import 'package:flutter/material.dart';

/// Palette used by the app. Widgets read colors through [AppColors] so the
/// whole UI can switch palettes without threading a Theme through every file.
class AppPalette {
  const AppPalette({
    required this.isDark,
    required this.bgDeep,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.border,
    required this.borderAccent,
    required this.borderWarn,
    required this.borderDanger,
    required this.accent,
    required this.accent2,
    required this.accent3,
    required this.warn,
    required this.danger,
    required this.onAccent,
    required this.text,
    required this.text2,
    required this.text3,
    required this.primaryGradient,
    required this.heroGradient,
    required this.warnGradient,
    required this.splashGradient,
    required this.progressNormal,
    required this.progressWarn,
    required this.progressDanger,
    required this.tagGreenBg,
    required this.tagBlueBg,
    required this.tagWarnBg,
    required this.tagDangerBg,
    required this.tagOrangeBg,
  });

  final bool isDark;
  final Color bgDeep;
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color border;
  final Color borderAccent;
  final Color borderWarn;
  final Color borderDanger;
  final Color accent;
  final Color accent2;
  final Color accent3;
  final Color warn;
  final Color danger;
  final Color onAccent;
  final Color text;
  final Color text2;
  final Color text3;
  final LinearGradient primaryGradient;
  final LinearGradient heroGradient;
  final LinearGradient warnGradient;
  final LinearGradient splashGradient;
  final LinearGradient progressNormal;
  final LinearGradient progressWarn;
  final LinearGradient progressDanger;
  final Color tagGreenBg;
  final Color tagBlueBg;
  final Color tagWarnBg;
  final Color tagDangerBg;
  final Color tagOrangeBg;

  static const AppPalette dark = AppPalette(
    isDark: true,
    bgDeep: Color(0xFF060912),
    bg: Color(0xFF0A0E1A),
    surface: Color(0xFF111827),
    surface2: Color(0xFF1A2235),
    surface3: Color(0xFF1F2D42),
    border: Color(0x12FFFFFF),
    borderAccent: Color(0x3300D4AA),
    borderWarn: Color(0x4DFFB020),
    borderDanger: Color(0x26FF5C76),
    accent: Color(0xFF00D4AA),
    accent2: Color(0xFF0099FF),
    accent3: Color(0xFFFF6B35),
    warn: Color(0xFFFFB020),
    danger: Color(0xFFFF5C76),
    onAccent: Colors.black,
    text: Color(0xFFF0F4FF),
    text2: Color(0xFF8899BB),
    text3: Color(0xFF8595B8),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF00D4AA), Color(0xFF0099FF)],
    ),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0D2D24), Color(0xFF0A1E2E)],
    ),
    warnGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2D1A0A), Color(0xFF1E1A0A)],
    ),
    splashGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF060912), Color(0xFF0D1A2E)],
    ),
    progressNormal: LinearGradient(
      colors: [Color(0xFF00D4AA), Color(0xFF0099FF)],
    ),
    progressWarn: LinearGradient(
      colors: [Color(0xFFFFB020), Color(0xFFFF6B35)],
    ),
    progressDanger: LinearGradient(
      colors: [Color(0xFFFF5C76), Color(0xFFFF9A00)],
    ),
    tagGreenBg: Color(0x1F00D4AA),
    tagBlueBg: Color(0x1F0099FF),
    tagWarnBg: Color(0x1FFFB020),
    tagDangerBg: Color(0x1FFF5C76),
    tagOrangeBg: Color(0x1FFF6B35),
  );

  static const AppPalette light = AppPalette(
    isDark: false,
    bgDeep: Color(0xFFE6EEF8),
    bg: Color(0xFFF3F7FC),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFE1ECF7),
    surface3: Color(0xFFD8E4F2),
    border: Color(0xFFB9CCDF),
    borderAccent: Color(0xFF99D9CB),
    borderWarn: Color(0xFFEBC98A),
    borderDanger: Color(0xFFE9A8B4),
    accent: Color(0xFF00705C),
    accent2: Color(0xFF005FB8),
    accent3: Color(0xFFA33F06),
    warn: Color(0xFF955400),
    danger: Color(0xFFB4233C),
    onAccent: Colors.white,
    text: Color(0xFF0F1B2D),
    text2: Color(0xFF44546A),
    text3: Color(0xFF56667B),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF00705C), Color(0xFF005FB8)],
    ),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE6F7F2), Color(0xFFE8F1FB)],
    ),
    warnGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF4E5), Color(0xFFFFF9EE)],
    ),
    splashGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF5F8FC), Color(0xFFE8F1FB)],
    ),
    progressNormal: LinearGradient(
      colors: [Color(0xFF00705C), Color(0xFF005FB8)],
    ),
    progressWarn: LinearGradient(
      colors: [Color(0xFF955400), Color(0xFFA33F06)],
    ),
    progressDanger: LinearGradient(
      colors: [Color(0xFFB4233C), Color(0xFFA33F06)],
    ),
    tagGreenBg: Color(0x1A00705C),
    tagBlueBg: Color(0x1A005FB8),
    tagWarnBg: Color(0x1A955400),
    tagDangerBg: Color(0x1AB4233C),
    tagOrangeBg: Color(0x1AA33F06),
  );
}

abstract class AppColors {
  static AppPalette _palette = AppPalette.light;

  static AppPalette get palette => _palette;

  static bool get isDark => _palette.isDark;

  /// Called once per app build before widgets read [AppColors].
  static void setDark({required bool value}) {
    _palette = value ? AppPalette.dark : AppPalette.light;
  }

  static Color get bgDeep => _palette.bgDeep;
  static Color get bg => _palette.bg;
  static Color get surface => _palette.surface;
  static Color get surface2 => _palette.surface2;
  static Color get surface3 => _palette.surface3;

  static Color get border => _palette.border;
  static Color get borderAccent => _palette.borderAccent;
  static Color get borderWarn => _palette.borderWarn;
  static Color get borderDanger => _palette.borderDanger;

  static Color get accent => _palette.accent;
  static Color get accent2 => _palette.accent2;
  static Color get accent3 => _palette.accent3;
  static Color get warn => _palette.warn;
  static Color get danger => _palette.danger;
  static Color get onAccent => _palette.onAccent;

  static Color get text => _palette.text;
  static Color get text2 => _palette.text2;
  static Color get text3 => _palette.text3;

  static LinearGradient get primaryGradient => _palette.primaryGradient;
  static LinearGradient get heroGradient => _palette.heroGradient;
  static LinearGradient get warnGradient => _palette.warnGradient;
  static LinearGradient get splashGradient => _palette.splashGradient;
  static LinearGradient get progressNormal => _palette.progressNormal;
  static LinearGradient get progressWarn => _palette.progressWarn;
  static LinearGradient get progressDanger => _palette.progressDanger;

  static Color get tagGreenBg => _palette.tagGreenBg;
  static Color get tagBlueBg => _palette.tagBlueBg;
  static Color get tagWarnBg => _palette.tagWarnBg;
  static Color get tagDangerBg => _palette.tagDangerBg;
  static Color get tagOrangeBg => _palette.tagOrangeBg;

  static List<BoxShadow> get cardGlow => [
    BoxShadow(
      color: accent.withValues(alpha: isDark ? 0.08 : 0.10),
      blurRadius: 40,
    ),
  ];

  static List<BoxShadow> get navFabShadow => [
    BoxShadow(
      color: accent.withValues(alpha: isDark ? 0.40 : 0.24),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get btnPrimaryShadow => [
    BoxShadow(
      color: accent.withValues(alpha: isDark ? 0.30 : 0.20),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get cardElevated => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.60 : 0.12),
      blurRadius: 80,
      offset: const Offset(0, 24),
    ),
    ...cardGlow,
  ];
}
