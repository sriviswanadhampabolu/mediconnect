import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Soft Neumorphic Brand Palette (Matching GitHub site docs/styles.css)
  static const Color primary = Color(0xFF2563EB); // Vibrant Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFDBEAFE);
  
  static const Color secondary = Color(0xFF4F46E5); // Indigo
  static const Color secondaryDark = Color(0xFF3730A3);
  static const Color secondaryLight = Color(0xFFEEF2FF);

  static const Color emergency = Color(0xFFDC2626); // Red
  static const Color emergencyLight = Color(0xFFFEE2E2);

  static const Color warning = Color(0xFFD97706); // Amber
  static const Color warningLight = Color(0xFFFEF3C7);

  static const Color success = Color(0xFF059669); // Emerald Green
  static const Color successLight = Color(0xFFD1FAE5);

  // Exact Neumorphic Background & Surface Tones from docs/styles.css (--neu-bg: #e6ecf8)
  static const Color background = Color(0xFFE6ECF8);
  static const Color neuBackground = Color(0xFFE6ECF8);
  static const Color surface = Color(0xFFE6ECF8);
  static const Color surfaceVariant = Color(0xFFEDF2FB);
  static const Color neuWhite = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  static const Color border = Color(0xFFD8E2EE);

  // Dual Shadows for Neumorphic Depth (--neu-dark-shadow: #c5d0e2, --neu-light-shadow: #ffffff)
  static const Color neuLight = Color(0xFFFFFFFF);
  static const Color neuDark = Color(0xFFC5D0E2);
  static const Color neuDarker = Color(0xFFB3C2D8);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    colors: [Color(0xFFF87171), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Extruded Raised Surface (Raised neumorphic card / button)
  static BoxDecoration neuRaised({
    double radius = 22.0,
    Color color = surface,
    Border? border,
    bool hover = false,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: border ?? Border.all(color: Colors.white.withOpacity(0.85), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: hover ? neuDarker : neuDark,
          offset: hover ? const Offset(8, 8) : const Offset(6, 6),
          blurRadius: hover ? 18 : 14,
        ),
        BoxShadow(
          color: neuLight,
          offset: hover ? const Offset(-8, -8) : const Offset(-6, -6),
          blurRadius: hover ? 18 : 14,
        ),
      ],
    );
  }

  /// Debossed / Sunken Surface (Recessed input / active button)
  static BoxDecoration neuSunken({
    double radius = 18.0,
    Color color = surfaceVariant,
    Border? border,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: border ?? Border.all(color: Colors.white.withOpacity(0.55), width: 1.0),
      boxShadow: const [
        BoxShadow(
          color: neuDark,
          offset: Offset(3, 3),
          blurRadius: 6,
        ),
        BoxShadow(
          color: neuLight,
          offset: Offset(-3, -3),
          blurRadius: 6,
        ),
      ],
    );
  }

  /// Tactile Squircle Navigation Button (58x58 with rounded corners)
  static BoxDecoration neuSquircle({
    bool active = false,
    bool isEmergency = false,
    double radius = 18.0,
  }) {
    if (active) {
      return BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isEmergency ? emergency.withOpacity(0.5) : primary.withOpacity(0.4),
          width: 1.5,
        ),
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

    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.85), width: 1.2),
      boxShadow: [
        if (isEmergency)
          BoxShadow(
            color: emergency.withOpacity(0.22),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        const BoxShadow(
          color: neuDark,
          offset: Offset(5, 5),
          blurRadius: 10,
        ),
        const BoxShadow(
          color: neuLight,
          offset: Offset(-5, -5),
          blurRadius: 10,
        ),
      ],
    );
  }

  /// Tactile Pill Button
  static BoxDecoration neuPill({
    bool active = false,
    Color? activeColor,
    Color? borderColor,
  }) {
    final baseActiveColor = activeColor ?? primary;
    if (active) {
      return BoxDecoration(
        color: baseActiveColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: baseActiveColor, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: neuDark,
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: neuLight,
            offset: Offset(-2, -2),
            blurRadius: 4,
          ),
        ],
      );
    }

    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: borderColor ?? Colors.white.withOpacity(0.85), width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: neuDark,
          offset: Offset(4, 4),
          blurRadius: 8,
        ),
        BoxShadow(
          color: neuLight,
          offset: Offset(-4, -4),
          blurRadius: 8,
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
          fontSize: 15,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: textSecondary,
          fontSize: 13.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 18,
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
          borderSide: BorderSide(color: Colors.white.withOpacity(0.85), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.85), width: 1.2),
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
