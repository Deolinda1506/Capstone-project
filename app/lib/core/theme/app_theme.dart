import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CarotidCheck theme — Figma primary **#1F41BB** for buttons, app bars, links, logo.
class AppTheme {
  AppTheme._();

  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  /// Brand primary (Figma).
  static const Color primaryBlue = Color(0xFF1F41BB);
  /// Lighter same-hue blue for gradients / highlights (pairs with [primaryBlue]).
  static const Color primaryBlueLight = Color(0xFF4D64D9);
  static const Color accentTeal = Color(0xFF00695C);
  /// Secondary UI blue — tinted from [primaryBlue], not Material default blue.
  static const Color softBlue = Color(0xFF3553C5);
  static const Color riskHigh = Color(0xFFD32F2F);
  static const Color riskModerate = Color(0xFFF57C00);
  static const Color riskLow = Color(0xFF2E7D32);

  static const Color syncOffline = Color(0xFF9E9E9E);
  static const Color syncPending = Color(0xFFF57C00);
  static const Color syncSynced = Color(0xFF2E7D32);

  static ThemeData get lightTheme {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
    );
    final colorScheme = baseScheme.copyWith(
      primary: primaryBlue,
      onPrimary: Colors.white,
      secondary: accentTeal,
      onSecondary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      textTheme: GoogleFonts.dmSansTextTheme(),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryBlue),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.focused) ? primaryBlue : colorScheme.onSurfaceVariant,
          ),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    final darkScheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.dark,
      surface: const Color(0xFF121212),
    ).copyWith(
      primary: primaryBlue,
      onPrimary: Colors.white,
      secondary: accentTeal,
      onSecondary: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: darkScheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryBlueLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF2C2C2C),
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF252525),
      ),
    );
  }
}
