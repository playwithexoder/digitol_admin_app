import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_mode_provider.dart';
import '../widgets/server_status_indicator.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 28),
            const SizedBox(width: 8),
            Text(
              'Digitol',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18.0,
                letterSpacing: -0.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF14D8B4), Color(0xFF00C8E8)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PRINT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          const ServerStatusIndicator(),
          const ThemeModeSelector(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(theme),
          const _HistoryPlaceholder(), // We'll navigate instead for now
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            context.push('/history');
          } else if (index == 2) {
            context.push('/dashboard');
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What would you like to print?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _ActionTile(
                title: 'Document',
                subtitle: 'PDF, DOCX',
                icon: Icons.description,
                color: Colors.blue.shade600,
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    allowMultiple: true,
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'doc', 'docx'],
                    withData: kIsWeb,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    if (mounted) {
                      context.push('/print/pdf', extra: result.files);
                    }
                  }
                },
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms).scaleXY(begin: 0.9, end: 1.0, curve: Curves.easeOutBack),
              
              _ActionTile(
                title: 'Photo',
                subtitle: 'JPG, PNG',
                icon: Icons.photo_library,
                color: Colors.purple.shade600,
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    allowMultiple: true,
                    type: FileType.image,
                    withData: kIsWeb,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    if (mounted) {
                      context.push('/print/image', extra: result.files);
                    }
                  }
                },
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms).scaleXY(begin: 0.9, end: 1.0, curve: Curves.easeOutBack),
              
              _ActionTile(
                title: 'Passport Photo',
                subtitle: 'Standard Sizes',
                icon: Icons.portrait,
                color: Colors.teal.shade600,
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    allowMultiple: false,
                    type: FileType.image,
                    withData: kIsWeb,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    if (mounted) {
                      context.push('/print/passport', extra: result.files);
                    }
                  }
                },
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms).scaleXY(begin: 0.9, end: 1.0, curve: Curves.easeOutBack),
              
              _ActionTile(
                title: 'Quick Send',
                subtitle: 'Any Files',
                icon: Icons.send_rounded,
                color: Colors.blueGrey.shade600,
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    allowMultiple: true,
                    type: FileType.any,
                    withData: kIsWeb,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    if (mounted) {
                      context.push('/print/quick_send', extra: result.files);
                    }
                  }
                },
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms).scaleXY(begin: 0.9, end: 1.0, curve: Curves.easeOutBack),
              
              _ActionTile(
                title: 'Print History',
                subtitle: 'Past Prints',
                icon: Icons.history,
                color: Colors.orange.shade600,
                onTap: () => context.push('/history'),
              ).animate().fadeIn(duration: 400.ms, delay: 500.ms).scaleXY(begin: 0.9, end: 1.0, curve: Curves.easeOutBack),
              
              _ActionTile(
                title: 'AI BG Remover',
                subtitle: 'Magic Wand',
                icon: Icons.auto_fix_high,
                color: Colors.pink.shade500,
                onTap: () => context.push('/ai_bg_remover'),
              ).animate().fadeIn(duration: 400.ms, delay: 600.ms).scaleXY(begin: 0.9, end: 1.0, curve: Curves.easeOutBack),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryPlaceholder extends StatelessWidget {
  const _HistoryPlaceholder();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
