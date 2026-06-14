import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/components/chart.dart';
import 'package:energy_tracker/ui/features/ft_usage/notifier/usage_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UsageBarChart extends StatelessWidget {
  const UsageBarChart({
    required this.data,
    required this.maxKwh,
    super.key,
  });

  final List<MonthlyUsage> data;
  final double maxKwh;

  static const double _chartHeight = 80;
  static const double _labelHeight = 14;

  @override
  Widget build(BuildContext context) {
    final maxBarHeight = _chartHeight.h - _labelHeight.h;

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
                'kWh Usage',
                style:
                    AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text('kWh', style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (data.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text('No readings yet', style: AppTextStyles.bodySm),
              ),
            )
          else ...[
            SizedBox(
              height: _chartHeight.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.asMap().entries.map((entry) {
                  final item = entry.value;
                  final isCurrentMonth = entry.key == data.length - 1;
                  final isHighest = item.kwh == maxKwh && item.kwh > 0;
                  final heightFraction = maxKwh > 0
                      ? (item.kwh <= 0
                          ? 0.0
                          : (item.kwh / maxKwh).clamp(0.05, 1.0))
                      : 0.0;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3.w),
                      child: ChartBar(
                        heightFraction: heightFraction,
                        isHighlighted: isCurrentMonth,
                        kwh: item.kwh,
                        maxBarHeight: maxBarHeight,
                        labelHeight: _labelHeight.h,
                        defaultColor: isHighest
                            ? AppColors.accent3.withValues(alpha: 0.4)
                            : AppColors.surface3,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              children: data.asMap().entries.map((entry) {
                final item = entry.value;
                final isCurrentMonth = entry.key == data.length - 1;
                return Expanded(
                  child: Text(
                    item.month,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10.sp,
                      color:
                          isCurrentMonth ? AppColors.accent : AppColors.text3,
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
