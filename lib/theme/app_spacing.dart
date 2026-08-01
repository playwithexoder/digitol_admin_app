import 'package:flutter/material.dart';

/// Digitol Print — Spacing & Layout Tokens
///
/// Consistent spacing scale, border radii, breakpoints, and sizing constants.
abstract final class AppSpacing {
  // ─────────────────────────────────────────────
  // Spacing Scale (4px base)
  // ─────────────────────────────────────────────
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;
  static const double giant = 64;

  // ─────────────────────────────────────────────
  // Page Padding
  // ─────────────────────────────────────────────
  static const EdgeInsets pagePadding = EdgeInsets.all(24);
  static const EdgeInsets pagePaddingHorizontal = EdgeInsets.symmetric(
    horizontal: 24,
  );
  static const EdgeInsets sectionPadding = EdgeInsets.all(20);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(20);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 14,
  );

  // ─────────────────────────────────────────────
  // Border Radius
  // ─────────────────────────────────────────────
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 24;
  static const double radiusFull = 999;

  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );
  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );
  static const BorderRadius borderRadiusLg = BorderRadius.all(
    Radius.circular(radiusLg),
  );
  static const BorderRadius borderRadiusXl = BorderRadius.all(
    Radius.circular(radiusXl),
  );
  static const BorderRadius borderRadiusFull = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  // ─────────────────────────────────────────────
  // Responsive Breakpoints
  // ─────────────────────────────────────────────
  static const double breakpointMobile = 600;
  static const double breakpointTablet = 900;
  static const double breakpointDesktop = 1200;
  static const double breakpointWide = 1600;

  // ─────────────────────────────────────────────
  // Layout Dimensions
  // ─────────────────────────────────────────────
  static const double sidebarExpandedWidth = 260;
  static const double sidebarCollapsedWidth = 72;
  static const double topBarHeight = 64;
  static const double statCardMinWidth = 200;
  static const double maxContentWidth = 1400;

  // ─────────────────────────────────────────────
  // Animation Durations
  // ─────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 400);
  static const Duration animVerySlow = Duration(milliseconds: 600);

  // ─────────────────────────────────────────────
  // Animation Curves
  // ─────────────────────────────────────────────
  static const Curve animCurve = Curves.easeOutCubic;
  static const Curve animCurveEmphasized = Curves.easeInOutCubicEmphasized;
}
