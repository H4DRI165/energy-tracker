import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_notifier.dart';
import 'package:energy_tracker/ui/features/ft_usage/notifier/usage_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class BillHistoryList extends StatelessWidget {
  const BillHistoryList({required this.bills, super.key});

  final List<BillRecord> bills;

  @override
  Widget build(BuildContext context) {
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
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedBills.length,
                itemBuilder: (context, index) {
                  final bill = sortedBills[index];
                  final isLast = index == sortedBills.length - 1;
                  final iconBg = index.isEven
                      ? AppColors.accent.withValues(alpha: 0.10)
                      : AppColors.accent2.withValues(alpha: 0.10);

                  return _BillHistoryTile(
                    key: Key(bill.id),
                    bill: bill,
                    isLast: isLast,
                    iconBg: iconBg,
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _BillHistoryTile extends ConsumerWidget {
  const _BillHistoryTile({
    required this.bill,
    required this.isLast,
    required this.iconBg,
    super.key,
  });

  final BillRecord bill;
  final bool isLast;
  final Color iconBg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
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
              style: AppTextStyles.caption.copyWith(color: AppColors.danger),
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
        final usageNotifier = ref.read(usageProvider.notifier);
        final dashboardNotifier = ref.read(dashboardProvider.notifier);

        try {
          await usageNotifier.deleteMonth(bill);
          await dashboardNotifier.refresh();
        } on Exception {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete. Please try again.'),
              ),
            );
          }
        }
      },
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.billDetail, extra: bill),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(bottom: BorderSide(color: AppColors.border)),
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
                  child: Text('📅', style: TextStyle(fontSize: 14.sp)),
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
                    SizedBox(height: 4.h),
                    Text(
                      '${bill.kwh.toStringAsFixed(0)} kWh',
                      style: AppTextStyles.caption,
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface3,
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: AppColors.text3.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        bill.tariffType.label,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.text2,
                          fontSize: 9.sp,
                          height: 1.2,
                        ),
                      ),
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
    );
  }
}
