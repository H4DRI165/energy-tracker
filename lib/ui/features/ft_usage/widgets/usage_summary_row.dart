import 'package:energy_tracker/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UsageSummaryRow extends StatelessWidget {
  const UsageSummaryRow({
    required this.kwh,
    required this.bill,
    required this.monthLabel,
    super.key,
  });

  final double kwh;
  final double bill;
  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
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
          child: _SummaryStat(
            label: 'Est. Bill',
            value: 'RM ${bill.toStringAsFixed(2)}',
            unit: monthLabel,
            color: AppColors.accent,
          ),
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
