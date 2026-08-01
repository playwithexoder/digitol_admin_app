import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../widgets/connection_error_card.dart';

class QuickSendView extends ConsumerStatefulWidget {
  final List<PlatformFile> files;

  const QuickSendView({super.key, required this.files});

  @override
  ConsumerState<QuickSendView> createState() => _QuickSendViewState();
}

class _QuickSendViewState extends ConsumerState<QuickSendView> {
  bool _isUploading = false;
  bool _serverError = false;
  String _customerName = '';

  Future<void> _uploadFiles() async {
    if (widget.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No files selected.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final apiService = ApiService();
      
      final files = widget.files;
      
      // Upload with category: raw
      final result = await apiService.uploadPrintJob(
        files: files,
        category: 'raw',
        customerName: _customerName.isNotEmpty ? _customerName : 'Walk-in Customer',
        colorMode: 'color', // Default ignored for raw
        copies: 1,
        pageCount: 1,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Files successfully added to Queue!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/tracking', extra: {'jobId': result['id'], 'type': 'raw'});
      }
    } catch (e) {
      if (mounted) {
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
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_serverError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quick Send'), centerTitle: true),
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
      appBar: AppBar(
        title: const Text('Quick Send'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.files.length} File(s) Selected',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.files.length,
                        separatorBuilder: (context, index) => Divider(color: theme.colorScheme.outlineVariant, height: 1),
                        itemBuilder: (context, index) {
                          final file = widget.files[index];
                          final fileName = file.name;
                          final size = file.size;
                          final sizeStr = '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
                          
                          return ListTile(
                            leading: const Icon(Icons.insert_drive_file),
                            title: Text(fileName, overflow: TextOverflow.ellipsis),
                            trailing: Text(sizeStr, style: theme.textTheme.bodySmall),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Optional Details',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Your Name (Optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      onChanged: (val) => _customerName = val,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blueGrey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'By clicking Send, these files will be transferred directly to the Queue.',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploading || widget.files.isEmpty ? null : _uploadFiles,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_isUploading ? 'Sending...' : 'Add to Queue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
