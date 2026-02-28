import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: DT.accent,
      primary: DT.primary,
      secondary: DT.accent,
      surface: DT.background,
      brightness: Brightness.light,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: DT.background,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: DT.primary,
        displayColor: DT.primary,
      ),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: DT.background,
        foregroundColor: DT.primaryVariant,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: DT.primaryVariant,
        ),
        iconTheme: const IconThemeData(color: DT.primaryVariant),
      ),
      cardTheme: CardThemeData(
        color: DT.surface,
        elevation: DT.elevation,
        margin: const EdgeInsets.symmetric(horizontal: DT.gap),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DT.radius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DT.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 3,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DT.primary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: DT.primary.withValues(alpha: 0.08)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DT.accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DT.accent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: DT.surface,
        selectedItemColor: DT.primaryVariant,
        unselectedItemColor: DT.muted,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        elevation: 12,
        showSelectedLabels: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DT.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: DT.muted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: DT.surfaceElevated,
        selectedColor: DT.accent.withValues(alpha: 0.12),
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: DT.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      iconTheme: const IconThemeData(size: 20, color: Color(0xFF0B1220)),
    );
  }

  static ThemeData dark() {
    final colorScheme =
        ColorScheme.fromSeed(seedColor: DT.accent, brightness: Brightness.dark);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme().apply(bodyColor: Colors.white),
      scaffoldBackgroundColor: const Color(0xFF071026),
      cardTheme: CardThemeData(
        color: const Color(0xFF071026),
        elevation: DT.elevationLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DT.radius),
        ),
      ),
    );
  }
}
