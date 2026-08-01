import 'package:flutter/material.dart';

/// Digitol Print — Shadow Presets
///
/// Subtle, modern shadows for cards, elevation, and overlays.
abstract final class AppShadows {
  // ─────────────────────────────────────────────
  // Light Mode Shadows
  // ─────────────────────────────────────────────
  static List<BoxShadow> get cardLight => [
        BoxShadow(
          color: const Color(0xFF1A1F36).withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: const Color(0xFF1A1F36).withValues(alpha: 0.02),
          blurRadius: 24,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedLight => [
        BoxShadow(
          color: const Color(0xFF1A1F36).withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF1A1F36).withValues(alpha: 0.04),
          blurRadius: 40,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get floatingLight => [
        BoxShadow(
          color: const Color(0xFF1A1F36).withValues(alpha: 0.1),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: const Color(0xFF1A1F36).withValues(alpha: 0.06),
          blurRadius: 64,
          offset: const Offset(0, 16),
        ),
      ];

  // ─────────────────────────────────────────────
  // Dark Mode Shadows
  // ─────────────────────────────────────────────
  static List<BoxShadow> get cardDark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevatedDark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get floatingDark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ];

  // ─────────────────────────────────────────────
  // Glow Effects
  // ─────────────────────────────────────────────
  static List<BoxShadow> primaryGlow(double opacity) => [
        BoxShadow(
          color: const Color(0xFF14D8B4).withValues(alpha: opacity),
          blurRadius: 24,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> accentGlow(double opacity) => [
        BoxShadow(
          color: const Color(0xFF00C8E8).withValues(alpha: opacity),
          blurRadius: 24,
          offset: const Offset(0, 4),
        ),
      ];
}
