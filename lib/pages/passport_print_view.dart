import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../widgets/connection_error_card.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;

class PassportPrintView extends ConsumerStatefulWidget {
  final PlatformFile? file;

  const PassportPrintView({super.key, required this.file});

  @override
  ConsumerState<PassportPrintView> createState() => _PassportPrintViewState();
}

class _PassportPrintViewState extends ConsumerState<PassportPrintView> {
  // Local printers removed
  
  // Stage flags
  // Stage 1: Editor State
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;
  String _presetMode = 'US 2x2 inch (51x51mm)';
  double _rotationDegrees = 0;
  bool _isMirrored = false;
  bool _serverError = false;
  double _customWidthMm = 51;
  double _customHeightMm = 51;
  String _customUnit = 'mm';
  bool _isCroppingStage = true;
  img.Image? _rawImage;
  Uint8List? _croppedBytes;
  Uint8List? _rawImageBytes;

  final TextEditingController _customWidthController = TextEditingController(text: '35');
  final TextEditingController _customHeightController = TextEditingController(text: '45');

  // For mathematical cropping
  Size _viewportSize = Size.zero;
  Size _cropBoxSize = Size.zero;
  final GlobalKey _previewKey = GlobalKey();
  
  double _convertToMm(double val, String unit) {
    if (unit == 'inch') return val * 25.4;
    if (unit == 'cm') return val * 10.0;
    return val;
  }

  double _convertFromMm(double val, String unit) {
    if (unit == 'inch') return val / 25.4;
    if (unit == 'cm') return val / 10.0;
    return val;
  }

  // Stage 2: Print Settings
  int _copies = 1;
  String _paperSize = 'A4';
  // ignore: unused_field
  bool _isProcessingPdf = false;
  Uint8List? _processedPdfBytes;
  Timer? _debounceTimer;
  String _colorMode = 'Color';

  @override
  void initState() {
    super.initState();
    // _loadPrinters removed
    _loadImage();
    _transformationController.addListener(_onTransformationChange);
  }

  @override
  void didUpdateWidget(PassportPrintView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file?.name != widget.file?.name) {
      // Release previous image data before loading new one
      setState(() {
        _rawImage = null;
        _rawImageBytes = null;
        _croppedBytes = null;
        _processedPdfBytes = null;
        _isCroppingStage = true;
        _transformationController.value = Matrix4.identity();
      });
      _loadImage();
    }
  }

  void _onTransformationChange() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (_currentScale != scale && mounted) {
      setState(() => _currentScale = scale);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _customWidthController.dispose();
    _customHeightController.dispose();
    _debounceTimer?.cancel();
    // Release all heavy image/PDF buffers to prevent memory leaks
    _rawImage = null;
    _rawImageBytes = null;
    _croppedBytes = null;
    _processedPdfBytes = null;
    // Evict cached image textures associated with this screen
    PaintingBinding.instance.imageCache.clear();
    super.dispose();
  }

  // _loadPrinters removed

  Future<void> _loadImage() async {
    try {
      Uint8List bytes;
      // Removing PDF to image logic in PassportPrintView for now since we're assuming passports are images (or handle later)
      // For now just keep the basic readAsBytes since Printing package is removed.
      if (widget.file!.name.toLowerCase().endsWith('.pdf')) {
         bytes = widget.file!.bytes ?? await File(widget.file!.path!).readAsBytes();
      } else {
        bytes = widget.file!.bytes ?? await File(widget.file!.path!).readAsBytes();
      }
      if (bytes.isEmpty) return;
      final decoded = img.decodeImage(bytes);
      if (mounted && decoded != null) {
        setState(() {
          _rawImage = decoded;
          _rawImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
    }
  }

  Future<void> _pickNewFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'bmp'],
    );
    if (result != null && result.paths.isNotEmpty) {
      final validPath = result.paths.first;
      if (validPath != null && mounted) {
        context.pushReplacement('/passport', extra: validPath);
      }
    }
  }

  void _applyZoom(double newScale) {
    if (_currentScale == 0) return;
    final scaleChange = newScale / _currentScale;
    final matrix = _transformationController.value.clone();
    matrix.multiply(Matrix4.diagonal3Values(scaleChange, scaleChange, 1.0));
    _transformationController.value = matrix;
  }

  Future<Uint8List?> _cropImageWithCanvas(ui.Image capturedImage, Rect cropRect) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      canvas.drawImageRect(
        capturedImage,
        cropRect,
        Rect.fromLTWH(0, 0, cropRect.width, cropRect.height),
        Paint(),
      );
      
      final picture = recorder.endRecording();
      final croppedUiImage = await picture.toImage(cropRect.width.toInt(), cropRect.height.toInt());
      final byteData = await croppedUiImage.toByteData(format: ui.ImageByteFormat.png);
      
      croppedUiImage.dispose();
      picture.dispose();
      
      if (byteData == null) return null;
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error cropping image with canvas: $e');
      return null;
    }
  }

  Future<void> _applyCrop() async {
    if (_rawImage == null || _viewportSize == Size.zero) return;
    
    setState(() => _isProcessingPdf = true);

    try {
      final boundary = _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        setState(() => _isProcessingPdf = false);
        return;
      }

      // Capture at high resolution (2.0 pixel ratio is sufficient for passport photos and prevents OOM)
      final ui.Image capturedImage = await boundary.toImage(pixelRatio: 2.0);
      
      final double pr = 2.0;
      final double left = ((_viewportSize.width / 2) - (_cropBoxSize.width / 2)) * pr;
      final double top = ((_viewportSize.height / 2) - (_cropBoxSize.height / 2)) * pr;
      final double width = _cropBoxSize.width * pr;
      final double height = _cropBoxSize.height * pr;
      
      final croppedBytes = await _cropImageWithCanvas(
        capturedImage,
        Rect.fromLTWH(left, top, width, height),
      );
      
      // CRITICAL: Dispose the GPU texture immediately
      capturedImage.dispose();

      if (croppedBytes != null) {
        setState(() {
          _croppedBytes = croppedBytes;
          _isCroppingStage = false;
        });
        unawaited(_updateProcessedPdf());
      } else {
        setState(() => _isProcessingPdf = false);
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
      setState(() => _isProcessingPdf = false);
    }
  }

  Future<void> _updateProcessedPdf() async {
    if (_croppedBytes == null) return;
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _isProcessingPdf = true);
      
      try {
        final generatedBytes = await compute(_generatePdfGrid, {
          'croppedBytes': _croppedBytes!,
          'paperSize': _paperSize,
          'presetMode': _presetMode,
          'customWidthMm': _customWidthMm,
          'customHeightMm': _customHeightMm,
          'copies': _copies,
          'colorMode': _colorMode,
        });
        
        if (mounted) {
          setState(() {
            _processedPdfBytes = generatedBytes;
            _isProcessingPdf = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isProcessingPdf = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_serverError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Passport Print'), centerTitle: true),
        body: Center(
          child: ConnectionErrorCard(
            onDismiss: () => setState(() => _serverError = false),
            onReconnect: () => context.go('/connect'),
          ),
        ),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Passport Photo: ${p.basename(widget.file!.name)}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.image_search),
            tooltip: 'Change Photo',
            onPressed: _pickNewFile,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: OrientationBuilder(
              builder: (context, orientation) {
                if (orientation == Orientation.portrait) {
                  return Column(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _isCroppingStage ? _buildEditorArea(theme) : _buildPreviewArea(theme),
                      ),
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          width: double.infinity,
                          child: _buildSidebar(theme),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        child: _isCroppingStage ? _buildEditorArea(theme) : _buildPreviewArea(theme),
                      ),
                      _buildSidebar(theme),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorArea(ThemeData theme) {
    if (_rawImageBytes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    double aspectRatio = 1.0;
    if (_presetMode == 'UK/EU 35x45mm' || _presetMode == 'Indian ID (35x45mm)') {
      aspectRatio = 35 / 45;
    } else if (_presetMode == 'Indian PAN (25x35mm)') {
      aspectRatio = 25 / 35;
    } else if (_presetMode == 'Indian Stamp (20x25mm)') {
      aspectRatio = 20 / 25;
    } else if (_presetMode == 'Japan 30x40mm') {
      aspectRatio = 30 / 40;
    } else if (_presetMode == 'China 33x48mm') {
      aspectRatio = 33 / 48;
    } else if (_presetMode == 'Custom') {
      aspectRatio = _customWidthMm / _customHeightMm;
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxHeight = constraints.maxHeight * 0.7;
        final boxWidth = boxHeight * aspectRatio;
        
        final cropRect = Rect.fromCenter(
          center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
          width: boxWidth,
          height: boxHeight,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
            _cropBoxSize = Size(boxWidth, boxHeight);
          }
        });

        return Container(
          color: const Color(0xFF1E1E1E),
          child: Stack(
            children: [
              Listener(
                onPointerSignal: (pointerSignal) {
                  if (pointerSignal is PointerScrollEvent) {
                    final dy = pointerSignal.scrollDelta.dy;
                    if (dy == 0) return;
                    final scaleChange = dy > 0 ? 0.9 : 1.1;
                    final Matrix4 matrix = _transformationController.value.clone();
                    final focalPoint = pointerSignal.localPosition;
                    
                    final dx = focalPoint.dx * (1 - scaleChange);
                    final dy2 = focalPoint.dy * (1 - scaleChange);
                    
                    matrix.multiply(Matrix4.diagonal3Values(scaleChange, scaleChange, 1.0));
                    matrix.multiply(Matrix4.translationValues(dx / scaleChange, dy2 / scaleChange, 0.0));
                    _transformationController.value = matrix;
                  }
                },
                child: RepaintBoundary(
                  key: _previewKey,
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.1,
                    maxScale: 10.0,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    constrained: false,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationZ(_rotationDegrees * pi / 180)..
                      multiply(Matrix4.diagonal3Values(_isMirrored ? -1.0 : 1.0, 1.0, 1.0)),
                      child: Image.memory(
                        _rawImageBytes!,
                        fit: BoxFit.none,
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _CropOverlayPainter(cropRect: cropRect),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(40),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _processedPdfBytes == null
              ? const CircularProgressIndicator()
              : AspectRatio(
                  key: ValueKey(_processedPdfBytes.hashCode),
                  aspectRatio: _paperSize.contains('Letter') ? (8.5 / 11.0) : (_paperSize.contains('Legal') ? (8.5 / 14.0) : _paperSize.contains('4R') ? (4 / 6) : _paperSize.contains('5R') ? (5 / 7) : _paperSize.contains('6R') ? (6 / 8) : _paperSize.contains('8R') ? (8 / 10) : (1 / 1.414)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: _colorMode == 'Black and white'
                        ? ColorFiltered(
                            colorFilter: const ColorFilter.matrix([
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0, 0, 0, 1, 0,
                            ]),
                            child: SfPdfViewer.memory(
                              _processedPdfBytes!,
                              canShowScrollHead: false,
                              canShowScrollStatus: false,
                              pageSpacing: 0,
                            ),
                          )
                        : SfPdfViewer.memory(
                            _processedPdfBytes!,
                            canShowScrollHead: false,
                            canShowScrollStatus: false,
                            pageSpacing: 0,
                          ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    return Container(
      width: 320,
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isCroppingStage) ...[
               Text('1. Select Standard', style: theme.textTheme.titleMedium),
               const SizedBox(height: 16),
               DropdownButtonFormField<String>(
                  initialValue: _presetMode,
                  items: ['US 2x2 inch (51x51mm)', 'Indian Passport (51x51mm)', 'Indian ID (35x45mm)', 'Indian PAN (25x35mm)', 'Indian Stamp (20x25mm)', 'UK/EU 35x45mm', 'Japan 30x40mm', 'China 33x48mm', 'Custom'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _presetMode = val!),
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
             ),
             if (_presetMode == 'Custom') ...[
               const SizedBox(height: 12),
               Row(
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                   Expanded(child: TextField(
                     controller: _customWidthController, 
                     decoration: const InputDecoration(labelText: 'Width'), 
                     keyboardType: TextInputType.number, 
                     onChanged: (val) { 
                       final p = double.tryParse(val) ?? 35;
                       setState(() => _customWidthMm = _convertToMm(p, _customUnit)); 
                     }
                   )),
                   const SizedBox(width: 8),
                   Expanded(child: TextField(
                     controller: _customHeightController, 
                     decoration: const InputDecoration(labelText: 'Height'), 
                     keyboardType: TextInputType.number, 
                     onChanged: (val) {
                       final p = double.tryParse(val) ?? 45;
                       setState(() => _customHeightMm = _convertToMm(p, _customUnit));
                     }
                   )),
                   const SizedBox(width: 8),
                   SizedBox(width: 100, child: DropdownButtonFormField<String>(
                     initialValue: _customUnit,
                     items: ['mm', 'cm', 'inch'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                     onChanged: (val) {
                       if (val != null) {
                         setState(() {
                           _customUnit = val;
                           _customWidthController.text = _convertFromMm(_customWidthMm, _customUnit).toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
                           _customHeightController.text = _convertFromMm(_customHeightMm, _customUnit).toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
                         });
                       }
                     },
                   )),
                 ],
               ),
             ],
             const SizedBox(height: 24),
             Text('2. Editor Tools', style: theme.textTheme.titleMedium),
             const SizedBox(height: 8),
             Row(
               children: [
                 const Text('Rotate:'),
                 Expanded(
                   child: Slider(
                     value: _rotationDegrees,
                     min: -180,
                     max: 180,
                     onChanged: (val) => setState(() => _rotationDegrees = val),
                   ),
                 ),
                 Text('${_rotationDegrees.toStringAsFixed(0)}°'),
                 IconButton(
                   icon: const Icon(Icons.refresh, size: 18),
                   onPressed: () => setState(() => _rotationDegrees = 0),
                   tooltip: 'Reset Rotation',
                 ),
               ],
             ),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Text('Mirror Horizontal'),
                 Switch(
                   value: _isMirrored,
                   onChanged: (val) => setState(() => _isMirrored = val),
                 ),
               ],
             ),
             Row(
               children: [
                 const Text('Zoom:'),
                 Expanded(
                   child: Slider(
                     value: _currentScale.clamp(0.1, 10.0),
                     min: 0.1,
                     max: 10.0,
                     onChanged: _applyZoom,
                   ),
                 ),
                 Text('${_currentScale.toStringAsFixed(1)}x'),
                 IconButton(
                   icon: const Icon(Icons.refresh, size: 18),
                   onPressed: () => _applyZoom(1.0),
                   tooltip: 'Reset Zoom',
                 ),
               ],
             ),
             const SizedBox(height: 48),
             ElevatedButton(
               onPressed: _applyCrop,
               child: const Text('Apply Crop & Proceed'),
             ),
             const SizedBox(height: 16),
             OutlinedButton.icon(
               onPressed: _sendRawPhotoToStudio,
               icon: const Icon(Icons.send_rounded, size: 18),
               label: const Text('Send Raw Photo to Studio'),
             ),
          ] else ...[
             Text('2. Print Settings', style: theme.textTheme.titleMedium),
             const SizedBox(height: 16),
             const Text('Photo Size Standard:'),
                 DropdownButtonFormField<String>(
                   initialValue: _presetMode,
                items: ['US 2x2 inch (51x51mm)', 'Indian Passport (51x51mm)', 'Indian ID (35x45mm)', 'Indian PAN (25x35mm)', 'Indian Stamp (20x25mm)', 'UK/EU 35x45mm', 'Japan 30x40mm', 'China 33x48mm', 'Custom'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) {
                  setState(() { _presetMode = val!; _isCroppingStage = true; });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please re-crop image for the new dimensions.')));
                },
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
             ),
             const SizedBox(height: 16),
             const Text('Paper Size:'),
             DropdownButtonFormField<String>(
                initialValue: _paperSize,
                 items: ['A4', 'A3', '4R (4x6")', '5R (5x7")', '6R (6x8")', '8R (8x10")', 'Letter', 'Legal', 'Foolscap (8.5x13.5")'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) {
                  setState(() => _paperSize = val!);
                  _updateProcessedPdf();
                },
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
             ),
             const SizedBox(height: 16),
             const Text('Colour:'),
             DropdownButtonFormField<String>(
               initialValue: _colorMode,
               items: ['Color', 'Black and white'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
               onChanged: (val) {
                 setState(() => _colorMode = val!);
                 _updateProcessedPdf();
               },
               decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
             ),
             const SizedBox(height: 16),
             Row(
               children: [
                 const Text('Copies:'),
                 const Spacer(),
                 IconButton(icon: const Icon(Icons.remove), onPressed: () {
                   if (_copies > 1) { setState(() => _copies--); _updateProcessedPdf(); }
                 }),
                 Text('$_copies', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                 IconButton(icon: const Icon(Icons.add), onPressed: () {
                   if (_copies < 100) { setState(() => _copies++); _updateProcessedPdf(); }
                 }),
               ],
             ),
             const SizedBox(height: 48),
             ElevatedButton(
               onPressed: () => setState(() => _isCroppingStage = true),
               child: const Text('Back to Editor'),
             ),
             const SizedBox(height: 8),
             ElevatedButton(
               style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary),
               onPressed: () async {
                 if (_processedPdfBytes != null) {
                   try {
                     showDialog(
                       context: context,
                       barrierDismissible: false,
                       builder: (context) => const Center(child: CircularProgressIndicator()),
                     );

                     final apiService = ApiService();
                     final base = widget.file != null ? p.basename(widget.file!.name) : 'Document';
                     final finalName = base.toLowerCase().endsWith('.pdf') ? base : '${p.withoutExtension(base)}.pdf';

                     final multipartFile = http.MultipartFile.fromBytes(
                       'files[]', 
                       _processedPdfBytes!, 
                       filename: finalName
                     );

                     final response = await apiService.uploadPrintJob(
                       fileBytes: [multipartFile],
                       category: 'passport',
                       copies: 1, // Multiplication happens in PDF grid generator
                       pageCount: _copies, // Total pages generated
                       colorMode: _colorMode == 'Color' ? 'color' : 'bw',
                       paperSize: _paperSize,
                       orientation: 'auto',
                       printSides: 'single',
                     );

                     if (mounted) {
                       Navigator.of(context).pop(); // dismiss loading
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Print Job sent successfully!')),
                       );
                       context.go('/tracking', extra: response['id']);
                     }
                   } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop(); // pop progress dialog
                  if (e.toString().contains('SERVER_OFFLINE')) {
                    setState(() => _serverError = true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to send print job: $e')),
                    );
                  }
                }
              }
                 }
               },
               child: const Text('Print Now'),
             ),
           ]
          ],
        ),
      ),
    );
  }

  Future<void> _sendRawPhotoToStudio() async {
    if (widget.file == null) return;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final apiService = ApiService();

      final response = await apiService.uploadPrintJob(
        files: [widget.file!],
        category: 'passport',
        copies: 1,
        pageCount: 1,
        colorMode: 'color',
        paperSize: 'A4',
        orientation: 'auto',
        printSides: 'single',
      );

      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Raw photo sent to studio successfully!')),
        );
        context.go('/tracking', extra: response['id']);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send raw photo: $e')),
        );
      }
    }
  }
}

class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;

  _CropOverlayPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cropPath = Path()..addRect(cropRect);

    final overlayPath = Path.combine(PathOperation.difference, backgroundPath, cropPath);

    canvas.drawPath(overlayPath, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(cropRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

Future<Uint8List?> _generatePdfGrid(Map<String, dynamic> params) async {
  try {
    final croppedBytes = params['croppedBytes'] as Uint8List;
    final paperSize = params['paperSize'] as String;
    final presetMode = params['presetMode'] as String;
    final customWidthMm = params['customWidthMm'] as double;
    final customHeightMm = params['customHeightMm'] as double;
    final copies = params['copies'] as int;
    final colorMode = params['colorMode'] as String? ?? 'Color';

    final newDoc = PdfDocument();
    Size sheetSize;
    if (paperSize.contains('Letter')) {
      sheetSize = const Size(612, 792);
    } else if (paperSize.contains('Legal')) {
              sheetSize = const Size(612, 1008);
            } else if (paperSize.contains('Foolscap')) {
              sheetSize = const Size(612, 972);
            } else if (paperSize.contains('A3')) {
              sheetSize = const Size(842, 1191);
            } else if (paperSize.contains('4R')) {
              sheetSize = const Size(288, 432);
            } else if (paperSize.contains('5R')) {
              sheetSize = const Size(360, 504);
            } else if (paperSize.contains('6R')) {
              sheetSize = const Size(432, 576);
            } else if (paperSize.contains('8R')) {
              sheetSize = const Size(576, 720);
            } else {
              sheetSize = const Size(595, 842);
            } // Default A4
    
    newDoc.pageSettings.size = sheetSize;
    newDoc.pageSettings.margins.all = 0;
    
    PdfPage newPage = newDoc.pages.add();
    
    Uint8List finalCropped = croppedBytes;
    if (colorMode == 'Black and white') {
      final decoded = img.decodeImage(croppedBytes);
      if (decoded != null) {
        final grayscale = img.grayscale(decoded);
        finalCropped = Uint8List.fromList(img.encodePng(grayscale));
      }
    }
    final PdfBitmap bitmap = PdfBitmap(finalCropped);
    
    double ptWidth = 35 * 2.83465;
    double ptHeight = 45 * 2.83465;
    if (presetMode == 'US 2x2 inch (51x51mm)' || presetMode == 'Indian Passport (51x51mm)') {
      ptWidth = 51 * 2.83465; ptHeight = 51 * 2.83465;
    } else if (presetMode == 'Indian PAN (25x35mm)') {
      ptWidth = 25 * 2.83465; ptHeight = 35 * 2.83465;
    } else if (presetMode == 'Indian Stamp (20x25mm)') {
      ptWidth = 20 * 2.83465; ptHeight = 25 * 2.83465;
    } else if (presetMode == 'Japan 30x40mm') {
      ptWidth = 30 * 2.83465; ptHeight = 40 * 2.83465;
    } else if (presetMode == 'China 33x48mm') {
      ptWidth = 33 * 2.83465; ptHeight = 48 * 2.83465;
    } else if (presetMode == 'Custom') {
      ptWidth = customWidthMm * 2.83465; ptHeight = customHeightMm * 2.83465;
    }

    const double spacing = 10.0;
    final int columns = ((sheetSize.width - spacing) / (ptWidth + spacing)).floor().clamp(1, 100);
    final int rows = ((sheetSize.height - spacing) / (ptHeight + spacing)).floor().clamp(1, 100);

    final double startX = (sheetSize.width - (columns * ptWidth + (columns - 1) * spacing)) / 2;
    final double startY = (sheetSize.height - (rows * ptHeight + (rows - 1) * spacing)) / 2;

    int currentCopy = 0;
    int currentRow = 0;
    int currentCol = 0;

    while (currentCopy < copies) {
      if (currentRow >= rows) {
        newPage = newDoc.pages.add();
        currentRow = 0;
        currentCol = 0;
      }
      final x = startX + currentCol * (ptWidth + spacing);
      final y = startY + currentRow * (ptHeight + spacing);
      newPage.graphics.drawImage(bitmap, Rect.fromLTWH(x, y, ptWidth, ptHeight));
      currentCopy++;
      currentCol++;
      if (currentCol >= columns) {
        currentCol = 0;
        currentRow++;
      }
    }
    final List<int> generatedBytes = await newDoc.save();
    newDoc.dispose();
    return Uint8List.fromList(generatedBytes);
  } catch (e) {
    return null;
  }
}


