import 'package:flutter/material.dart';

class DT {
  // Colors (primary palette + neutrals)
  static const Color primary = Color(0xFF0B1220); // deep indigo/near-black
  static const Color primaryVariant = Color(0xFF0F172A);
  static const Color accent = Color(0xFF06B6D4); // teal/cyan
  static const Color accentVariant = Color(0xFF0891B2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF8FAFC);
  static const Color background = Color(0xFFF7FAFC);
  static const Color muted = Color(0xFF6B7280);
  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Radii
  static const double radiusSm = 8.0;
  static const double radius = 12.0;
  static const double radiusLg = 18.0;

  // Elevations
  static const double elevationLow = 1.0;
  static const double elevation = 3.0;
  static const double elevationHigh = 8.0;

  // Spacing
  static const double gapXs = 6.0;
  static const double gapSm = 12.0;
  static const double gap = 16.0;
  static const double gapLg = 24.0;

  // Animation durations
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 450);

  // Fonts (names only — ensure added in pubspec)
  static const String brandFont = 'Poppins';
}
