import 'package:energy_tracker/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DomesticLineItem extends StatelessWidget {
  const DomesticLineItem({
    required this.item,
    super.key,
  });

  final ChargeLineItem item;

  @override
  Widget build(BuildContext context) {
    final isRebate = item.isRebate;
    final isLevy = item.isLevy;

    final amountColor = isRebate
        ? AppColors.accent
        : isLevy
            ? AppColors.text2
            : AppColors.text;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.bodySm.copyWith(
                    color: isLevy ? AppColors.text2 : AppColors.text,
                    fontWeight: isLevy ? FontWeight.w400 : FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  item.rateLabel,
                  style: AppTextStyles.caption.copyWith(color: AppColors.text3),
                ),
              ],
            ),
          ),
          Text(
            '${isRebate ? '−' : ''}RM ${item.amount.abs().toStringAsFixed(2)}',
            style: AppTextStyles.bodySm.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
