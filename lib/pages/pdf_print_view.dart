import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path/path.dart' as p;
import '../services/api_service.dart';
import '../widgets/connection_error_card.dart';

class PdfPrintView extends ConsumerStatefulWidget {
  final PlatformFile? file;

  const PdfPrintView({super.key, required this.file});

  @override
  ConsumerState<PdfPrintView> createState() => _PdfPrintViewState();
}

class _PdfPrintViewState extends ConsumerState<PdfPrintView> {
  // Removed local printer variables
  int _copies = 1;
  String _colorMode = 'Color';
  String _duplexMode = 'Print on one side';
  String _paperSize = 'A4';
  String _orientation = 'Auto';
  bool _smartOrientation = true;
  bool _smartCopies = false;
  String _scaleMode = 'Fit to printable area';
  int _pagesPerSheet = 1;
  int _totalPdfPages = 0;

  late TextEditingController _copiesController;
  Uint8List? _processedPdfBytes;
  bool _isProcessingPdf = false;
  bool _serverError = false;

  int get _totalSheets => _totalPdfPages > 0 ? (_totalPdfPages / _pagesPerSheet).ceil() : 0;

  @override
  void initState() {
    super.initState();
    _copiesController = TextEditingController(text: _copies.toString());
    _updateProcessedPdf();
  }

  @override
  void didUpdateWidget(PdfPrintView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file?.name != widget.file?.name) {
      _updateProcessedPdf();
    }
  }

  @override
  void dispose() {
    _copiesController.dispose();
    // Release the multi-MB processed PDF buffer
    _processedPdfBytes = null;
    super.dispose();
  }

  // Local printing removed

  Future<void> _updateProcessedPdf() async {
    if (widget.file == null) return;
    
    if (!mounted) return;
    setState(() => _isProcessingPdf = true);
    
    try {
      final originalBytes = widget.file!.bytes ?? await File(widget.file!.path!).readAsBytes();
      
      // Offload N-up layout generation to background isolate to keep UI thread responsive
      final layoutBytes = await compute(_generateNUpPdf, {
        'originalBytes': originalBytes,
        'paperSize': _paperSize,
        'orientation': _orientation,
        'pagesPerSheet': _pagesPerSheet,
        'copies': _copies,
        'scaleMode': _scaleMode,
        'smartOrientation': _smartOrientation,
        'smartCopies': _smartCopies,
      });

      // Store the lightweight vector-based layout PDF.
      // B&W conversion is NOT done here — it happens at print time inside onLayout
      // to avoid holding two massive rasterized copies in memory simultaneously.
      if (mounted) {
        setState(() {
          _processedPdfBytes = layoutBytes;
          _isProcessingPdf = false;
        });
      }
    } catch (e) {
      debugPrint('Error generating N-up PDF: $e');
      if (mounted) {
        setState(() => _isProcessingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_serverError) {
      return Scaffold(
        appBar: AppBar(title: const Text('PDF Print'), centerTitle: true),
        body: Center(
          child: ConnectionErrorCard(
            onDismiss: () => setState(() => _serverError = false),
            onReconnect: () => context.go('/connect'),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final fileName = widget.file != null ? p.basenameWithoutExtension(widget.file!.name) : 'Document';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(theme, fileName),
            Expanded(
            child: OrientationBuilder(
              builder: (context, orientation) {
                if (orientation == Orientation.portrait) {
                  return Column(
                    children: [
                      // Top Preview Area (40% height)
                      Expanded(
                        flex: 2,
                        child: _buildPreviewArea(theme),
                      ),
                      // Bottom Sidebar (60% height)
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
                      // Left Sidebar
                      _buildSidebar(theme),
                      // Right Preview Area
                      Expanded(
                        child: _buildPreviewArea(theme),
                      ),
                    ],
                  );
                }
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

  Widget _buildTopBar(ThemeData theme, String fileName) {
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$fileName - Print',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          if (_totalSheets > 0)
            Text(
              'Total: $_totalSheets sheet(s) of paper',
              style: theme.textTheme.bodyMedium,
            ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf'],
              );
              if (result != null && result.paths.isNotEmpty) {
                final validPath = result.paths.first;
                if (validPath != null) {
                  if (!mounted) return;
                  context.pushReplacement('/print-dialog', extra: [validPath]);
                }
              }
            },
            icon: const Icon(Icons.file_open, size: 16),
            label: const Text('Change Document'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.fullscreen, color: theme.iconTheme.color, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.close, color: theme.iconTheme.color, size: 20),
            onPressed: () => context.go('/'),
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
            // Removed Printer dropdown
            const SizedBox(height: 16),
            Text('Copies', style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _copies = (_copies > 1) ? _copies - 1 : 1;
                      _copiesController.text = _copies.toString();
                      if (_smartCopies && _pagesPerSheet > 1) _updateProcessedPdf();
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
                      controller: _copiesController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                         setState(() => _copies = int.tryParse(val) ?? 1);
                         if (_smartCopies && _pagesPerSheet > 1) _updateProcessedPdf();
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
                      _copies++;
                      _copiesController.text = _copies.toString();
                      if (_smartCopies && _pagesPerSheet > 1) _updateProcessedPdf();
                    });
                  },
                  icon: const Icon(Icons.add, size: 16),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDropdown('Colour', _colorMode, ['Color', 'Black and white'], (val) {
              setState(() => _colorMode = val!);
              // No need to regenerate PDF — preview uses visual filter,
              // actual B&W conversion happens at print time.
            }, theme),
            const SizedBox(height: 16),
            _buildDropdown('Print on both sides', _duplexMode, ['Print on one side', 'Print on both sides'], (val) => setState(() => _duplexMode = val!), theme),
            const SizedBox(height: 16),
            _buildDropdown('Paper size', _paperSize, ['A4', 'A3', 'Letter', 'Legal', 'Foolscap (8.5x13.5")'], (val) {
              setState(() => _paperSize = val!); 
              _updateProcessedPdf();
            }, theme),
            const SizedBox(height: 16),
            _buildDropdown('Orientation', _orientation, ['Auto', 'Portrait', 'Landscape'], (val) {
              setState(() => _orientation = val!); 
              _updateProcessedPdf();
            }, theme),
            Row(
              children: [
                Checkbox(
                  value: _smartOrientation,
                  onChanged: (val) {
                    setState(() => _smartOrientation = val ?? true);
                    _updateProcessedPdf();
                  },
                  activeColor: theme.colorScheme.primary,
                  visualDensity: VisualDensity.compact,
                ),
                Text('Smart Auto-fit', style: theme.textTheme.bodySmall),
              ],
            ),
            if (_pagesPerSheet > 1)
              Row(
                children: [
                  Checkbox(
                    value: _smartCopies,
                    onChanged: (val) {
                      setState(() => _smartCopies = val ?? false);
                      _updateProcessedPdf();
                    },
                    activeColor: theme.colorScheme.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                  Text('Smart Copies (Fill Page)', style: theme.textTheme.bodySmall),
                ],
              ),
            const SizedBox(height: 16),
            _buildDropdown('Scale (%)', _scaleMode, ['Fit to printable area', 'Actual size'], (val) {
              setState(() => _scaleMode = val!); 
              _updateProcessedPdf();
            }, theme),
            const SizedBox(height: 16),
            _buildDropdown('Pages per sheet', '$_pagesPerSheet', ['1', '2', '4', '6', '9', '16'], (val) {
              setState(() => _pagesPerSheet = int.parse(val!));
              _updateProcessedPdf();
            }, theme),
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
          const Spacer(),
          ElevatedButton(
            onPressed: _isProcessingPdf ? null : () async {
              if (_processedPdfBytes == null) return;
              
              setState(() => _isProcessingPdf = true);
              try {
                 // Capture these values before the async gap so they don't change
                 final printBytes = _processedPdfBytes!;
                 final copies = _copies;
                 final smartCopies = _smartCopies;
                 final pagesPerSheet = _pagesPerSheet;
                 final colorMode = _colorMode;

                 // Build the final print document with copies
                 Uint8List bytesToPrint;
                 if (copies <= 1 || (smartCopies && pagesPerSheet > 1)) {
                   bytesToPrint = printBytes;
                 } else {
                   // We must multiply copies locally because the server does not support
                   // the copies parameter for PDFs in its Printing.directPrintPdf call
                   final doc = PdfDocument();
                   final templateDoc = PdfDocument(inputBytes: printBytes);
                   for (int i = 0; i < copies; i++) {
                     for (int pg = 0; pg < templateDoc.pages.count; pg++) {
                       final page = templateDoc.pages[pg];
                       doc.pageSettings.size = page.size;
                       doc.pageSettings.margins.all = 0;
                       doc.pageSettings.orientation = page.size.width > page.size.height ? PdfPageOrientation.landscape : PdfPageOrientation.portrait;
                       final template = page.createTemplate();
                       final newPage = doc.pages.add();
                       newPage.graphics.drawPdfTemplate(template, Offset.zero, page.size);
                     }
                   }
                   final bytes = doc.saveSync();
                   templateDoc.dispose();
                   doc.dispose();
                   bytesToPrint = Uint8List.fromList(bytes);
                 }

                 final apiService = ApiService();
                 final base = widget.file != null ? p.basename(widget.file!.name) : 'Document';
                 final finalName = base.toLowerCase().endsWith('.pdf') ? base : '$base.pdf';
                 final multipartFile = http.MultipartFile.fromBytes(
                    'files[]', 
                    bytesToPrint, 
                    filename: finalName
                 );
                 
                 // Since we multiplied copies locally in the PDF, we tell the server 1 copy
                 // so it doesn't double-charge if it calculates price based on copies.
                 // Actually, server price calculation: pageCount * copies.
                 // Wait, if we multiplied the pages, the pageCount is higher.
                 // The server calculates price as: copies * (pageCount / pagesPerSheet) * price.
                 // Since we already multiplied the pages inside the PDF, we must send copies = 1 to the server.
                 final response = await apiService.uploadPrintJob(
                   fileBytes: [multipartFile],
                   category: 'document',
                   copies: 1, // Already multiplied in PDF
                   pageCount: _totalPdfPages * _copies,
                   colorMode: colorMode == 'Color' ? 'color' : 'bw',
                   paperSize: _paperSize.toLowerCase().split(' ')[0], // A4, A3, letter, legal
                   orientation: _orientation.toLowerCase(),
                   printSides: _duplexMode.contains('both') ? 'duplex' : 'single',
                 );

                 if (!mounted) return;
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Print Job sent successfully!')),
                 );
                 context.go('/tracking', extra: response['id']);

                 // Force GC after printing to reclaim any temporary buffers
                 PaintingBinding.instance.imageCache.clear();
              } catch (e) {
                 debugPrint('Print error: $e');
                 if (!mounted) return;
                 if (e.toString().contains('SERVER_OFFLINE')) {
                   setState(() => _serverError = true);
                 } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Failed to send print job: $e')),
                   );
                 }
              } finally {
                 if (mounted) {
                    setState(() => _isProcessingPdf = false);
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

  Widget _buildPreviewArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(40),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Builder(
          builder: (context) {
            double ratio = 1 / 1.414;
            if (_paperSize.contains('Letter')) {
              ratio = 8.5 / 11.0;
            } else if (_paperSize.contains('Legal')) {
              ratio = 8.5 / 14.0;
            } else if (_paperSize.contains('Foolscap')) {
              ratio = 8.5 / 13.5;
            } else if (_paperSize.contains('A3')) {
              ratio = 1 / 1.414;
            }
            
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
            child: widget.file == null
                ? Center(child: Text('No PDF Selected', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.black)))
                : _colorMode == 'Black and white'
                    ? ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0, 0, 0, 1, 0,
                        ]),
                        child: _buildPdfViewer(),
                      )
                    : _buildPdfViewer(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    if (_isProcessingPdf) {
       return const Center(child: CircularProgressIndicator());
    }
    if (_processedPdfBytes == null) {
       return const Center(child: Text('Failed to load PDF'));
    }
    return SfPdfViewer.memory(
      _processedPdfBytes!,
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        setState(() {
          _totalPdfPages = details.document.pages.count;
        });
      },
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged, ThemeData theme) {
    final items = {value, ...options}.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: theme.colorScheme.surfaceContainerHighest,
              icon: Icon(Icons.keyboard_arrow_down, size: 16, color: theme.colorScheme.onSurfaceVariant),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: theme.textTheme.bodyMedium))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

Future<Uint8List> _generateNUpPdf(Map<String, dynamic> params) async {
  final originalBytes = params['originalBytes'] as Uint8List;
  final paperSize = params['paperSize'] as String;
  final orientation = params['orientation'] as String;
  final pagesPerSheet = params['pagesPerSheet'] as int;
  final copies = params['copies'] as int;
  final scaleMode = params['scaleMode'] as String;
  final smartOrientation = params['smartOrientation'] as bool;
  final smartCopies = params['smartCopies'] as bool;

  final originalDoc = PdfDocument(inputBytes: originalBytes);
  final newDoc = PdfDocument();
  
  int rows = pagesPerSheet == 2 ? 2 : (pagesPerSheet == 4 ? 2 : (pagesPerSheet == 6 ? 3 : (pagesPerSheet == 9 ? 3 : (pagesPerSheet == 16 ? 4 : 1))));
  int cols = pagesPerSheet == 2 ? 1 : (pagesPerSheet == 4 ? 2 : (pagesPerSheet == 6 ? 2 : (pagesPerSheet == 9 ? 3 : (pagesPerSheet == 16 ? 4 : 1))));
  
  Size sheetSize;
  if (paperSize.contains('Letter')) {
    sheetSize = const Size(612, 792);
  } else if (paperSize.contains('Legal')) {
              sheetSize = const Size(612, 1008);
            } else if (paperSize.contains('Foolscap')) {
              sheetSize = const Size(612, 972);
            } else if (paperSize.contains('A3')) {
              sheetSize = const Size(842, 1191);
            } else {
              sheetSize = const Size(595, 842);
            } // A4 default

  bool isLandscape = orientation == 'Landscape';
  if (orientation == 'Auto' && originalDoc.pages.count > 0) {
     final firstPage = originalDoc.pages[0].size;
     isLandscape = firstPage.width > firstPage.height;
  }

  if (isLandscape) {
     sheetSize = Size(sheetSize.height, sheetSize.width);
     final temp = rows;
     rows = cols;
     cols = temp;
  }
  
  newDoc.pageSettings.size = sheetSize;
  newDoc.pageSettings.orientation = isLandscape ? PdfPageOrientation.landscape : PdfPageOrientation.portrait;
  newDoc.pageSettings.margins.all = 0;
  
  int pageIndex = 0;
  final int totalOriginalPages = originalDoc.pages.count;
  final int virtualTotalPages = totalOriginalPages * (smartCopies && pagesPerSheet > 1 ? copies : 1);
  
  while (pageIndex < virtualTotalPages) {
    final PdfPage newPage = newDoc.pages.add();
    final double cellWidth = sheetSize.width / cols;
    final double cellHeight = sheetSize.height / rows;
    
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (pageIndex >= virtualTotalPages) break;
        
        int actualPageIndex = pageIndex % totalOriginalPages;
        final PdfPage originalPage = originalDoc.pages[actualPageIndex];
        final PdfTemplate template = originalPage.createTemplate();
        
        final double margin = 10.0;
        final double availableWidth = cellWidth - (margin * 2);
        final double availableHeight = cellHeight - (margin * 2);
        
        double scale = min(availableWidth / originalPage.size.width, availableHeight / originalPage.size.height);
        double scaleRotated = min(availableWidth / originalPage.size.height, availableHeight / originalPage.size.width);
        
        bool shouldRotate = smartOrientation && (scaleRotated > scale);
        double finalScale = shouldRotate ? scaleRotated : scale;
        
        if (scaleMode == 'Actual size') {
           finalScale = finalScale < 1.0 ? finalScale : 1.0;
        }
        
        final double scaledW = originalPage.size.width * finalScale;
        final double scaledH = originalPage.size.height * finalScale;
        
        newPage.graphics.save();
        newPage.graphics.translateTransform( 
          (c * cellWidth) + (cellWidth / 2),
          (r * cellHeight) + (cellHeight / 2)
        );
        
        if (shouldRotate) {
           newPage.graphics.rotateTransform(-90);
        }
        
        newPage.graphics.drawPdfTemplate(
          template,
          Offset(-scaledW / 2, -scaledH / 2),
          Size(scaledW, scaledH)
        );
        
        newPage.graphics.restore();
        pageIndex++;
      }
    }
  }
  
  final List<int> generatedBytes = await newDoc.save();
  originalDoc.dispose();
  newDoc.dispose();
  return Uint8List.fromList(generatedBytes);
}


