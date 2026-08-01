import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../widgets/connection_error_card.dart';

class AIBgRemoverPage extends StatefulWidget {
  const AIBgRemoverPage({super.key});

  @override
  State<AIBgRemoverPage> createState() => _AIBgRemoverPageState();
}

class _AIBgRemoverPageState extends State<AIBgRemoverPage> {
  Uint8List? _originalImageBytes;
  Uint8List? _processedImageBytes;
  bool _isProcessing = false;
  String _status = '';
  bool _serverError = false;
  
  // Advanced Settings
  String _selectedModel = 'u2net';
  bool _alphaMatting = false;
  Color _bgColor = Colors.transparent;

  final List<Map<String, String>> _models = [
    {'value': 'u2net', 'label': 'General (Balanced)'},
    {'value': 'isnet-general', 'label': 'Products, Logos & Objects'},
    {'value': 'birefnet-portrait', 'label': 'Portraits & People'},
  ];

  final List<Color> _presetColors = [
    Colors.transparent,
    Colors.white,
    Colors.black,
    Colors.blue.shade100,
    Colors.green.shade100,
    Colors.pink.shade100,
  ];

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _originalImageBytes = result.files.first.bytes;
        _processedImageBytes = null;
        _status = '';
      });
    }
  }

  Future<void> _removeBackground() async {
    if (_originalImageBytes == null) return;
    
    setState(() {
      _isProcessing = true;
      _status = 'Uploading...';
    });

    try {
      final apiService = ApiService();
      final ip = await apiService.getServerIp();
      final tunnel = await apiService.getTunnelUrl();
      
      String? activeHost;
      if (tunnel != null && tunnel.isNotEmpty) {
        activeHost = tunnel;
      } else if (ip != null && ip.isNotEmpty) {
        activeHost = ip;
      }

      if (activeHost == null) {
        setState(() {
          _isProcessing = false;
          _status = '';
          _serverError = true;
        });
        return;
      }

      Uri uri;
      if (activeHost.startsWith('http://') || activeHost.startsWith('https://')) {
        final baseUrl = activeHost.endsWith('/') ? activeHost.substring(0, activeHost.length - 1) : activeHost;
        uri = Uri.parse('$baseUrl/api/ai/remove-bg');
      } else {
        uri = Uri.parse('http://$activeHost:8080/api/ai/remove-bg');
      }

      final request = http.MultipartRequest('POST', uri);
      final accessKey = await apiService.getAccessKey();
      if (accessKey != null && accessKey.isNotEmpty) {
        request.headers['x-access-key'] = accessKey;
      }
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _originalImageBytes!,
          filename: 'upload.png',
        ),
      );
      
      request.fields['model'] = _selectedModel;
      request.fields['alpha_matting'] = _alphaMatting.toString();
      
      if (_bgColor != Colors.transparent) {
        // format color as #RRGGBB
        String hex = '#${_bgColor.toARGB32().toRadixString(16).substring(2, 8).toUpperCase()}';
        request.fields['bg_color'] = hex;
      }

      setState(() => _status = 'AI is processing...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() {
          _processedImageBytes = response.bodyBytes;
          _status = 'Success!';
        });
      } else {
        setState(() {
          _status = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _status = '';
        _serverError = true;
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Background Remover'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_originalImageBytes == null)
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload, size: 64, color: theme.colorScheme.primary),
                      const SizedBox(height: 16),
                      Text('Tap to select an image', style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
              ).animate().fadeIn()
            else if (_serverError)
              ConnectionErrorCard(
                onDismiss: () => setState(() => _serverError = false),
                onReconnect: () {
                  setState(() => _serverError = false);
                  context.push('/connect');
                },
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack)
            else
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Original', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: MemoryImage(_originalImageBytes!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Result', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _isProcessing
                              ? const Center(child: CircularProgressIndicator())
                              : _processedImageBytes != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(_processedImageBytes!, fit: BoxFit.contain),
                                    )
                                  : Center(child: Text(_status.isEmpty ? 'Waiting...' : _status)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 24),
            
            // Advanced Settings
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    // Model Selection
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Subject Type (AI Model)',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedModel,
                      items: _models.map((m) {
                        return DropdownMenuItem<String>(
                          value: m['value'],
                          child: Text(m['label']!),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedModel = val!);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Edge Refinement
                    SwitchListTile(
                      title: const Text('Edge Refinement (Alpha Matting)'),
                      subtitle: const Text('Improves edges for hair, fur, and glass'),
                      value: _alphaMatting,
                      onChanged: (val) {
                        setState(() => _alphaMatting = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Background Color
                    const Text('Background Color:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _presetColors.map((color) {
                        final isSelected = _bgColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _bgColor = color),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color == Colors.transparent ? Colors.grey.shade300 : color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? theme.colorScheme.primary : Colors.grey,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: color == Colors.transparent 
                              ? const Center(child: Text('None', style: TextStyle(fontSize: 10))) 
                              : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                if (_originalImageBytes != null)
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Change'),
                  ),
                FilledButton.icon(
                  onPressed: _isProcessing || _originalImageBytes == null ? null : _removeBackground,
                  icon: const Icon(Icons.auto_fix_high),
                  label: Text(_isProcessing ? 'Processing...' : 'Remove BG'),
                ),
                if (_processedImageBytes != null) ...[
                  FilledButton.icon(
                    onPressed: () {
                      final file = PlatformFile(
                        name: 'ai_processed.png',
                        size: _processedImageBytes!.length,
                        bytes: _processedImageBytes,
                      );
                      context.push('/print/image', extra: [file]);
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.green.shade600),
                  ).animate().scale(),
                  FilledButton.icon(
                    onPressed: () {
                      final file = PlatformFile(
                        name: 'ai_processed.png',
                        size: _processedImageBytes!.length,
                        bytes: _processedImageBytes,
                      );
                      context.push('/print/passport', extra: [file]);
                    },
                    icon: const Icon(Icons.contact_page),
                    label: const Text('Passport'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.purple.shade600),
                  ).animate().scale(),
                  FilledButton.icon(
                    onPressed: () {
                      final file = PlatformFile(
                        name: 'ai_processed.png',
                        size: _processedImageBytes!.length,
                        bytes: _processedImageBytes,
                      );
                      context.push('/print/quick_send', extra: [file]);
                    },
                    icon: const Icon(Icons.bolt),
                    label: const Text('Quick Send'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade600),
                  ).animate().scale(),
                  FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Image is ready. Use Quick Send to transfer to PC!')),
                      );
                    },
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Save'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade700),
                  ).animate().scale(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
