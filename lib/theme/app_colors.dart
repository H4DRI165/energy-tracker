import 'package:flutter/material.dart';

abstract class AppColors {
  // ─── Backgrounds ───────────────────────────────────────────────────────────
  /// True page background: #060912
  static const Color bgDeep = Color(0xFF060912);

  /// Primary surface (cards, nav): #0A0E1A
  static const Color bg = Color(0xFF0A0E1A);

  /// Elevated surface (card base): #111827
  static const Color surface = Color(0xFF111827);

  /// Medium surface (inputs, chips): #1A2235
  static const Color surface2 = Color(0xFF1A2235);

  /// High surface (bars, skeleton): #1F2D42
  static const Color surface3 = Color(0xFF1F2D42);

  // ─── Borders ───────────────────────────────────────────────────────────────
  /// Default border: rgba(255,255,255,0.07)
  static const Color border = Color(0x12FFFFFF);

  /// Accent border (teal tint): rgba(0,212,170,0.20)
  static const Color borderAccent = Color(0x3300D4AA);

  /// Warning border: rgba(255,176,32,0.30)
  static const Color borderWarn = Color(0x4DFFB020);

  /// Danger border: rgba(255,77,106,0.15)
  static const Color borderDanger = Color(0x26FF4D6A);

  // ─── Brand Accents ─────────────────────────────────────────────────────────
  /// Primary teal: #00D4AA
  static const Color accent = Color(0xFF00D4AA);

  /// Secondary blue: #0099FF
  static const Color accent2 = Color(0xFF0099FF);

  /// Tertiary orange: #FF6B35
  static const Color accent3 = Color(0xFFFF6B35);

  // ─── Semantic ──────────────────────────────────────────────────────────────
  /// Warning amber: #FFB020
  static const Color warn = Color(0xFFFFB020);

  /// Danger red-pink: #FF4D6A
  static const Color danger = Color(0xFFFF4D6A);

  // ─── Text ──────────────────────────────────────────────────────────────────
  /// Primary text: #F0F4FF
  static const Color text = Color(0xFFF0F4FF);

  /// Secondary / muted text: #8899BB
  static const Color text2 = Color(0xFF8899BB);

  /// Tertiary / disabled text: #4A5C7A
  static const Color text3 = Color(0xFF4A5C7A);

  // ─── Gradients ─────────────────────────────────────────────────────────────
  /// Primary CTA gradient (teal → blue)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accent2],
  );

  /// Hero card gradient (dark teal)
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D2D24), Color(0xFF0A1E2E)],
  );

  /// Alert / warn card gradient
  static const LinearGradient warnGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D1A0A), Color(0xFF1E1A0A)],
  );

  /// Splash radial base
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF060912), Color(0xFF0D1A2E)],
  );

  /// Progress bar — normal
  static const LinearGradient progressNormal = LinearGradient(
    colors: [accent, accent2],
  );

  /// Progress bar — warning
  static const LinearGradient progressWarn = LinearGradient(
    colors: [warn, accent3],
  );

  /// Progress bar — danger
  static const LinearGradient progressDanger = LinearGradient(
    colors: [danger, Color(0xFFFF9A00)],
  );

  // ─── Tag / Badge fills (low-opacity tints) ─────────────────────────────────
  static const Color tagGreenBg = Color(0x1F00D4AA); // 12%
  static const Color tagBlueBg = Color(0x1F0099FF);
  static const Color tagWarnBg = Color(0x1FFFB020);
  static const Color tagDangerBg = Color(0x1FFF4D6A);
  static const Color tagOrangeBg = Color(0x1FFF6B35);

  // ─── Glow / shadows ────────────────────────────────────────────────────────
  static List<BoxShadow> get cardGlow => [
        BoxShadow(
          color: accent.withValues(alpha: 0.08),
          blurRadius: 40,
        ),
      ];

  static List<BoxShadow> get navFabShadow => [
        BoxShadow(
          color: accent.withValues(alpha: 0.40),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get btnPrimaryShadow => [
        BoxShadow(
          color: accent.withValues(alpha: 0.30),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get cardElevated => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.60),
          blurRadius: 80,
          offset: const Offset(0, 24),
        ),
        ...cardGlow,
      ];
}
