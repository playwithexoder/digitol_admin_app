import 'package:flutter/material.dart';
import '../constants.dart';

class ImagePrintOptionsPanel extends StatelessWidget {
  const ImagePrintOptionsPanel({
    super.key,
    required this.selectedLayout,
    required this.onLayoutChanged,
    required this.fitToFrame,
    required this.onFitToFrameChanged,
  });

  final ImageLayout selectedLayout;
  final ValueChanged<ImageLayout> onLayoutChanged;
  final bool fitToFrame;
  final ValueChanged<bool> onFitToFrameChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(left: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Right Panel (Layouts)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: ImageLayout.values.length,
              itemBuilder: (context, index) {
                final layout = ImageLayout.values[index];
                final isSelected = selectedLayout == layout;

                return InkWell(
                  onTap: () => onLayoutChanged(layout),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildLayoutIcon(layout, isSelected),
                        const SizedBox(height: 8),
                        Text(
                          layout.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: fitToFrame,
                    onChanged: (val) {
                      if (val != null) onFitToFrameChanged(val);
                    },
                    activeColor: theme.colorScheme.primary,
                    checkColor: const Color(0xFF07141D),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fit picture to frame',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutIcon(ImageLayout layout, bool isSelected) {
    final color = isSelected ? Colors.blue : Colors.grey;
    IconData icon;
    switch (layout) {
      case ImageLayout.fullPage:
      case ImageLayout.eightByTen:
      case ImageLayout.fiveBySeven:
        icon = Icons.crop_square;
        break;
      case ImageLayout.twoUp:
      case ImageLayout.fourBySix:
      case ImageLayout.hagaki:
      case ImageLayout.threeHalfByFive:
        icon = Icons.splitscreen;
        break;
      case ImageLayout.fourUp:
      case ImageLayout.twoByThreeWallet:
        icon = Icons.grid_view;
        break;
      case ImageLayout.nineUp:
      case ImageLayout.sixByEightWallet:
        icon = Icons.grid_on;
        break;
    }
    return Icon(icon, color: color, size: 32);
  }
}
