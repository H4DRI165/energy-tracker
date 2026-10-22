import 'package:energy_tracker/theme/theme.dart';
import 'package:flutter/widgets.dart';

abstract final class AppContentWidth {
  static const double standard = 900;

  /// Horizontal padding that keeps content readable on tablets while
  /// preserving the normal mobile margins.
  static double horizontalPadding(
    BuildContext context, {
    double maxWidth = standard,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final basePadding = AppDimensions.screenPaddingH;

    if (screenWidth <= maxWidth + (basePadding * 2)) {
      return basePadding;
    }
    return (screenWidth - maxWidth) / 2;
  }
}
