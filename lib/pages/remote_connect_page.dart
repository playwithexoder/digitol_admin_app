import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class RemoteConnectPage extends StatefulWidget {
  const RemoteConnectPage({super.key});

  @override
  State<RemoteConnectPage> createState() => _RemoteConnectPageState();
}

class _RemoteConnectPageState extends State<RemoteConnectPage> {
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final ip = await _apiService.getServerIp();
    final key = await _apiService.getAccessKey();
    if (ip != null && (ip.startsWith('http://') || ip.startsWith('https://'))) {
      _urlController.text = ip;
    }
    if (key != null) {
      _keyController.text = key;
    }
  }

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    final key = _keyController.text.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the Remote URL')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Save credentials
    await _apiService.saveServerIp(url);
    await _apiService.saveAccessKey(key);

    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/'); // Go to home dashboard
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Remote Connect'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.cloud_sync_rounded, size: 80, color: Colors.orange.shade600),
                const SizedBox(height: 24),
                Text(
                  'Connect via Internet',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter the Remote URL and Admin Access Key to manage the server remotely.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: 'Remote Tunnel URL',
                    hintText: 'e.g. https://my-shop.loca.lt',
                    prefixIcon: const Icon(Icons.link),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _keyController,
                  decoration: InputDecoration(
                    labelText: 'Admin Access Key',
                    hintText: 'Enter admin security key',
                    prefixIcon: const Icon(Icons.key),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _connect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Connect to Server', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
