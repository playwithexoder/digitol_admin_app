import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_colors.dart';

/// Theme mode provider — manages light/dark/system mode toggle.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void toggle() {
    state = switch (state) {
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.system,
      ThemeMode.system => ThemeMode.dark,
    };
  }

  void setMode(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

/// Sleek expandable/retractable theme mode selector pill (Light | Dark | Auto System).
///
/// Retracted by default (showing only the active selection). Expands on hover or click.
class ThemeModeSelector extends ConsumerStatefulWidget {
  const ThemeModeSelector({super.key});

  @override
  ConsumerState<ThemeModeSelector> createState() => _ThemeModeSelectorState();
}

class _ThemeOption {
  final ThemeMode mode;
  final IconData icon;
  final String tooltip;
  const _ThemeOption(this.mode, this.icon, this.tooltip);
}

class _ThemeModeSelectorState extends ConsumerState<ThemeModeSelector> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentMode = ref.watch(themeModeProvider);
    final isDark = theme.brightness == Brightness.dark;

    final options = const [
      _ThemeOption(ThemeMode.light, Icons.light_mode_rounded, 'Light Mode'),
      _ThemeOption(ThemeMode.dark, Icons.dark_mode_rounded, 'Dark Mode'),
      _ThemeOption(ThemeMode.system, Icons.brightness_auto_rounded, 'System Auto Mode'),
    ];

    return TapRegion(
      onTapOutside: (_) {
        if (_isHovered) {
          setState(() => _isHovered = false);
        }
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          height: 38,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B1E2A) : const Color(0xFFE8ECF4),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _isHovered
                  ? AppColors.primaryTeal.withValues(alpha: 0.6)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.primaryTeal.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            clipBehavior: Clip.hardEdge,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < options.length; i++) ...[
                  if (_isHovered || options[i].mode == currentMode) ...[
                    if (_isHovered && i > 0) const SizedBox(width: 2),
                    _buildOption(
                      context,
                      ref,
                      mode: options[i].mode,
                      currentMode: currentMode,
                      icon: options[i].icon,
                      tooltip: options[i].tooltip,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    WidgetRef ref, {
    required ThemeMode mode,
    required ThemeMode currentMode,
    required IconData icon,
    required String tooltip,
  }) {
    final theme = Theme.of(context);
    final isSelected = mode == currentMode;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!_isHovered) {
              setState(() => _isHovered = true);
            } else {
              ref.read(themeModeProvider.notifier).setMode(mode);
            }
          },
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
