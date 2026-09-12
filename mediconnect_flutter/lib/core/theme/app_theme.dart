import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Soft Neumorphic Brand Palette (Matching User's Reference Image)
  static const Color primary = Color(0xFF2563EB); // Vibrant Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFDBEAFE);
  
  static const Color secondary = Color(0xFF4F46E5); // Indigo
  static const Color secondaryLight = Color(0xFFEEF2FF);

  static const Color emergency = Color(0xFFE11D48); // Rose Crimson
  static const Color emergencyLight = Color(0xFFFFE4E6);

  static const Color warning = Color(0xFFD97706); // Amber
  static const Color warningLight = Color(0xFFFEF3C7);

  static const Color success = Color(0xFF059669); // Emerald Green
  static const Color successLight = Color(0xFFD1FAE5);

  // Neumorphic Background & Surface Tones
  static const Color background = Color(0xFFE6EDF5);
  static const Color surface = Color(0xFFEAF0F8);
  static const Color surfaceVariant = Color(0xFFE2EAF4);

  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);

  static const Color border = Color(0xFFD8E2EE);

  // Dual Shadows for Neumorphic Depth
  static const Color neuLight = Color(0xFFFFFFFF);
  static const Color neuDark = Color(0xFFC2CDDC);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration neuRaised({
    double radius = 24.0,
    Color color = surface,
    Border? border,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: border ?? Border.all(color: Colors.white.withOpacity(0.8), width: 1.0),
      boxShadow: const [
        BoxShadow(
          color: neuDark,
          offset: Offset(6, 6),
          blurRadius: 14,
        ),
        BoxShadow(
          color: neuLight,
          offset: Offset(-6, -6),
          blurRadius: 14,
        ),
      ],
    );
  }

  static BoxDecoration neuSunken({
    double radius = 20.0,
    Color color = surfaceVariant,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.8),
      boxShadow: const [
        BoxShadow(
          color: neuDark,
          offset: Offset(2, 2),
          blurRadius: 5,
        ),
        BoxShadow(
          color: neuLight,
          offset: Offset(-2, -2),
          blurRadius: 5,
        ),
      ],
    );
  }

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: emergency,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: textSecondary,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Colors.white, width: 1.2),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.8), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.8), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
      ),
    );
  }
}
