import 'package:flutter/material.dart';
import 'pdf_print_view.dart';
import 'image_print_view.dart';
import 'package:file_picker/file_picker.dart';

class PrintDialogPage extends StatelessWidget {
  final List<String> filePaths;

  const PrintDialogPage({super.key, required this.filePaths});

  @override
  Widget build(BuildContext context) {
    if (filePaths.isEmpty) {
      return const Scaffold(body: Center(child: Text('No files selected')));
    }

    // Determine type from first file
    final firstFile = filePaths.first;
    final isPdf = firstFile.toLowerCase().endsWith('.pdf');

    if (isPdf) {
      return PdfPrintView(file: PlatformFile(name: firstFile, size: 0, path: firstFile));
    } else {
      return ImagePrintView(files: filePaths.map((p) => PlatformFile(name: p, size: 0, path: p)).toList());
    }
  }
}
