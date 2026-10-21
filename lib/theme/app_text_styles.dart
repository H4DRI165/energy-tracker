import 'package:energy_tracker/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTextStyles {

  static TextStyle get displayXl => GoogleFonts.lato(
    fontSize: 40.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
    height: 1,
  );

  static TextStyle get displayLg => GoogleFonts.lato(
    fontSize: 36.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
    height: 1,
  );

  static TextStyle get displayMd => GoogleFonts.lato(
    fontSize: 26.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
    height: 1.1,
  );

  static TextStyle get titleLg => GoogleFonts.lato(
    fontSize: 22.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    height: 1.2,
  );

  static TextStyle get titleMd => GoogleFonts.lato(
    fontSize: 18.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    height: 1.2,
  );

  static TextStyle get overline => GoogleFonts.lato(
    fontSize: 11.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.accent,
    letterSpacing: 3,
    height: 1,
  ).copyWith(decoration: TextDecoration.none);

  static TextStyle get navLabel => GoogleFonts.lato(
    fontSize: 9.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.text3,
    letterSpacing: 0.5,
    height: 1,
  );


  static TextStyle get bodyLg => GoogleFonts.dmSans(
    fontSize: 15.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    height: 1.5,
  );

  static TextStyle get bodyMd => GoogleFonts.dmSans(
    fontSize: 13.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    height: 1.5,
  );

  static TextStyle get bodySm => GoogleFonts.dmSans(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.text2,
    height: 1.4,
  );

  static TextStyle get caption => GoogleFonts.dmSans(
    fontSize: 11.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.text2,
    height: 1.3,
  );

  static TextStyle get label => GoogleFonts.dmSans(
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.text2,
    letterSpacing: 0.5,
    height: 1,
  );

  static TextStyle get button => GoogleFonts.lato(
    fontSize: 15.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.onAccent,
    letterSpacing: 0.5,
    height: 1,
  );

  static TextStyle get tag => GoogleFonts.dmSans(
    fontSize: 11.sp,
    fontWeight: FontWeight.w600,
    height: 1,
  );


  static TextStyle get meterXl => GoogleFonts.lato(
    fontSize: 44.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.accent,
    letterSpacing: 4,
    height: 1,
  );

  static TextStyle get statMd => GoogleFonts.lato(
    fontSize: 20.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    height: 1,
  );

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
