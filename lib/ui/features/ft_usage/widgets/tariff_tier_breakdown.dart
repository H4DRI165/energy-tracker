import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/features/ft_usage/notifier/usage_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TariffTierBreakdown extends StatelessWidget {
  const TariffTierBreakdown({
    required this.tiers,
    required this.monthLabel,
    super.key,
  });

  final List<TierBreakdown> tiers;
  final String monthLabel;

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
            'Tariff Tier Breakdown',
            style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12.h),
          if (tiers.isEmpty)
            Text(
              'No usage data for $monthLabel',
              style: AppTextStyles.bodySm,
            )
          else
            ...tiers.map(
              (tier) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tier.label, style: AppTextStyles.caption),
                        Text(
                          'RM ${tier.amount.toStringAsFixed(2)}',
                          style: AppTextStyles.bodySm.copyWith(
                            color: tier.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3.r),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: tier.fillPercent),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        builder: (context, value, _) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 6.h,
                            backgroundColor: AppColors.surface3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(tier.color),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
