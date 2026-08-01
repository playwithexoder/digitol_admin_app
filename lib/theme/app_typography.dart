import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Digitol Print — Typography System
///
/// Uses Plus Jakarta Sans (Google Fonts) with a responsive type scale.
/// Clean, modern, highly readable — optimized for desktop and long work sessions.
abstract final class AppTypography {
  // ─────────────────────────────────────────────
  // Base Text Theme (Light)
  // ─────────────────────────────────────────────
  static TextTheme get textTheme => TextTheme(
        // Display — Hero numbers, large dashboard stats
        displayLarge: _baseStyle(56, FontWeight.w700, -1.5),
        displayMedium: _baseStyle(44, FontWeight.w700, -0.5),
        displaySmall: _baseStyle(36, FontWeight.w600, 0),

        // Headline — Section headers, page titles
        headlineLarge: _baseStyle(32, FontWeight.w700, 0),
        headlineMedium: _baseStyle(28, FontWeight.w600, 0.15),
        headlineSmall: _baseStyle(24, FontWeight.w600, 0),

        // Title — Card titles, dialog titles
        titleLarge: _baseStyle(20, FontWeight.w600, 0.15),
        titleMedium: _baseStyle(16, FontWeight.w600, 0.15),
        titleSmall: _baseStyle(14, FontWeight.w600, 0.1),

        // Body — Paragraphs, descriptions
        bodyLarge: _baseStyle(16, FontWeight.w400, 0.5),
        bodyMedium: _baseStyle(14, FontWeight.w400, 0.25),
        bodySmall: _baseStyle(12, FontWeight.w400, 0.4),

        // Label — Buttons, chips, badges
        labelLarge: _baseStyle(14, FontWeight.w600, 0.1),
        labelMedium: _baseStyle(12, FontWeight.w500, 0.5),
        labelSmall: _baseStyle(11, FontWeight.w500, 0.5),
      );

  static TextStyle _baseStyle(
    double size,
    FontWeight weight,
    double letterSpacing,
  ) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: _lineHeight(size),
    );
  }

  /// Calculate comfortable line heights based on font size.
  static double _lineHeight(double fontSize) {
    if (fontSize >= 44) return 1.1;
    if (fontSize >= 32) return 1.2;
    if (fontSize >= 20) return 1.3;
    if (fontSize >= 16) return 1.5;
    return 1.4;
  }

  // ─────────────────────────────────────────────
  // Convenience Styles
  // ─────────────────────────────────────────────

  /// Large stat number for dashboard cards.
  static TextStyle get statValue => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      );

  /// Small stat label below dashboard numbers.
  static TextStyle get statLabel => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.4,
      );

  /// Sidebar navigation item.
  static TextStyle get navItem => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.4,
      );

  /// Monospaced for codes, IDs, etc.
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.5,
      );
}
