import 'package:energy_tracker/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChartBar extends StatelessWidget {
  const ChartBar({
    required this.heightFraction,
    required this.isHighlighted,
    required this.kwh,
    required this.maxBarHeight,
    required this.labelHeight,
    this.highlightGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.accent, Color(0x6600D4AA)],
    ),
    this.defaultColor = AppColors.surface3,
    this.highlightShadowColor = AppColors.accent,
    super.key,
  });

  final double heightFraction;
  final bool isHighlighted;
  final double kwh;
  final double maxBarHeight;
  final double labelHeight;
  final LinearGradient highlightGradient;
  final Color defaultColor;
  final Color highlightShadowColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: labelHeight,
          child: kwh > 0
              ? Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    kwh.toStringAsFixed(0),
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 9.sp,
                      color: isHighlighted ? AppColors.accent : AppColors.text3,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: heightFraction),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder: (context, value, _) {
            return SizedBox(
              height: maxBarHeight * value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: isHighlighted ? highlightGradient : null,
                  color: isHighlighted ? null : defaultColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                  boxShadow: isHighlighted
                      ? [
                          BoxShadow(
                            color: highlightShadowColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
