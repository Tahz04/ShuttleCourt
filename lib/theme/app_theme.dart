import 'package:flutter/material.dart';

/// ShuttleCourt Design System - Premium "Modern Slate" Light Theme
class AppTheme {
  // BRAND COLORS (Professional & Trustworthy)
  static const Color primary = Color(0xFF2D3250);        // Deep Slate/Indigo
  static const Color primaryDeep = Color(0xFF1B2038);      // Even deeper slate
  static const Color primaryLight = Color(0xFF424769);
  static const Color accent = Color(0xFF7077A1);         // Muted Blue
  static const Color highlight = Color(0xFFF6B17A);      // Warm Coral/Orange (Call to Action)
  static const Color glassmorphic = Color(0xCCFFFFFF);   // Glass effect

  // BACKGROUND COLORS (Sophisticated Light)
  static const Color scaffoldLight = Color(0xFFF8FAFC);  // Very light slate gray
  static const Color surfaceLight = Colors.white;
  static const Color cardLight = Colors.white;
  static const Color borderLight = Color(0xFFE2E8F0);    // Slate 200

  // TEXT COLORS
  static const Color textPrimary = Color(0xFF1E293B);    // Slate 900
  static const Color textSecondary = Color(0xFF64748B);  // Slate 500
  static const Color textMuted = Color(0xFF94A3B8);      // Slate 400

  // STATUS COLORS
  static const Color success = Color(0xFF10B981);       // Emerald 500
  static const Color warning = Color(0xFFF59E0B);       // Amber 500
  static const Color error = Color(0xFFEF4444);         // Rose 500

  // PREMIUM GRADIENTS
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2D3250), Color(0xFF424769)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF7077A1), Color(0xFF424769)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFF6B17A), Color(0xFFD68A5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // BORDER RADIUS
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 32.0;

  // SHADOWS (Soft & Airy)
  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  // THEME DATA
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surfaceLight,
        onSurface: textPrimary,
        error: error,
      ),
      fontFamily: 'Inter', // Professional sans-serif
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primary.withOpacity(0.2),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.1),
        ),
      ),
    );
  }

  // Compatibility helpers (Mapped to New Professional Light Theme)
  static const Color accentGold = warning;
  static const Color primaryDark = primary;
  static const Color scaffoldDark = scaffoldLight;
  static const Color surfaceDark = surfaceLight;
  static const Color cardDark = cardLight;
  static const Color borderDark = borderLight;
  static const LinearGradient heroGradient = primaryGradient;
  static const LinearGradient matchmakingGradient = accentGradient;
  static const LinearGradient ownerGradient = primaryGradient;
  static const LinearGradient matchGradient = accentGradient;
  
  static List<BoxShadow> glowShadowColor(Color color) => [
    BoxShadow(color: color.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 5))
  ];

  static ThemeData get darkTheme => lightTheme; // Maintaining Light UI as the "Professional" standard
  static const Color surfaceLightCard = Colors.white;
  static List<BoxShadow> get cardShadow => premiumShadow;
  static List<BoxShadow> get glowShadow => [
    BoxShadow(color: primary.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))
  ];
}
