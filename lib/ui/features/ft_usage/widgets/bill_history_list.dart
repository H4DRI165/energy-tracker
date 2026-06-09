import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/features/ft_usage/notifier/usage_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BillHistoryList extends StatelessWidget {
  const BillHistoryList({
    required this.bills,
    super.key,
  });

  final List<BillRecord> bills;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bill History',
          style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 10.h),
        if (bills.isEmpty)
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                'No bill history yet.\nAdd meter readings to see your history.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySm,
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: bills.asMap().entries.map((entry) {
                final bill = entry.value;
                final isLast = entry.key == bills.length - 1;
                final iconBg = entry.key.isEven
                    ? AppColors.accent.withValues(alpha: 0.10)
                    : AppColors.accent2.withValues(alpha: 0.10);

                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : const Border(
                            bottom: BorderSide(color: AppColors.border),
                          ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36.r,
                        height: 36.r,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Center(
                          child: Text(
                            '📅',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bill.monthYear,
                              style: AppTextStyles.bodyMd.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${bill.kwh.toStringAsFixed(0)} kWh',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'RM ${bill.amount.toStringAsFixed(2)}',
                            style: AppTextStyles.bodyMd.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          _PaidBadge(isPaid: bill.isPaid),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _PaidBadge extends StatelessWidget {
  const _PaidBadge({required this.isPaid});
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    final color = isPaid ? AppColors.accent : AppColors.warn;
    final bg = isPaid
        ? AppColors.accent.withValues(alpha: 0.12)
        : AppColors.warn.withValues(alpha: 0.12);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        isPaid ? 'Paid' : 'Pending',
        style: AppTextStyles.tag.copyWith(
          fontSize: 10.sp,
          color: color,
        ),
      ),
    );
  }
}
