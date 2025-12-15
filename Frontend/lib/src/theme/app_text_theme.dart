import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme appTextTheme(BuildContext context) {
  final base = Theme.of(context).textTheme;

  if (kIsWeb) {
    // Web-safe fonts (NO AssetManifest usage)
    return base.copyWith(
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      bodyMedium: base.bodyMedium,
    );
  }

  // Mobile (Android / iOS)
  return GoogleFonts.poppinsTextTheme(base);
}
