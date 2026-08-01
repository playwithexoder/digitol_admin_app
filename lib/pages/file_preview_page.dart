import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../services/api_service.dart';

class FilePreviewPage extends StatefulWidget {
  final Map<String, dynamic> job;

  const FilePreviewPage({super.key, required this.job});

  @override
  State<FilePreviewPage> createState() => _FilePreviewPageState();
}

class _FilePreviewPageState extends State<FilePreviewPage> {
  String? _fileUrl;
  String? _accessKey;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final api = ApiService();
    final url = await api.getAdminFileUrl(widget.job['id']);
    final key = await api.getAccessKey();
    
    if (mounted) {
      setState(() {
        _fileUrl = url;
        _accessKey = key;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.job['fileName'] as String? ?? 'Unknown File';
    final isPdf = fileName.toLowerCase().endsWith('.pdf');

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _fileUrl == null
              ? const Center(child: Text('Could not load file URL.'))
              : isPdf
                  ? SfPdfViewer.network(
                      _fileUrl!,
                      headers: _accessKey != null ? {'x-access-key': _accessKey!} : null,
                    )
                  : Center(
                      child: InteractiveViewer(
                        child: Image.network(
                          _fileUrl!,
                          headers: _accessKey != null ? {'x-access-key': _accessKey!} : null,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text('Error loading image. The file may no longer exist on the server.'),
                            );
                          },
                        ),
                      ),
                    ),
    );
  }
}
