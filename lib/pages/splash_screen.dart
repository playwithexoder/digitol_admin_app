import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    
    final apiService = ApiService();
    final ip = await apiService.getServerIp();
    final tunnel = await apiService.getTunnelUrl();
    
    if ((ip != null && ip.isNotEmpty) || (tunnel != null && tunnel.isNotEmpty)) {
      if (mounted) context.go('/');
    } else {
      if (mounted) context.go('/connect-method');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', height: 120),
            const SizedBox(height: 24),
            Text(
              'Digitol Print',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
