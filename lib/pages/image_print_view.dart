import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:image/image.dart' as img;
import 'package:image_size_getter/image_size_getter.dart' as img_size;
import 'package:image_size_getter/file_input.dart';

import '../constants.dart';
import '../services/api_service.dart';
import '../widgets/connection_error_card.dart';

class ImagePrintView extends ConsumerStatefulWidget {
  final List<PlatformFile> files;

  const ImagePrintView({super.key, required this.files});

  @override
  ConsumerState<ImagePrintView> createState() => _ImagePrintViewState();
}

class _ImagePrintViewState extends ConsumerState<ImagePrintView> {
  late List<PlatformFile> _files;
  int _currentPageIndex = 0;
  // Local printers removed
  PrintOrientation _orientation = PrintOrientation.auto;
  PaperSize _paperSize = PaperSize.a4;
  final Map<String, Size> _imageSizes = {};
  ImageLayout _photoSize = ImageLayout.fullPage;
  PageMargins _pageMargins = PageMargins.normal;
  Scaling _fit = Scaling.shrinkToFit;
  ImagesPerPage _imagesPerPage = ImagesPerPage.one;
  bool _letAppChangePreferences = true;

  int _imageCopies = 1;
  int _batchCopies = 1;
  ColorMode _colorMode = ColorMode.color;
  PrintSides _duplexMode = PrintSides.single;
  bool _serverError = false;
  late TextEditingController _imageCopiesController;
  late TextEditingController _batchCopiesController;

  List<PlatformFile> get _effectiveFiles {
    List<PlatformFile> result = [];
    for (var file in _files) {
      for (int i = 0; i < _imageCopies; i++) {
        result.add(file);
      }
    }
    return result;
  }
  @override
  void initState() {
    super.initState();
    _files = List.from(widget.files);
    _imageCopiesController = TextEditingController(text: _imageCopies.toString());
    _batchCopiesController = TextEditingController(text: _batchCopies.toString());
    // _loadPrinters removed
    _loadInitialImageSizes();
  }

  @override
  void didUpdateWidget(ImagePrintView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.files != widget.files) {
      setState(() {
        _files = List.from(widget.files);
        _currentPageIndex = 0;
      });
      _loadInitialImageSizes();
    }
  }

  @override
  void dispose() {
    _imageCopiesController.dispose();
    _batchCopiesController.dispose();
    // Clear cached image textures to free GPU/memory
    _imageSizes.clear();
    PaintingBinding.instance.imageCache.clear();
    super.dispose();
  }

  Future<void> _loadInitialImageSizes() async {
    for (var file in _files) {
      await _loadImageSize(file);
    }
  }

  Future<void> _loadImageSize(PlatformFile file) async {
    if (_imageSizes.containsKey(file.name)) return;
      try {
        final sizeInts = file.bytes != null ? img_size.ImageSizeGetter.getSizeResult(img_size.MemoryInput(file.bytes!)).size : img_size.ImageSizeGetter.getSizeResult(FileInput(File(file.path!))).size;
        final size = Size(sizeInts.width.toDouble(), sizeInts.height.toDouble());

      if (mounted) {
        setState(() {
          _imageSizes[file.name] = size;
        });
      }
    } catch (e) {
      debugPrint('Error loading image size: $e');
    }
  }

  // _loadPrinters removed

  Future<void> _pickMoreImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result != null) {
      final newFiles = result.files;
      setState(() {
        _files.addAll(newFiles);
      });
      for (var file in newFiles) {
        _loadImageSize(file);
      }
    }
  }

  int get _totalPages {
    if (_effectiveFiles.isEmpty) return 0;
    return (_effectiveFiles.length / _imagesPerPage.value).ceil();
  }

  @override
  Widget build(BuildContext context) {
    if (_serverError) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.files.isNotEmpty ? widget.files.first.name : 'Image Print'), centerTitle: true),
        body: Center(
          child: ConnectionErrorCard(
            onDismiss: () => setState(() => _serverError = false),
            onReconnect: () => context.go('/connect'),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final fileName = _files.isNotEmpty ? p.basenameWithoutExtension(_files.first.name) : 'Document';
    
    // Ensure current page index is valid if total pages shrinks
    if (_totalPages > 0 && _currentPageIndex >= _totalPages) {
      _currentPageIndex = _totalPages - 1;
    }
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
            child: OrientationBuilder(
              builder: (context, orientation) {
                final isPortrait = orientation == Orientation.portrait;
                
                return Column(
                  children: [
                    _buildTopBar(theme, fileName, !isPortrait),
                    Expanded(
                      child: isPortrait
                        ? Column(
                            children: [
                              // Top Preview Area
                              Expanded(
                                flex: 3,
                                child: _buildPreviewArea(theme),
                              ),
                              // Bottom Sidebar
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: _buildSidebar(theme),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              // Left Sidebar
                              _buildSidebar(theme),
                              // Right Preview Area
                              Expanded(
                                child: _buildPreviewArea(theme),
                              ),
                            ],
                          ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Bottom Bar
          _buildBottomBar(theme),
        ],
      ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, String fileName, bool isDesktop) {
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: isDesktop 
        ? Row(
            children: [
              Expanded(
                child: Text(
                  '$fileName - Print',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _pickMoreImages,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                label: const Text('Add Photos'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              // Pagination
              if (_totalPages > 0)
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_left, color: theme.iconTheme.color),
                      onPressed: _currentPageIndex > 0 ? () => setState(() => _currentPageIndex--) : null,
                    ),
                    Text(
                      'Page ${_currentPageIndex + 1} of $_totalPages',
                      style: theme.textTheme.bodyMedium,
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_right, color: theme.iconTheme.color),
                      onPressed: _currentPageIndex < _totalPages - 1 ? () => setState(() => _currentPageIndex++) : null,
                    ),
                  ],
                ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.fullscreen, color: theme.iconTheme.color, size: 20),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.close, color: theme.iconTheme.color, size: 20),
                onPressed: () => context.go('/'),
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$fileName - Print',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.iconTheme.color, size: 20),
                    onPressed: () => context.go('/'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickMoreImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                    label: const Text('Add Photos'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  if (_totalPages > 0)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_left, color: theme.iconTheme.color),
                          onPressed: _currentPageIndex > 0 ? () => setState(() => _currentPageIndex--) : null,
                        ),
                        Text(
                          '${_currentPageIndex + 1} / $_totalPages',
                          style: theme.textTheme.bodyMedium,
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_right, color: theme.iconTheme.color),
                          onPressed: _currentPageIndex < _totalPages - 1 ? () => setState(() => _currentPageIndex++) : null,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    return Container(
      width: 320,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Printer dropdown removed
            const SizedBox(height: 16),
            Text('Image Copies (per photo)', style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _imageCopies = (_imageCopies > 1) ? _imageCopies - 1 : 1;
                      _imageCopiesController.text = _imageCopies.toString();
                    });
                  },
                  icon: const Icon(Icons.remove, size: 16),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _imageCopiesController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                         setState(() => _imageCopies = int.tryParse(val) ?? 1);
                      },
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _imageCopies++;
                      _imageCopiesController.text = _imageCopies.toString();
                    });
                  },
                  icon: const Icon(Icons.add, size: 16),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Batch Copies (entire job)', style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _batchCopies = (_batchCopies > 1) ? _batchCopies - 1 : 1;
                      _batchCopiesController.text = _batchCopies.toString();
                    });
                  },
                  icon: const Icon(Icons.remove, size: 16),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _batchCopiesController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                         setState(() => _batchCopies = int.tryParse(val) ?? 1);
                      },
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _batchCopies++;
                      _batchCopiesController.text = _batchCopies.toString();
                    });
                  },
                  icon: const Icon(Icons.add, size: 16),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDropdownEnum('Colour', _colorMode, ColorMode.values, (val) => setState(() => _colorMode = val as ColorMode), theme),
            const SizedBox(height: 16),
            _buildDropdownEnum('Print on both sides', _duplexMode, PrintSides.values, (val) => setState(() => _duplexMode = val as PrintSides), theme),
            const SizedBox(height: 16),
            _buildDropdownEnum('Orientation', _orientation, PrintOrientation.values, (val) => setState(() => _orientation = val as PrintOrientation), theme, icon: Icons.landscape),
            const SizedBox(height: 16),
            _buildDropdownEnum('Paper size', _paperSize, PaperSize.values, (val) => setState(() => _paperSize = val as PaperSize), theme, subtitleMap: {
              PaperSize.a4: '21.00cm x 29.70cm',
              PaperSize.a3: '29.70cm x 42.00cm',
              PaperSize.letter: '8.5 x 11 in.',
              PaperSize.legal: '8.5 x 14 in.',
              PaperSize.foolscap: '8.5 x 13.5 in.',
              PaperSize.r4: '10.2cm x 15.2cm',
              PaperSize.r5: '12.7cm x 17.8cm',
              PaperSize.r6: '15.2cm x 20.3cm',
              PaperSize.r8: '20.3cm x 25.4cm',
            }),
            const SizedBox(height: 16),
            _buildDropdownEnum('Photo size', _photoSize, ImageLayout.values, (val) => setState(() => _photoSize = val as ImageLayout), theme),
            const SizedBox(height: 16),
            _buildDropdownEnum('Page Margins', _pageMargins, PageMargins.values, (val) => setState(() => _pageMargins = val as PageMargins), theme),
            const SizedBox(height: 16),
            _buildDropdownEnum('Fit', _fit, Scaling.values, (val) => setState(() => _fit = val as Scaling), theme),
            const SizedBox(height: 16),
            _buildDropdownEnum('Images per page', _imagesPerPage, ImagesPerPage.values, (val) => setState(() => _imagesPerPage = val as ImagesPerPage), theme),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {},
              child: Text('More settings', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Checkbox(
                  value: _letAppChangePreferences,
                  onChanged: (val) => setState(() => _letAppChangePreferences = val ?? true),
                  activeColor: theme.colorScheme.primary,
                ),
                Expanded(
                  child: Text(
                    'Let the app change my printing preferences', 
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _files.isEmpty ? null : () async {
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                final Map<String, List<double>> serializedSizes = {};
                _imageSizes.forEach((key, val) {
                  serializedSizes[key] = [val.width, val.height];
                });

                final bytes = await compute(_generateImagePdfBytes, {
                  'filePaths': _effectiveFiles,
                  'paperSize': _paperSize.name,
                  'orientation': _orientation.name,
                  'fit': _fit.name,
                  'pageMargins': _pageMargins.name,
                  'imagesPerPage': _imagesPerPage.value,
                  'colorMode': _colorMode.name,
                  'imageSizes': serializedSizes,
                });

                if (!mounted) return;
                Navigator.of(context).pop();

                final base = _files.isNotEmpty ? _files.first.name : 'Photos';
                final finalName = base.toLowerCase().endsWith('.pdf') ? base : '${p.withoutExtension(base)}.pdf';

                final apiService = ApiService();
                final multipartFile = http.MultipartFile.fromBytes(
                   'files[]', 
                   bytes, 
                   filename: finalName
                );

                final response = await apiService.uploadPrintJob(
                   fileBytes: [multipartFile],
                   category: 'photo',
                   copies: _batchCopies, // PC App will loop and print this many times
                   pageCount: _totalPages,
                   colorMode: _colorMode == ColorMode.color ? 'color' : 'bw',
                   paperSize: _paperSize.name, // Will use exact enum string
                   orientation: _orientation.name,
                   printSides: _duplexMode.name,
                   imageLayout: _photoSize.name,
                );

                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Print Job sent successfully!')),
                   );
                   context.go('/tracking', extra: response['id']);
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  if (e.toString().contains('SERVER_OFFLINE')) {
                    setState(() => _serverError = true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to upload: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              minimumSize: const Size(100, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Print'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => context.go('/'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(100, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  bool _calculateSmartLandscape(double imgWidth, double imgHeight, int imagesPerPage) {
    final bool imgIsWide = imgWidth > imgHeight;
    if (imagesPerPage == 2) {
      return !imgIsWide;
    } else {
      return imgIsWide;
    }
  }

  bool get _isLandscape {
    if (_orientation == PrintOrientation.landscape) return true;
    if (_orientation == PrintOrientation.portrait) return false;
    if (_files.isEmpty) return false;
    
    // Auto mode: check first image of the current page
    int startIndex = _currentPageIndex * _imagesPerPage.value;
    if (startIndex >= _files.length) startIndex = 0;
    final file = _files[startIndex];
    final size = _imageSizes[file.name];
    if (size != null) {
      return _calculateSmartLandscape(size.width, size.height, _imagesPerPage.value);
    }
    try {
      final bytes = file.bytes ?? File(file.path!).readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        _imageSizes[file.name] = Size(decoded.width.toDouble(), decoded.height.toDouble());
        return _calculateSmartLandscape(decoded.width.toDouble(), decoded.height.toDouble(), _imagesPerPage.value);
      }
    } catch (_) {}
    return false; // default portrait if unknown
  }

  Widget _buildPreviewArea(ThemeData theme) {
    if (_files.isEmpty) {
       return Container(color: theme.colorScheme.surfaceContainerHighest, child: Center(child: Text('No Image Selected', style: theme.textTheme.titleMedium)));
    }
    
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Builder(
          builder: (context) {
            double baseRatio = 1 / 1.414;
            if (_paperSize == PaperSize.letter) {
              baseRatio = 8.5 / 11.0;
            } else if (_paperSize == PaperSize.legal) {
              baseRatio = 8.5 / 14.0;
            } else if (_paperSize == PaperSize.foolscap) {
              baseRatio = 8.5 / 13.5;
            } else if (_paperSize == PaperSize.r4) {
              baseRatio = 4.0 / 6.0;
            } else if (_paperSize == PaperSize.r5) {
              baseRatio = 5.0 / 7.0;
            } else if (_paperSize == PaperSize.r6) {
              baseRatio = 6.0 / 8.0;
            } else if (_paperSize == PaperSize.r8) {
              baseRatio = 8.0 / 10.0;
            }
            final ratio = _isLandscape ? (1.0 / baseRatio) : baseRatio;
            
            return AspectRatio(
              aspectRatio: ratio,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(4, 4),
                    ),
                  ],
                ),
                child: _colorMode == ColorMode.bw
                    ? ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0, 0, 0, 1, 0,
                        ]),
                        child: _buildImagesGrid(),
                      )
                    : _buildImagesGrid(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImagesGrid() {
     int startIndex = _currentPageIndex * _imagesPerPage.value;
     int endIndex = min(startIndex + _imagesPerPage.value, _effectiveFiles.length);
     List<PlatformFile> pageFiles = _effectiveFiles.sublist(startIndex, endIndex);
     
     int crossAxisCount = 1;
     int rows = 1;
     switch (_imagesPerPage) {
       case ImagesPerPage.one:
         crossAxisCount = 1;
         rows = 1;
         break;
       case ImagesPerPage.two:
         crossAxisCount = _isLandscape ? 2 : 1;
         rows = _isLandscape ? 1 : 2;
         break;
       case ImagesPerPage.four:
         crossAxisCount = 2;
         rows = 2;
         break;
       case ImagesPerPage.nine:
         crossAxisCount = 3;
         rows = 3;
         break;
     }

     return Padding(
       padding: EdgeInsets.all(_pageMargins == PageMargins.normal ? 16.0 : 0.0),
       child: LayoutBuilder(
         builder: (context, constraints) {
           double cellWidth = (constraints.maxWidth - (8.0 * (crossAxisCount - 1))) / crossAxisCount;
           double cellHeight = (constraints.maxHeight - (8.0 * (rows - 1))) / rows;
           double exactAspectRatio = cellHeight <= 0 ? 1.0 : (cellWidth / cellHeight);

           return GridView.builder(
             physics: const NeverScrollableScrollPhysics(),
             itemCount: _imagesPerPage.value,
             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
               crossAxisCount: crossAxisCount,
               crossAxisSpacing: 8,
               mainAxisSpacing: 8,
               childAspectRatio: exactAspectRatio,
             ),
             itemBuilder: (context, index) {
           if (_effectiveFiles.isNotEmpty) {
              int actualIndex;
              if (index < pageFiles.length) {
                actualIndex = startIndex + index;
              } else {
                return Container(color: Colors.grey.shade100);
              }
              final file = _effectiveFiles[actualIndex];
              return Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                child: file.bytes != null ? Image.memory(file.bytes!, fit: _fit == Scaling.fillPage ? BoxFit.cover : BoxFit.contain) : Image.file(
                  File(file.path!),
                  fit: _fit == Scaling.fillPage ? BoxFit.cover : BoxFit.contain,
                  cacheWidth: 800,
                  gaplessPlayback: true,
                ),
              );
           } else {
              return Container(
                color: Colors.grey.shade100,
              );
           }
         },
       );
       },
     ),
    );
  }



  Widget _buildDropdownEnum(String label, dynamic value, List<dynamic> options, ValueChanged<dynamic> onChanged, ThemeData theme, {IconData? icon, Map<dynamic, String>? subtitleMap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              value: value,
              isExpanded: true,
              dropdownColor: theme.colorScheme.surfaceContainerHighest,
              isDense: false,
              itemHeight: null,
              icon: Icon(Icons.keyboard_arrow_down, size: 16, color: theme.colorScheme.onSurfaceVariant),
              items: options.map((e) {
                final hasSubtitle = subtitleMap != null && subtitleMap.containsKey(e);
                return DropdownMenuItem(
                  value: e,
                  child: Row(
                    children: [
                      if (icon != null) ...[Icon(icon, color: theme.iconTheme.color, size: 16), const SizedBox(width: 8)],
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(e.label, style: theme.textTheme.bodyMedium),
                          if (hasSubtitle) Text(subtitleMap[e]!, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                        ],
                      ),
                    ],
                  )
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

Future<Uint8List> _generateImagePdfBytes(Map<String, dynamic> params) async {
  final filePaths = params['filePaths'] as List<String>;
  final paperSizeVal = params['paperSize'] as String;
  final orientationVal = params['orientation'] as String;
  final fitVal = params['fit'] as String;
  final pageMarginsVal = params['pageMargins'] as String;
  final imagesPerPageVal = params['imagesPerPage'] as int;
  final colorModeVal = params['colorMode'] as String;
  final imageSizes = params['imageSizes'] as Map<String, dynamic>? ?? {};

  final newDoc = PdfDocument();
  
  Size sheetSize;
  if (paperSizeVal == 'letter') {
    sheetSize = const Size(612, 792);
  } else if (paperSizeVal == 'legal') {
    sheetSize = const Size(612, 1008);
  } else if (paperSizeVal == 'foolscap') {
    sheetSize = const Size(612, 972);
  } else if (paperSizeVal == 'a3') {
    sheetSize = const Size(842, 1191);
  } else if (paperSizeVal == 'r4') {
    sheetSize = const Size(288, 432);
  } else if (paperSizeVal == 'r5') {
    sheetSize = const Size(360, 504);
  } else if (paperSizeVal == 'r6') {
    sheetSize = const Size(432, 576);
  } else if (paperSizeVal == 'r8') {
    sheetSize = const Size(576, 720);
  } else {
    sheetSize = const Size(595, 842);
  }
  
  bool isLandscape = false;
  if (orientationVal == 'landscape') {
    isLandscape = true;
  } else if (orientationVal == 'auto') {
    if (filePaths.isNotEmpty) {
      try {
        double w = 0;
        double h = 0;
        final sizeList = imageSizes[filePaths.first] as List<dynamic>?;
        if (sizeList != null && sizeList.length == 2) {
          w = sizeList[0] as double;
          h = sizeList[1] as double;
        } else {
          final firstBytes = File(filePaths.first).readAsBytesSync();
          final firstImage = img.decodeImage(firstBytes);
          if (firstImage != null) {
            w = firstImage.width.toDouble();
            h = firstImage.height.toDouble();
          }
        }
        if (w > 0 && h > 0) {
          final bool imgIsWide = w > h;
          if (imagesPerPageVal == 2) {
            isLandscape = !imgIsWide;
          } else {
            isLandscape = imgIsWide;
          }
        }
      } catch (_) {}
    }
  }
  
  if (isLandscape) {
    sheetSize = Size(sheetSize.height, sheetSize.width);
  }
  
  newDoc.pageSettings.size = sheetSize;
  newDoc.pageSettings.margins.all = 0;
  newDoc.pageSettings.orientation = isLandscape ? PdfPageOrientation.landscape : PdfPageOrientation.portrait;
  
  int cols = 1;
  int rows = 1;
  if (imagesPerPageVal == 2) {
    if (isLandscape) {
      cols = 2;
      rows = 1;
    } else {
      cols = 1;
      rows = 2;
    }
  } else if (imagesPerPageVal == 4) {
    cols = 2;
    rows = 2;
  } else if (imagesPerPageVal == 9) {
    cols = 3;
    rows = 3;
  }
  
  double margin = pageMarginsVal == 'normal' ? 36.0 : 18.0;
  double spacing = 8.0;
  
  double cellWidth = (sheetSize.width - (margin * 2) - (spacing * (cols - 1))) / cols;
  double cellHeight = (sheetSize.height - (margin * 2) - (spacing * (rows - 1))) / rows;
  
  int totalImages = filePaths.length;
  int imagesPerPage = imagesPerPageVal;
  int totalPages = totalImages == 0 ? 1 : (totalImages / imagesPerPage).ceil();
  
  for (int pIndex = 0; pIndex < totalPages; pIndex++) {
    final page = newDoc.pages.add();
    final graphics = page.graphics;
    
    int startIndex = pIndex * imagesPerPage;
    for (int cellIndex = 0; cellIndex < imagesPerPage; cellIndex++) {
      if (filePaths.isEmpty) break;
      int imgIndex;
      if (cellIndex < filePaths.length) {
        imgIndex = startIndex + cellIndex;
        if (imgIndex >= filePaths.length) break;
      } else {
        break;
      }
      
      final filePath = filePaths[imgIndex];
      final file = File(filePath);
      if (!file.existsSync()) continue;
      
      Uint8List imageBytes = file.readAsBytesSync();
      double imageWidth = 0;
      double imageHeight = 0;
      
      if (colorModeVal == 'bw') {
        var decoded = img.decodeImage(imageBytes);
        if (decoded == null) continue;
        
        // Downscale to max 1600px to save heap memory
        if (decoded.width > 1600 || decoded.height > 1600) {
          decoded = img.copyResize(
            decoded, 
            width: decoded.width > decoded.height ? 1600 : null, 
            height: decoded.height >= decoded.width ? 1600 : null,
            interpolation: img.Interpolation.average,
          );
        }
        
        imageWidth = decoded.width.toDouble();
        imageHeight = decoded.height.toDouble();
        decoded = img.grayscale(decoded);
        imageBytes = Uint8List.fromList(img.encodePng(decoded));
      } else {
        // Retrieve size without decoding
        final sizeList = imageSizes[filePath] as List<dynamic>?;
        if (sizeList != null && sizeList.length == 2) {
          imageWidth = sizeList[0] as double;
          imageHeight = sizeList[1] as double;
        } else {
          // fallback to decode if not found (should not happen)
          final decoded = img.decodeImage(imageBytes);
          if (decoded != null) {
            imageWidth = decoded.width.toDouble();
            imageHeight = decoded.height.toDouble();
          }
        }
      }
      
      if (imageWidth == 0 || imageHeight == 0) continue;
      
      final bitmap = PdfBitmap(imageBytes);
      
      int r = cellIndex ~/ cols;
      int c = cellIndex % cols;
      
      double cellX = margin + c * (cellWidth + spacing);
      double cellY = margin + r * (cellHeight + spacing);
      
      final cellRect = Rect.fromLTWH(cellX, cellY, cellWidth, cellHeight);
      
      double imageRatio = imageWidth / imageHeight;
      double cellRatio = cellWidth / cellHeight;
      
      double drawWidth;
      double drawHeight;
      
      if (fitVal == 'fillPage') {
        if (imageRatio > cellRatio) {
          drawHeight = cellHeight;
          drawWidth = cellHeight * imageRatio;
        } else {
          drawWidth = cellWidth;
          drawHeight = cellWidth / imageRatio;
        }
      } else {
        if (imageRatio > cellRatio) {
          drawWidth = cellWidth;
          drawHeight = cellWidth / imageRatio;
        } else {
          drawHeight = cellHeight;
          drawWidth = cellHeight * imageRatio;
        }
      }
      
      double drawX = cellX + (cellWidth - drawWidth) / 2;
      double drawY = cellY + (cellHeight - drawHeight) / 2;
      
      graphics.save();
      final path = PdfPath();
      path.addRectangle(cellRect);
      graphics.setClip(path: path);
      
      graphics.drawImage(bitmap, Rect.fromLTWH(drawX, drawY, drawWidth, drawHeight));
      graphics.restore();
    }
    // Yield to the event loop so that Dart GC has a chance to clean up intermediate allocations
    await Future.delayed(const Duration(milliseconds: 50));
  }
  
  final bytes = await newDoc.save();
  newDoc.dispose();
  return Uint8List.fromList(bytes);
}
