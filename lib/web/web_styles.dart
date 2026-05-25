import 'package:flutter/material.dart';

/// WebStyles — single file CSS equivalent.
/// Change colors/sizes here → entire web UI updates.
class WebStyles {
  WebStyles._();

  // ── Layout ───────────────────────────────────────────────────────────────────
  static const double maxWidth = 1280.0;
  static const double navHeight = 68.0;

  // ── DARK PALETTE (PlayGroundX) ───────────────────────────────────────────────
  static const Color dark950  = Color(0xFF020617);
  static const Color dark900  = Color(0xFF0F172A);
  static const Color dark800  = Color(0xFF1E293B);
  static const Color dark700  = Color(0xFF334155);
  static const Color dark600  = Color(0xFF475569);
  static const Color dark500  = Color(0xFF64748B);
  static const Color dark400  = Color(0xFF94A3B8);
  static const Color dark300  = Color(0xFFCBD5E1);
  static const Color dark200  = Color(0xFFE2E8F0);
  static const Color dark100  = Color(0xFFF1F5F9);
  static const Color dark50   = Color(0xFFF8FAFC);

  // ── PRIMARY PALETTE — Emerald Green ─────────────────────────────────────────
  static const Color brand      = Color(0xFF059669); // Emerald 600
  static const Color brandDark  = Color(0xFF047857); // Emerald 700
  static const Color brandLight = Color(0xFF6EE7B7); // Emerald 300
  static const Color brandPale  = Color(0xFFD1FAE5); // Emerald 100

  static const Color cta        = Color(0xFFF59E0B); // Amber 500
  static const Color ctaDark    = Color(0xFFD97706); // Amber 600

  static const Color ink        = Color(0xFF111827); // Grey 900
  static const Color inkMid     = Color(0xFF374151); // Grey 700
  static const Color inkLight   = Color(0xFF6B7280); // Grey 500
  static const Color inkFaint   = Color(0xFF9CA3AF); // Grey 400

  static const Color surface    = Color(0xFFFFFFFF);
  static const Color bg         = Color(0xFFF9FAFB); // Grey 50
  static const Color bgTint     = Color(0xFFF0FDF4); // Emerald 50
  static const Color border     = Color(0xFFE5E7EB); // Grey 200
  static const Color borderMid  = Color(0xFFD1D5DB); // Grey 300

  // ── GRADIENTS ────────────────────────────────────────────────────────────────
  static const LinearGradient brandGrad = LinearGradient(
    colors: [brand, brandDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient ctaGrad = LinearGradient(
    colors: [cta, ctaDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroBg = LinearGradient(
    colors: [Color(0xFFF0FDF4), Color(0xFFECFDF5), Color(0xFFD1FAE5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBannerGrad = LinearGradient(
    colors: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF047857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navDarkGrad = LinearGradient(
    colors: [dark900, dark800],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroDarkGrad = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xEB0F172A), // dark900, 92%
      Color(0xA60F172A), // dark900, 65%
      Color(0x66059669), // brand, 40%
    ],
  );

  static const LinearGradient amberGrad = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient featureBg = LinearGradient(
    colors: [Color(0xFFF9FAFB), Color(0xFFF0FDF4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── RADII ────────────────────────────────────────────────────────────────────
  static const double rSm  = 6.0;
  static const double rMd  = 10.0;
  static const double rLg  = 16.0;
  static const double rXl  = 24.0;
  static const double rXxl = 32.0;

  // ── TYPOGRAPHY ───────────────────────────────────────────────────────────────
  static const TextStyle heroTitle = TextStyle(
    color: ink,
    fontSize: 60,
    fontWeight: FontWeight.w900,
    height: 1.04,
    letterSpacing: -2.5,
  );

  static const TextStyle heroTitleMobile = TextStyle(
    color: ink,
    fontSize: 38,
    fontWeight: FontWeight.w900,
    height: 1.08,
    letterSpacing: -1.2,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w900,
    color: ink,
    letterSpacing: -1.0,
    height: 1.15,
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    color: ink,
    letterSpacing: -0.4,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: ink,
    height: 1.25,
  );

  static const TextStyle heroSub = TextStyle(
    color: inkLight,
    fontSize: 17,
    height: 1.7,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle sectionSub = TextStyle(
    fontSize: 16,
    color: inkFaint,
    height: 1.6,
  );

  static const TextStyle pageSubtitle = TextStyle(
    fontSize: 13,
    color: inkFaint,
    height: 1.5,
  );

  static const TextStyle eyebrow = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: brand,
    letterSpacing: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: inkFaint,
    fontWeight: FontWeight.w500,
  );

  // ── SHADOWS ──────────────────────────────────────────────────────────────────
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 40,
          offset: const Offset(0, 16),
        ),
      ];

  static List<BoxShadow> brandShadow(double opacity) => [
        BoxShadow(
          color: brand.withValues(alpha: opacity),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  // ── BOX DECORATIONS ──────────────────────────────────────────────────────────
  static BoxDecoration get pageHeader => const BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: border)),
      );

  static BoxDecoration get card => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(rLg),
        border: Border.all(color: border),
        boxShadow: shadowSm,
      );

  static BoxDecoration cardActive(Color c) => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(rLg),
        border: Border.all(color: c.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      );

  static BoxDecoration filterPanel(bool isDesktop) => BoxDecoration(
        color: bg,
        border: Border(
          right: isDesktop ? const BorderSide(color: border) : BorderSide.none,
          bottom: !isDesktop ? const BorderSide(color: border) : BorderSide.none,
        ),
      );

  static BoxDecoration get inputBox => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(rMd),
        border: Border.all(color: border),
        boxShadow: shadowSm,
      );

  static BoxDecoration chip({required bool active, Color? color}) {
    final c = color ?? brand;
    return BoxDecoration(
      color: active ? c : surface,
      borderRadius: BorderRadius.circular(rSm),
      border: Border.all(color: active ? c : border),
    );
  }

  static BoxDecoration iconBox({Color? color, double r = 10}) {
    final c = color ?? brand;
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [c, Color.lerp(c, Colors.black, 0.15)!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(r),
    );
  }

  static BoxDecoration tintBox(Color c) => BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(rMd),
        border: Border.all(color: c.withValues(alpha: 0.18)),
      );

  static BoxDecoration pill(Color c) => BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      );

  // ── BUTTON STYLES ────────────────────────────────────────────────────────────
  static ButtonStyle primaryBtn({double h = 14, double v = 24, double r = 10}) =>
      ElevatedButton.styleFrom(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: v, vertical: h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      );

  static ButtonStyle ctaBtn({double h = 16, double v = 28, double r = 12}) =>
      ElevatedButton.styleFrom(
        backgroundColor: cta,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: v, vertical: h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      );

  static ButtonStyle ghostBtn({double h = 14, double v = 24, double r = 10}) =>
      OutlinedButton.styleFrom(
        foregroundColor: brand,
        side: const BorderSide(color: brand, width: 1.5),
        padding: EdgeInsets.symmetric(horizontal: v, vertical: h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      );
}
