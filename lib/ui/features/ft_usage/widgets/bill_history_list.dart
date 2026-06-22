import 'package:energy_tracker/models/bill_record.dart';
import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/components/badge.dart';
import 'package:energy_tracker/ui/components/dialog.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_notifier.dart';
import 'package:energy_tracker/ui/features/ft_usage/notifier/usage_notifier.dart';
import 'package:energy_tracker/ui/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class BillHistoryList extends ConsumerWidget {
  const BillHistoryList({
    required this.bills,
    super.key,
  });

  final List<BillRecord> bills;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedBills = [...bills]..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bill History',
              style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
            ),
            Row(
              children: [
                Icon(
                  Icons.swipe_left_rounded,
                  size: 14.r,
                  color: AppColors.text3,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Swipe to delete history',
                  style: AppTextStyles.caption.copyWith(color: AppColors.text3),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 10.h),
        if (sortedBills.isEmpty)
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
              children: sortedBills.asMap().entries.map((entry) {
                final bill = entry.value;
                final isLast = entry.key == sortedBills.length - 1;
                final iconBg = entry.key.isEven
                    ? AppColors.accent.withValues(alpha: 0.10)
                    : AppColors.accent2.withValues(alpha: 0.10);

                return ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: entry.key == 0
                        ? Radius.circular(AppDimensions.radiusLg)
                        : Radius.zero,
                    bottom: isLast
                        ? Radius.circular(AppDimensions.radiusLg)
                        : Radius.zero,
                  ),
                  child: Dismissible(
                    key: Key(bill.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20.w),
                      color: AppColors.danger.withValues(alpha: 0.15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.danger,
                            size: 22.r,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Delete',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                    confirmDismiss: (_) => ConfirmDialog.show(
                      context,
                      title: 'Delete ${bill.monthYear}?',
                      message:
                          'This will permanently delete all readings and bill '
                          'records for ${bill.monthYear}.',
                      confirmLabel: 'Delete',
                      confirmColor: AppColors.danger,
                      warning:
                          'This action cannot be undone. All meter readings '
                          'for this month will be lost.',
                    ),
                    onDismissed: (_) async {
                      try {
                        await ref
                            .read(usageProvider.notifier)
                            .deleteMonth(bill);
                        ref.invalidate(dashboardProvider);
                        await ref.read(dashboardProvider.future);
                      } on Exception {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Failed to delete. Please try again.'),
                            ),
                          );
                        }
                      }
                    },
                    child: GestureDetector(
                      onTap: () =>
                          context.push(AppRoutes.billDetail, extra: bill),
                      child: Container(
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
                                PaidBadge(isPaid: bill.isPaid),
                              ],
                            ),
                            SizedBox(width: 8.w),
                            Icon(
                              Icons.chevron_left_rounded,
                              size: 16.r,
                              color: AppColors.text3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
