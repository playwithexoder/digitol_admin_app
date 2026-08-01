import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nsd/nsd.dart' as nsd;
import 'dart:async';

import '../services/api_service.dart';

class RadarDiscoveryScreen extends StatefulWidget {
  const RadarDiscoveryScreen({super.key});

  @override
  State<RadarDiscoveryScreen> createState() => _RadarDiscoveryScreenState();
}

class _RadarDiscoveryScreenState extends State<RadarDiscoveryScreen> with SingleTickerProviderStateMixin {
  nsd.Discovery? _discovery;
  bool _isSearching = true;
  String _statusMessage = 'Searching for Digitol Print Server...';
  late AnimationController _radarController;
  final ApiService _apiService = ApiService();
  bool _found = false;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startDiscovery();
  }

  @override
  void dispose() {
    _radarController.dispose();
    _stopDiscovery();
    super.dispose();
  }

  Future<void> _startDiscovery() async {
    try {
      _discovery = await nsd.startDiscovery('_digitolprint._tcp');
      _discovery!.addListener(_onServicesUpdated);
      
      // Auto timeout after 15 seconds if nothing is found
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted && !_found && _isSearching) {
          setState(() {
            _isSearching = false;
            _statusMessage = 'No server found nearby.';
          });
          _radarController.stop();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _statusMessage = 'Network discovery failed.';
        });
        _radarController.stop();
      }
    }
  }

  Future<void> _stopDiscovery() async {
    if (_discovery != null) {
      _discovery!.removeListener(_onServicesUpdated);
      await nsd.stopDiscovery(_discovery!);
      _discovery = null;
    }
  }

  void _onServicesUpdated() async {
    if (_found || _discovery == null) return;
    
    for (final service in _discovery!.services) {
      if (service.name == 'DigitolPrint Server' || service.type == '_digitolprint._tcp') {
        final host = service.host;
        if (host != null && host.isNotEmpty) {
          _found = true;
          _stopDiscovery();
          
          if (mounted) {
            setState(() {
              _statusMessage = 'Server found! Connecting...';
            });
            _radarController.stop();
          }

          // Save IP and navigate to Home
          await _apiService.saveServerIp(host);
          
          if (mounted) {
            // Give a short delay so user sees "Connecting..."
            await Future.delayed(const Duration(milliseconds: 800));
            if (mounted) context.go('/');
          }
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Image.asset('assets/images/logo.png', height: 60),
            const Spacer(),
            
            // Radar Animation Area
            SizedBox(
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isSearching)
                    AnimatedBuilder(
                      animation: _radarController,
                      builder: (context, child) {
                        return Container(
                          width: 200 * _radarController.value,
                          height: 200 * _radarController.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 1.0 - _radarController.value),
                              width: 2,
                            ),
                            color: theme.colorScheme.primary.withValues(alpha: (1.0 - _radarController.value) * 0.2),
                          ),
                        );
                      },
                    ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _found ? Colors.green : theme.colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: (_found ? Colors.green : theme.colorScheme.primary).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _found ? Icons.check : Icons.wifi_tethering,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            Text(
              _statusMessage,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const Spacer(),
            
            // Manual Fallback
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: OutlinedButton.icon(
                onPressed: () async {
                  // Navigate to Settings Page for manual entry
                  await context.push('/settings');
                  if (!context.mounted) return;
                  
                  // Check if IP is now set, if so, go home
                  final ip = await _apiService.getServerIp();
                  final tunnel = await _apiService.getTunnelUrl();
                  if (!context.mounted) return;
                  if ((ip != null && ip.isNotEmpty) || (tunnel != null && tunnel.isNotEmpty)) {
                    context.go('/');
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text('Enter IP Manually'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                ),
              ),
            ),
            
            TextButton(
              onPressed: () async {
                await context.push('/settings');
                if (!context.mounted) return;
                
                final ip = await _apiService.getServerIp();
                final tunnel = await _apiService.getTunnelUrl();
                if (!context.mounted) return;
                if ((ip != null && ip.isNotEmpty) || (tunnel != null && tunnel.isNotEmpty)) {
                  context.go('/');
                }
              },
              child: const Text('Skip / Configure Later'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
