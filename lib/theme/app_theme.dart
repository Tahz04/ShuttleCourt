import 'package:flutter/material.dart';

/// ShuttleCourt Design System - Premium Light Theme
class AppTheme {
  // BRAND COLORS
  static const Color primary = Color(0xFF00C853);        // Vibrant Green
  static const Color primaryDark = Color(0xFF009624);     // Deep Green
  static const Color accent = Color(0xFF007BFF);          // Blue Accent
  static const Color accentGold = Color(0xFFFFB300);      // Gold

  // BACKGROUND COLORS (Light Mode)
  static const Color scaffoldLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Colors.white;
  static const Color cardLight = Colors.white;

  // TEXT COLORS
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textMuted = Color(0xFF9E9E9E);

  // STATUS COLORS
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);

  // GRADIENTS
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF64DD17)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF009624)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient matchmakingGradient = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient ownerGradient = LinearGradient(
    colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // BORDER RADIUS
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  // SHADOWS
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: primary.withOpacity(0.2),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];

  static List<BoxShadow> glowShadowColor(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.15),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];

  // THEME DATA
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldLight,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surfaceLight,
        error: error,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // To maintain compatibility with existing code during transition
  static Color get scaffoldDark => scaffoldLight;
  static Color get surfaceDark => surfaceLight;
  static Color get cardDark => cardLight;
  static ThemeData get darkTheme => lightTheme; 
}
