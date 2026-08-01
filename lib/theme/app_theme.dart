import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Digitol Print — Material 3 Theme
///
/// Builds complete light and dark ThemeData with the design system tokens.
abstract final class AppTheme {
  // ─────────────────────────────────────────────
  // Light Theme
  // ─────────────────────────────────────────────
  static ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary500,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primary100,
      onPrimaryContainer: AppColors.primary900,
      secondary: AppColors.accent500,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.accent100,
      onSecondaryContainer: AppColors.accent900,
      tertiary: AppColors.warning500,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.warning100,
      onTertiaryContainer: AppColors.warning900,
      error: AppColors.error500,
      onError: Colors.white,
      errorContainer: AppColors.error100,
      onErrorContainer: AppColors.error900,
      surface: AppColors.lightSurface,
      onSurface: AppColors.neutral900,
      surfaceContainerHighest: AppColors.lightSurfaceVariant,
      onSurfaceVariant: AppColors.neutral600,
      outline: AppColors.neutral300,
      outlineVariant: AppColors.neutral200,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.neutral900,
      onInverseSurface: AppColors.neutral50,
      inversePrimary: AppColors.primary200,
    );

    return _buildTheme(colorScheme, Brightness.light);
  }

  // ─────────────────────────────────────────────
  // Dark Theme
  // ─────────────────────────────────────────────
  static ThemeData get dark {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary400,
      onPrimary: AppColors.primary900,
      primaryContainer: AppColors.primary800,
      onPrimaryContainer: AppColors.primary100,
      secondary: AppColors.accent400,
      onSecondary: AppColors.accent900,
      secondaryContainer: AppColors.accent800,
      onSecondaryContainer: AppColors.accent100,
      tertiary: AppColors.warning400,
      onTertiary: AppColors.warning900,
      tertiaryContainer: AppColors.warning800,
      onTertiaryContainer: AppColors.warning100,
      error: AppColors.error400,
      onError: AppColors.error900,
      errorContainer: AppColors.error800,
      onErrorContainer: AppColors.error100,
      surface: AppColors.darkSurface,
      onSurface: AppColors.neutral100,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      onSurfaceVariant: AppColors.neutral400,
      outline: AppColors.neutral700,
      outlineVariant: AppColors.neutral800,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.neutral100,
      onInverseSurface: AppColors.neutral900,
      inversePrimary: AppColors.primary700,
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  // ─────────────────────────────────────────────
  // Build Theme from ColorScheme
  // ─────────────────────────────────────────────
  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      scaffoldBackgroundColor:
          isLight ? AppColors.lightBackground : AppColors.darkBackground,
      // ── AppBar ──
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      // ── Cards ──
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      // ── Elevated Buttons ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(120, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),
      // ── Outlined Buttons ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(120, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),
      // ── Text Buttons ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(80, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),
      // ── Icon Buttons ──
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
        ),
      ),
      // ── Input Decoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? AppColors.lightSurfaceVariant
            : AppColors.darkSurfaceVariant,
        contentPadding: AppSpacing.inputPadding,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        labelStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
      // ── Dialogs ──
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXl,
        ),
      ),
      // ── Snack Bars ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isLight ? AppColors.neutral900 : AppColors.neutral100,
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: isLight ? Colors.white : AppColors.neutral900,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
      ),
      // ── Chips ──
      chipTheme: ChipThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusFull,
        ),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      // ── Tooltips ──
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isLight ? AppColors.neutral900 : AppColors.neutral100,
          borderRadius: AppSpacing.borderRadiusSm,
        ),
        textStyle: AppTypography.textTheme.bodySmall?.copyWith(
          color: isLight ? Colors.white : AppColors.neutral900,
        ),
        waitDuration: const Duration(milliseconds: 500),
      ),
      // ── Scrollbar ──
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered) ? 8 : 4,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
