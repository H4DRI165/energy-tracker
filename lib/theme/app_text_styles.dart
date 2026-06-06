import 'package:energy_tracker/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Display / headings → Lato (weight 700–800)
/// Body / UI           → DM Sans (weight 300–600)
abstract class AppTextStyles {
  // ─── Display (Lato) ────────────────────────────────────────────────────────

  /// App name / hero number — Lato 800, 40px
  static TextStyle get displayXl => GoogleFonts.lato(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
        height: 1,
      );

  /// Section hero number — Lato 800, 36px
  static TextStyle get displayLg => GoogleFonts.lato(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
        height: 1,
      );

  /// Card headline — Lato 800, 26px
  static TextStyle get displayMd => GoogleFonts.lato(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
        height: 1.1,
      );

  /// Screen title / nav — Lato 700, 22px
  static TextStyle get titleLg => GoogleFonts.lato(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
        height: 1.2,
      );

  /// Card title — Lato 700, 18px
  static TextStyle get titleMd => GoogleFonts.lato(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
        height: 1.2,
      );

  /// Section label / overline — Lato 700, 11px, 3px spacing, UPPERCASE
  static TextStyle get overline => GoogleFonts.lato(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.accent,
        letterSpacing: 3,
        height: 1,
      ).copyWith(decoration: TextDecoration.none);

  /// Nav label overline — Lato 600, 9px
  static TextStyle get navLabel => GoogleFonts.lato(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: AppColors.text3,
        letterSpacing: 0.5,
        height: 1,
      );

  // ─── Body (DM Sans) ────────────────────────────────────────────────────────

  /// Body large — DM Sans 400, 15px
  static TextStyle get bodyLg => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.text,
        height: 1.5,
      );

  /// Body default — DM Sans 400, 13px
  static TextStyle get bodyMd => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.text,
        height: 1.5,
      );

  /// Body small — DM Sans 400, 12px
  static TextStyle get bodySm => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.text2,
        height: 1.4,
      );

  /// Caption / meta — DM Sans 400, 11px
  static TextStyle get caption => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.text2,
        height: 1.3,
      );

  /// Label (input labels, section keys) — DM Sans 600, 12px
  static TextStyle get label => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.text2,
        letterSpacing: 0.5,
        height: 1,
      );

  /// Button text — Lato 700, 15px, 0.5px spacing
  static TextStyle get button => GoogleFonts.lato(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.black,
        letterSpacing: 0.5,
        height: 1,
      );

  /// Tag / badge text — DM Sans 600, 11px
  static TextStyle get tag => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1,
      );

  // ─── Numeric display (Lato — for meter readings, RM amounts) ───────────────

  /// Large kWh / RM reading — Lato 800, 44px
  static TextStyle get meterXl => GoogleFonts.lato(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        color: AppColors.accent,
        letterSpacing: 4,
        height: 1,
      );

  /// Medium stat number — Lato 700, 20px
  static TextStyle get statMd => GoogleFonts.lato(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
        height: 1,
      );

  // ─── Muted / variant helpers ───────────────────────────────────────────────

  static TextStyle muted(TextStyle base) =>
      base.copyWith(color: AppColors.text2);

  static TextStyle accent(TextStyle base) =>
      base.copyWith(color: AppColors.accent);

  static TextStyle warn(TextStyle base) => base.copyWith(color: AppColors.warn);

  static TextStyle danger(TextStyle base) =>
      base.copyWith(color: AppColors.danger);

  static TextStyle colored(TextStyle base, Color color) =>
      base.copyWith(color: color);
}
