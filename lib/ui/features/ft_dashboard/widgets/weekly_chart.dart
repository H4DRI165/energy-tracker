import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WeeklyChart extends StatelessWidget {
  const WeeklyChart({
    required this.weeklyUsage,
    super.key,
  });

  final List<DailyUsage> weeklyUsage;

  static const double _chartHeight = 60;
  static const double _labelHeight = 14;

  @override
  Widget build(BuildContext context) {
    final maxKwh = weeklyUsage.isEmpty
        ? 1.0
        : weeklyUsage.map((e) => e.kwh).reduce((a, b) => a > b ? a : b);
    const maxBarHeight = _chartHeight - _labelHeight;

    return Container(
      padding: EdgeInsets.all(AppDimensions.cardPaddingSm),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7-Day Usage',
                style:
                    AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
              ),
              Text('kWh/day', style: AppTextStyles.caption),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: _chartHeight,
            child: weeklyUsage.isEmpty
                ? Center(
                    child:
                        Text('No readings yet', style: AppTextStyles.caption),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: weeklyUsage.map((day) {
                      final heightFraction = maxKwh > 0
                          ? (day.kwh <= 0
                              ? 0.0
                              : (day.kwh / maxKwh).clamp(0.05, 1.0))
                          : 0.0;

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 3.w),
                          child: ChartBar(
                            heightFraction: heightFraction,
                            isHighlighted: day.isToday,
                            kwh: day.kwh,
                            maxBarHeight: maxBarHeight,
                            labelHeight: _labelHeight,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          SizedBox(height: 6.h),
          if (weeklyUsage.isNotEmpty)
            Row(
              children: weeklyUsage.map((day) {
                return Expanded(
                  child: Text(
                    day.label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10.sp,
                      color: day.isToday ? AppColors.accent : AppColors.text3,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
