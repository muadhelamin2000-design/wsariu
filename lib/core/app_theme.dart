import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentGold = Color(0xFFC8A96A);
  static const Color lightBg = Color(0xFFF5F5F5);
  
  static const Color darkBg = Color(0xFF0D1B2A);
  static const Color darkPrimary = Color(0xFF14CFBA);
  static const Color darkAccent = Color(0xFFD4AF37);
  static const Color darkCard = Color(0xFF1E2A38);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: lightBg,
      fontFamily: 'NotoKufiArabic',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: accentGold,
        surface: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Amiri',
          color: primaryGreen,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: primaryGreen),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: darkBg,
      fontFamily: 'NotoKufiArabic',
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkPrimary,
        brightness: Brightness.dark,
        primary: darkPrimary,
        secondary: darkAccent,
        surface: darkCard,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Amiri',
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static const List<Color> expandedColors = [
    Color(0xFF2E7D32), Color(0xFFC8A96A), Color(0xFF1565C0), Color(0xFFC62828), Color(0xFF6A1B9A),
    Color(0xFFEF6C00), Color(0xFF00838F), Color(0xFF4E342E), Color(0xFF37474F), Color(0xFFAD1457),
    Color(0xFF283593), Color(0xFF558B2F), Color(0xFFF9A825), Color(0xFF607D8B), Color(0xFFFF8A65),
    Color(0xFF4DB6AC), Color(0xFF9CCC65), Color(0xFF7986CB), Color(0xFF90A4AE), Color(0xFF000000),
    Color(0xFFD32F2F), Color(0xFFC2185B), Color(0xFF7B1FA2), Color(0xFF512DA8), Color(0xFF303F9F),
    Color(0xFF1976D2), Color(0xFF0288D1), Color(0xFF0097A7), Color(0xFF00796B), Color(0xFF388E3C),
  ];
}