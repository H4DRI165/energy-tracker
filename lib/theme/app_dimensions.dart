import 'package:flutter_screenutil/flutter_screenutil.dart';

abstract class AppDimensions {
  // ─── Spacing scale ─────────────────────────────────────────────────────────
  static double get s2 => 2.r;
  static double get s4 => 4.r;
  static double get s6 => 6.r;
  static double get s8 => 8.r;
  static double get s10 => 10.r;
  static double get s12 => 12.r;
  static double get s14 => 14.r;
  static double get s16 => 16.r;
  static double get s20 => 20.r;
  static double get s24 => 24.r;
  static double get s28 => 28.r;
  static double get s32 => 32.r;
  static double get s40 => 40.r;
  static double get s48 => 48.r;

  // ─── Border radius ─────────────────────────────────────────────────────────
  static double get radiusLg => 20.r;
  static double get radiusMd => 12.r;
  static double get radiusPill => 20.r;
  static double get radiusXl => 36.r;
  static double get radiusSm => 10.r;

  // ─── Component sizes ───────────────────────────────────────────────────────
  static double get iconBtnSize => 36.r;
  static double get avatarSize => 32.r;
  static double get navFabSize => 48.r;
  static double get applianceIconSize => 40.r;
  static double get onboardIconSize => 72.r;
  static double get toggleWidth => 44.r;
  static double get toggleHeight => 24.r;

  // ─── Layout ────────────────────────────────────────────────────────────────
  static double get screenPaddingH => 20.w;
  static double get screenPaddingV => 16.h;
  static double get cardPaddingDefault => 18.r;
  static double get cardPaddingSm => 14.r;
  static double get bottomNavHeight => 64.h;
  static double get progressBarHeight => 6.r;
  static double get progressBarHeightLg => 8.r;
  static double get dividerHeight => 1.r;

  // ─── Border widths ─────────────────────────────────────────────────────────
  static double get borderWidth => 1.r;
  static double get borderWidthAccent => 2.r;
  static double get borderWidthScan => 3.r;
}
