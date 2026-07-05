import 'package:energy_tracker/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BarChartEntry {
  const BarChartEntry({
    required this.label,
    required this.kwh,
    this.isHighlighted = false,
  });

  final String label;
  final double kwh;
  final bool isHighlighted;
}

class UsageBarChartCard extends StatelessWidget {
  const UsageBarChartCard({
    required this.title,
    required this.subtitle,
    required this.entries,
    this.chartHeight = 110,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<BarChartEntry> entries;

  /// Override for compact usage
  final double chartHeight;

  static const double _valueLabelHeight = 16;

  @override
  Widget build(BuildContext context) {
    final maxKwh = entries.isEmpty
        ? 1.0
        : entries.map((e) => e.kwh).reduce((a, b) => a > b ? a : b);
    final maxBarHeight = chartHeight.h - _valueLabelHeight.h - 3.h;

    return Container(
      padding: EdgeInsets.all(AppDimensions.cardPaddingSm),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style:
                    AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (entries.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text(
                  'No readings yet',
                  style: AppTextStyles.bodySm,
                ),
              ),
            )
          else ...[
            SizedBox(
              height: chartHeight.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: entries.map((entry) {
                  final heightFraction = maxKwh > 0
                      ? (entry.kwh <= 0
                          ? 0.0
                          : (entry.kwh / maxKwh).clamp(0.05, 1.0))
                      : 0.0;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: _SlimBar(
                        heightFraction: heightFraction,
                        isHighlighted: entry.isHighlighted,
                        kwh: entry.kwh,
                        maxBarHeight: maxBarHeight,
                        valueLabelHeight: _valueLabelHeight.h,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              children: entries.map((entry) {
                return Expanded(
                  child: Text(
                    entry.label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10.sp,
                      color: entry.isHighlighted
                          ? AppColors.accent
                          : AppColors.text3,
                      fontWeight: entry.isHighlighted
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SlimBar extends StatelessWidget {
  const _SlimBar({
    required this.heightFraction,
    required this.isHighlighted,
    required this.kwh,
    required this.maxBarHeight,
    required this.valueLabelHeight,
  });

  final double heightFraction;
  final bool isHighlighted;
  final double kwh;
  final double maxBarHeight;
  final double valueLabelHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: valueLabelHeight,
          child: kwh > 0
              ? Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    kwh.toStringAsFixed(0),
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 9.sp,
                      color: isHighlighted ? AppColors.accent : AppColors.text3,
                      fontWeight:
                          isHighlighted ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        SizedBox(height: 3.h),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: heightFraction),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutQuart,
          builder: (context, value, _) {
            return SizedBox(
              height: maxBarHeight * value,
              child: Container(
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? AppColors.accent
                      : AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
