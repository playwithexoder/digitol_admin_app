import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nsd/nsd.dart' as nsd;
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _ipController = TextEditingController();
  final _tunnelController = TextEditingController();
  final _accessKeyController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = true;
  nsd.Discovery? _discovery;

  @override
  void initState() {
    super.initState();
    _loadIp();
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    try {
      _discovery = await nsd.startDiscovery('_digitolprint._tcp');
      _discovery?.addListener(() {
        if (!mounted) return;
        final services = _discovery?.services ?? [];
        if (services.isNotEmpty) {
          final service = services.first;
          final host = service.host;
          if (host != null && host.isNotEmpty) {
            if (_ipController.text.isEmpty) {
              setState(() {
                _ipController.text = host;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Found local server at $host')),
              );
            }
          }
        }
      });
    } catch (e) {
      debugPrint('mDNS Discovery error: $e');
    }
  }

  Future<void> _loadIp() async {
    final ip = await _apiService.getServerIp();
    final tunnel = await _apiService.getTunnelUrl();
    final accessKey = await _apiService.getAccessKey();
    final name = await _apiService.getCustomerName();
    final phone = await _apiService.getCustomerPhone();
    if (ip != null) {
      _ipController.text = ip;
    }
    if (tunnel != null) {
      _tunnelController.text = tunnel;
    }
    if (accessKey != null) {
      _accessKeyController.text = accessKey;
    }
    if (name != null) {
      _nameController.text = name;
    }
    if (phone != null) {
      _phoneController.text = phone;
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveIp() async {
    await _apiService.saveServerIp(_ipController.text.trim());
    await _apiService.saveTunnelUrl(_tunnelController.text.trim());
    await _apiService.saveAccessKey(_accessKeyController.text.trim());
    await _apiService.saveCustomerName(_nameController.text.trim());
    await _apiService.saveCustomerPhone(_phoneController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved!')),
      );
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _tunnelController.dispose();
    _accessKeyController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    if (_discovery != null) {
      nsd.stopDiscovery(_discovery!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Main DigitolPrint Server',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the IP address of the Windows PC running the main DigitolPrint app.',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Local IP Address (In Store)',
                hintText: 'e.g., 192.168.1.10',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wifi),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tunnelController,
              decoration: const InputDecoration(
                labelText: 'Remote Tunnel URL',
                hintText: 'e.g., https://my-tunnel.loca.lt',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cloud),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            TextField(
              controller: _accessKeyController,
              decoration: const InputDecoration(
                labelText: 'Admin Access Key',
                hintText: 'Enter your Admin PIN/Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navigate to Radar Discovery Screen to auto-scan
                  context.push('/radar');
                },
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('Scan for Server Automatically'),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Default Print Job Details (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Default Customer Name',
                hintText: 'e.g., Walk-in Customer',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Default Contact Number',
                hintText: 'e.g., +1 234 567 8900',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveIp,
                child: const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
