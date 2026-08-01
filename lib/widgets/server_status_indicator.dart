import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class ServerStatusIndicator extends StatefulWidget {
  const ServerStatusIndicator({super.key});

  @override
  State<ServerStatusIndicator> createState() => _ServerStatusIndicatorState();
}

class _ServerStatusIndicatorState extends State<ServerStatusIndicator> {
  final ApiService _apiService = ApiService();
  String _status = 'checking'; // 'checking', 'online', 'offline'
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _checkStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final tunnelUrl = await _apiService.getTunnelUrl();
    final serverIp = await _apiService.getServerIp();
    
    final String url = (tunnelUrl != null && tunnelUrl.isNotEmpty) ? tunnelUrl : (serverIp ?? '');
    
    if (url.isEmpty) {
      if (mounted) setState(() => _status = 'offline');
      return;
    }

    try {
      final String baseUrl = url.startsWith('http') ? (url.endsWith('/') ? url.substring(0, url.length - 1) : url) : 'http://$url:8080';
      
      final accessKey = await _apiService.getAccessKey() ?? '';
      final headers = accessKey.isNotEmpty ? {'x-access-key': accessKey} : null;
      
      final response = await http.get(Uri.parse('$baseUrl/api/status'), headers: headers).timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _status = response.statusCode == 200 ? 'online' : 'offline';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _status = 'offline');
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    if (_status == 'online') {
      color = Colors.green;
    } else if (_status == 'offline') {
      color = Colors.red;
    } else {
      color = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: 'Server: ${_status.toUpperCase()}',
        child: Icon(
          Icons.circle,
          size: 12,
          color: color,
        ),
      ),
    );
  }
}
