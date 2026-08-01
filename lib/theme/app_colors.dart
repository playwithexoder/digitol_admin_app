import 'package:flutter/material.dart';

/// Digitol Print — Curated HSL Color Palette
///
/// A premium, modern color system built with harmonious HSL values.
/// Primary: Digitol Teal (#14D8B4)
/// Accent: Digitol Cyan (#00C8E8)
/// Semantic: Success (#22C55E), Warning (#F59E0B), Error (#EF4444)
abstract final class AppColors {
  // ─────────────────────────────────────────────
  // Primary — Digitol Teal (#14D8B4)
  // ─────────────────────────────────────────────
  static const Color primary50 = Color(0xFFE0FEFA);
  static const Color primary100 = Color(0xFFB0FBF1);
  static const Color primary200 = Color(0xFF72F5E4);
  static const Color primary300 = Color(0xFF34EDD6);
  static const Color primary400 = Color(0xFF14D8B4);
  static const Color primary500 = Color(0xFF14D8B4); // Main Primary
  static const Color primary600 = Color(0xFF0FB899);
  static const Color primary700 = Color(0xFF0A947A);
  static const Color primary800 = Color(0xFF066E5B);
  static const Color primary900 = Color(0xFF04483C);

  // ─────────────────────────────────────────────
  // Accent — Digitol Cyan (#00C8E8)
  // ─────────────────────────────────────────────
  static const Color accent50 = Color(0xFFE0F9FF);
  static const Color accent100 = Color(0xFFB3F0FF);
  static const Color accent200 = Color(0xFF80E6FF);
  static const Color accent300 = Color(0xFF4DDCFF);
  static const Color accent400 = Color(0xFF00C8E8);
  static const Color accent500 = Color(0xFF00C8E8); // Main Accent
  static const Color accent600 = Color(0xFF00A3BE);
  static const Color accent700 = Color(0xFF007E93);
  static const Color accent800 = Color(0xFF005969);
  static const Color accent900 = Color(0xFF00343E);

  // ─────────────────────────────────────────────
  // Neutral — Cool Gray & Slate
  // ─────────────────────────────────────────────
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF8F9FC);
  static const Color neutral100 = Color(0xFFF5F7FA); // Primary Text (#F5F7FA)
  static const Color neutral150 = Color(0xFFE8ECF4);
  static const Color neutral200 = Color(0xFFDFE3ED);
  static const Color neutral300 = Color(0xFFC5CBD9);
  static const Color neutral400 = Color(0xFFA6B2C2); // Secondary Text (#A6B2C2)
  static const Color neutral500 = Color(0xFF7B849E);
  static const Color neutral600 = Color(0xFF5C6480);
  static const Color neutral700 = Color(0xFF203445); // Borders (#203445)
  static const Color neutral800 = Color(0xFF182838);
  static const Color neutral900 = Color(0xFF0B1E2A);
  static const Color neutral950 = Color(0xFF07141D);

  // ─────────────────────────────────────────────
  // Semantic — Success (#22C55E)
  // ─────────────────────────────────────────────
  static const Color success50 = Color(0xFFE8FAF0);
  static const Color success100 = Color(0xFFBFF0D5);
  static const Color success200 = Color(0xFF81E4AD);
  static const Color success300 = Color(0xFF48D68A);
  static const Color success400 = Color(0xFF22C55E);
  static const Color success500 = Color(0xFF22C55E); // Main Success
  static const Color success600 = Color(0xFF16A34A);
  static const Color success700 = Color(0xFF15803D);
  static const Color success800 = Color(0xFF166534);
  static const Color success900 = Color(0xFF14532D);

  // ─────────────────────────────────────────────
  // Semantic — Warning (#F59E0B)
  // ─────────────────────────────────────────────
  static const Color warning50 = Color(0xFFFFF8E6);
  static const Color warning100 = Color(0xFFFFEDB3);
  static const Color warning200 = Color(0xFFFFDF80);
  static const Color warning300 = Color(0xFFFFCE4D);
  static const Color warning400 = Color(0xFFF59E0B);
  static const Color warning500 = Color(0xFFF59E0B); // Main Warning
  static const Color warning600 = Color(0xFFD97706);
  static const Color warning700 = Color(0xFFB45309);
  static const Color warning800 = Color(0xFF92400E);
  static const Color warning900 = Color(0xFF78350F);

  // ─────────────────────────────────────────────
  // Semantic — Error (#EF4444)
  // ─────────────────────────────────────────────
  static const Color error50 = Color(0xFFFEECEE);
  static const Color error100 = Color(0xFFFDCDD1);
  static const Color error200 = Color(0xFFF99B9F);
  static const Color error300 = Color(0xFFF46B72);
  static const Color error400 = Color(0xFFEF4352);
  static const Color error500 = Color(0xFFEF4444); // Main Error
  static const Color error600 = Color(0xFFDC2626);
  static const Color error700 = Color(0xFFB91C1C);
  static const Color error800 = Color(0xFF991B1B);
  static const Color error900 = Color(0xFF7F1D1D);

  // ─────────────────────────────────────────────
  // Semantic — Info (#38BDF8)
  // ─────────────────────────────────────────────
  static const Color info50 = Color(0xFFE0F7FE);
  static const Color info100 = Color(0xFFBAE6FD);
  static const Color info200 = Color(0xFF7DD3FC);
  static const Color info300 = Color(0xFF38BDF8);
  static const Color info400 = Color(0xFF38BDF8);
  static const Color info500 = Color(0xFF38BDF8); // Main Info
  static const Color info600 = Color(0xFF0284C7);
  static const Color info700 = Color(0xFF0369A1);
  static const Color info800 = Color(0xFF075985);
  static const Color info900 = Color(0xFF0C4A6E);

  // ─────────────────────────────────────────────
  // Surface Colors — Light Mode
  // ─────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF5F6FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0F2F8);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);

  // ─────────────────────────────────────────────
  // Surface Colors — Dark Mode (Digitol Brand)
  // ─────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF07141D); // #07141D
  static const Color darkSurface = Color(0xFF121C2A); // Card #121C2A
  static const Color darkSurfaceVariant = Color(0xFF0B1E2A); // Secondary #0B1E2A
  static const Color darkSurfaceElevated = Color(0xFF182638);

  // ─────────────────────────────────────────────
  // Glass Effect Colors
  // ─────────────────────────────────────────────
  static Color glassLight = Colors.white.withValues(alpha: 0.08);
  static Color glassDark = Colors.white.withValues(alpha: 0.04);
  static Color glassBorder = Colors.white.withValues(alpha: 0.12);

  // ─────────────────────────────────────────────
  // Semantic Aliases (Digitol Brand)
  // ─────────────────────────────────────────────
  static const Color primaryTeal = primary500;
  static const Color primaryCyan = accent500;
  static const Color primaryText = neutral100;
  static const Color secondaryText = neutral400;
  static const Color border = neutral700;
  static const Color primaryBackground = darkBackground;
  static const Color secondaryBackground = darkSurfaceVariant;
  static const Color cardBackground = darkSurface;
  static const Color success = success500;
  static const Color warning = warning500;
  static const Color error = error500;
  static const Color info = info500;
}
