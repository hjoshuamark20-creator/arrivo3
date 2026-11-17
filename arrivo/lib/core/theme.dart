import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants.dart';

/// Light and dark Material 3 themes. Poppins for headings, Inter for body text.
class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final fg = isDark ? AppColors.offWhite : AppColors.navy;
    final border = isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? AppColors.tealLight : AppColors.darkTeal,
      onPrimary: isDark ? AppColors.navy : AppColors.offWhite,
      error: isDark ? const Color(0xFFFCA5A5) : AppColors.error,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? AppColors.deepNavy : AppColors.lightBg,
    );

    final body = GoogleFonts.interTextTheme(base.textTheme)
        .apply(bodyColor: fg, displayColor: fg);

    final textTheme = body.copyWith(
      headlineLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: fg),
      headlineMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: fg),
      titleLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: fg),
      titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: fg),
    );

    return base.copyWith(
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0x14FFFFFF) : const Color(0x80FFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.darkTeal,
        thumbColor: AppColors.darkTeal,
        inactiveTrackColor: Color(0x330F172A),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
