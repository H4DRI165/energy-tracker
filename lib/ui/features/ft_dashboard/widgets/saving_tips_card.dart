import 'package:energy_tracker/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SavingTipsCard extends StatelessWidget {
  const SavingTipsCard({super.key});

  static const _tips = [
    ('❄️', 'Set AC to 25°C saves ~15% energy'),
    ('💡', 'Switch off standby devices at night'),
    ('🌊', 'Wash clothes in cold water when possible'),
    ('🌞', 'Use natural light during the day'),
  ];

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
          Text(
            '💡 Quick Saving Tips',
            style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 10.h),
          ...(_tips.take(2).map(
                (tip) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    children: [
                      Container(
                        width: 28.r,
                        height: 28.r,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            tip.$1,
                            style: TextStyle(fontSize: 13.sp),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(tip.$2, style: AppTextStyles.bodySm),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
