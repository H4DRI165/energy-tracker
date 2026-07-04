import 'package:energy_tracker/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BillBreakdownCard extends StatelessWidget {
  const BillBreakdownCard({
    required this.items,
    required this.emptyLabel,
    this.padding,
    this.disclaimerColor,
    super.key,
  });

  final List<ChargeLineItem> items;
  final String emptyLabel;
  final EdgeInsetsGeometry? padding;
  final Color? disclaimerColor;

  @override
  Widget build(BuildContext context) {
    final effectivePadding =
        padding ?? EdgeInsets.all(AppDimensions.cardPaddingSm);

    return Container(
      padding: effectivePadding,
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
          if (items.isEmpty)
            Text(emptyLabel, style: AppTextStyles.bodySm)
          else
            ...items.map((item) => ChargeLineItemRow(item: item)),
          Divider(height: 16.h, color: AppColors.border),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 11.r,
                color: AppColors.warn,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  'Excludes AFA — a monthly fuel adjustment '
                  'published by TNB.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.warn,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
