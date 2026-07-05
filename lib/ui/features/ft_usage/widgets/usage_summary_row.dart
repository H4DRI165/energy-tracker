import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:energy_tracker/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UsageSummaryRow extends StatelessWidget {
  const UsageSummaryRow({
    required this.kwh,
    required this.bill,
    required this.monthLabel,
    required this.tariffType,
    super.key,
  });

  final double kwh;
  final double bill;
  final String monthLabel;
  final TariffType tariffType;

  bool get _billExcludesAfa => TariffRates.afaApplies(tariffType, kwh);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              monthLabel,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.text2),
            ),
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.surface3,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: AppColors.text3.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                tariffType.shortLabel,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.text2,
                  fontSize: 9.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _SummaryStat(
                label: 'kWh Used',
                value: kwh.toStringAsFixed(0),
                unit: 'kWh',
                color: AppColors.accent2,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _BillStat(
                bill: bill,
                monthLabel: monthLabel,
                excludesAfa: _billExcludesAfa,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

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
          Text(label, style: AppTextStyles.caption),
          SizedBox(height: 4.h),
          Text(
            value,
            style: AppTextStyles.statMd.copyWith(color: color),
          ),
          SizedBox(height: 2.h),
          Text(
            unit,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.text3,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _BillStat extends StatelessWidget {
  const _BillStat({
    required this.bill,
    required this.monthLabel,
    required this.excludesAfa,
  });

  final double bill;
  final String monthLabel;
  final bool excludesAfa;

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
            children: [
              Text('Est. Bill', style: AppTextStyles.caption),
              if (excludesAfa) ...[
                SizedBox(width: 4.w),
                Tooltip(
                  message: 'AFA not included — published monthly by TNB.',
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 11.r,
                    color: AppColors.warn,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'RM ${bill.toStringAsFixed(2)}',
            style: AppTextStyles.statMd.copyWith(color: AppColors.accent),
          ),
          SizedBox(height: 2.h),
          Text(
            excludesAfa ? 'excl. AFA · $monthLabel' : monthLabel,
            style: AppTextStyles.caption.copyWith(
              color: excludesAfa ? AppColors.warn : AppColors.text3,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }
}
