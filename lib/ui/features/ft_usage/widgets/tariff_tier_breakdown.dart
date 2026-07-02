import 'package:energy_tracker/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TariffTierBreakdown extends StatelessWidget {
  const TariffTierBreakdown({
    required this.monthLabel,
    required this.tariffType,
    this.domesticItems,
    this.commercialTiers,
    super.key,
  });

  final String monthLabel;
  final TariffType tariffType;
  final List<ChargeLineItem>? domesticItems;
  final List<TierBreakdown>? commercialTiers;

  bool get isEmpty => tariffType == TariffType.domestic
      ? (domesticItems?.isEmpty ?? true)
      : (commercialTiers?.isEmpty ?? true);

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
            'Bill Breakdown',
            style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12.h),
          if (isEmpty)
            Text(
              'No usage data for $monthLabel',
              style: AppTextStyles.bodySm,
            )
          else if (tariffType == TariffType.domestic)
            ...domesticItems!.map((item) => DomesticLineItem(item: item))
          else
            ..._buildCommercialTiers(),
          if (tariffType == TariffType.domestic) ...[
            Divider(height: 16.h, color: AppColors.border),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 11.r,
                  color: AppColors.text3,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    'Excludes AFA — a monthly fuel adjustment published '
                    'by TNB. Currently 0–2.59 sen/kWh depending on usage.',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.text3),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildCommercialTiers() {
    return commercialTiers!
        .map(
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
                        valueColor: AlwaysStoppedAnimation<Color>(tier.color),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}
