import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryGold = Color(0xFFD4AF37); // Gold Accent
  static const Color backgroundBlack = Color(0xFF000000); // Navy Primary
  static const Color surfaceDark = Color(0xFF121212); // Navy Secondary
  static const Color textPrimary = Color(0xFFFFFFFF); // Text Primary
  static const Color textSecondary = Color(0xFF94A3B8); // Text Secondary
  static const Color successGreen = Color(0xFF22C55E); // Success
  static const Color errorRed = Color(0xFFEF4444); // Error

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryGold,
    scaffoldBackgroundColor: backgroundBlack,
    colorScheme: const ColorScheme.dark(
      primary: primaryGold,
      secondary: primaryGold,
      surface: surfaceDark,
      error: errorRed,
      onPrimary: Colors.black,
      onSurface: textPrimary,
    ),
    textTheme: GoogleFonts.outfitTextTheme(
      const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: textPrimary,
          letterSpacing: -1,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
          fontWeight: FontWeight.w400,
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundBlack,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGold,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size(double.infinity, 56),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryGold, width: 2),
      ),
      hintStyle: const TextStyle(color: textSecondary),
    ),
    cardTheme: const CardThemeData(
      color: surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: Colors.white10),
      ),
      elevation: 0,
    ),
  );
}
