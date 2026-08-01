import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ConnectMethodPage extends StatelessWidget {
  const ConnectMethodPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('assets/images/logo.png', height: 80)
                .animate().fadeIn(duration: 500.ms).scaleXY(begin: 0.8, end: 1.0, curve: Curves.easeOutBack),
              const SizedBox(height: 48),
              Text(
                'Welcome to Digitol Print',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
              const SizedBox(height: 16),
              Text(
                'How are you connecting to the server today?',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
              const SizedBox(height: 48),
              
              // Local Wi-Fi Card
              _ConnectionCard(
                icon: Icons.wifi_tethering,
                title: 'In Store (Wi-Fi)',
                subtitle: 'I am currently connected to the local Wi-Fi network.',
                color: theme.colorScheme.primary,
                onTap: () {
                  context.push('/radar');
                },
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              
              const SizedBox(height: 24),
              
              // Remote Internet Card
              _ConnectionCard(
                icon: Icons.cloud_outlined,
                title: 'Remote (Internet)',
                subtitle: 'I am at home or on mobile data (4G/5G).',
                color: Colors.orange.shade600,
                onTap: () {
                  context.push('/remote-connect');
                },
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              
              const SizedBox(height: 32),
              TextButton(
                onPressed: () {
                  context.go('/');
                },
                child: const Text('Skip / Enter IP Later'),
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ConnectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
        ),
      ),
    );
  }
}
