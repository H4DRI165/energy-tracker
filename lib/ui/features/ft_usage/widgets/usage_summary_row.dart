import 'package:energy_tracker/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UsageSummaryRow extends StatelessWidget {
  const UsageSummaryRow({
    required this.kwh,
    required this.bill,
    required this.monthLabel,
    this.monthProgressLabel,
    this.status,
    super.key,
  });

  final double kwh;
  final double bill;
  final String monthLabel;
  final String? monthProgressLabel;
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                monthLabel,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.text2,
                ),
              ),
            ),
            if (monthProgressLabel != null)
              Text(
                monthProgressLabel!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.text3,
                  fontSize: 10.sp,
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _SummaryStat(
                label: 'Usage',
                value: kwh.toStringAsFixed(0),
                unit: 'kWh',
                color: AppColors.accent2,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(child: _BillStat(bill: bill)),
          ],
        ),
        if (status != null) ...[
          SizedBox(height: 9.h),
          status!,
        ],
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
  const _BillStat({required this.bill});

  final double bill;

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
          Text('Est. bill', style: AppTextStyles.caption),
          SizedBox(height: 4.h),
          Text(
            'RM ${bill.toStringAsFixed(2)}',
            style: AppTextStyles.statMd.copyWith(color: AppColors.accent),
          ),
          SizedBox(height: 2.h),
          Text(
            'Month-to-date',
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
