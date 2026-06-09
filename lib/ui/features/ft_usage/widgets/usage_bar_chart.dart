import 'package:energy_tracker/theme/theme.dart';
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

  @override
  Widget build(BuildContext context) {
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
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
                child: Text(
                  'No readings yet',
                  style: AppTextStyles.bodySm,
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 80.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.asMap().entries.map((entry) {
                  final item = entry.value;
                  final isCurrentMonth = entry.key == data.length - 1;
                  final heightFraction = maxKwh > 0
                      ? (item.kwh <= 0
                          ? 0.0
                          : (item.kwh / maxKwh).clamp(0.05, 1.0))
                      : 0.0;
                  final isHighest = item.kwh == maxKwh && item.kwh > 0;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (item.kwh > 0)
                            Text(
                              item.kwh.toStringAsFixed(0),
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 9.sp,
                                color: isCurrentMonth
                                    ? AppColors.accent
                                    : AppColors.text3,
                              ),
                            ),
                          SizedBox(height: 2.h),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: heightFraction),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            builder: (context, value, _) {
                              return FractionallySizedBox(
                                heightFactor: value,
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: isCurrentMonth
                                        ? const LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              AppColors.accent,
                                              Color(0x6600D4AA),
                                            ],
                                          )
                                        : null,
                                    color: isCurrentMonth
                                        ? null
                                        : isHighest
                                            ? AppColors.accent3
                                                .withValues(alpha: 0.4)
                                            : AppColors.surface3,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                    boxShadow: isCurrentMonth
                                        ? [
                                            BoxShadow(
                                              color: AppColors.accent
                                                  .withValues(alpha: 0.3),
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
