import 'dart:async';

import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/components/display/animated_number.dart';
import 'package:energy_tracker/ui/components/feedback/app_bottom_sheet.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_notifier.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProjectedBillCard extends ConsumerWidget {
  const ProjectedBillCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider.select((s) => s.value));
    final projectedBill = state?.projectedBill;
    final projectedKwh = state?.projectedKwh;

    if (state == null || projectedBill == null || projectedKwh == null) {
      return const SizedBox.shrink();
    }

    final budget = state.monthlyBudget;
    final hasBudget = budget > 0;
    final difference = budget - projectedBill;
    final isOverBudget = hasBudget && difference < 0;
    final statusColor = !hasBudget
        ? AppColors.text3
        : isOverBudget
        ? AppColors.danger
        : AppColors.accent;
    final statusLabel = !hasBudget
        ? 'No monthly budget set'
        : difference == 0
        ? 'On budget'
        : isOverBudget
        ? 'RM ${difference.abs().toStringAsFixed(0)} over budget'
        : 'RM ${difference.toStringAsFixed(0)} under budget';

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isOverBudget
              ? AppColors.danger.withValues(alpha: 0.28)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.auto_graph_rounded,
              size: 20.r,
              color: statusColor,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'PROJECTED BILL',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.text3,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showProjectionInfo(context, state),
                      tooltip: 'How projected bill is calculated',
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints.tightFor(
                        width: 28.r,
                        height: 28.r,
                      ),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.info_outline_rounded,
                        size: 16.r,
                        color: AppColors.text3,
                      ),
                    ),
                  ],
                ),
                AnimatedNumberText(
                  value: projectedBill,
                  formatter: (value) => 'RM ${value.toStringAsFixed(2)}',
                  style: AppTextStyles.statMd.copyWith(
                    color: AppColors.text,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '~${projectedKwh.toStringAsFixed(0)} kWh by month end',
                  style: AppTextStyles.caption.copyWith(color: AppColors.text3),
                ),
                SizedBox(height: 2.h),
                Text(
                  statusLabel,
                  style: AppTextStyles.caption.copyWith(color: statusColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showProjectionInfo(BuildContext context, DashboardPageState state) {
  final projectedKwh = state.projectedKwh ?? 0;
  final daysElapsed = DateTime.now().day;

  unawaited(
    showAppBottomSheet<void>(
      context: context,
      builder: (_) => AppBottomSheet(
        header: Text(
          'How this forecast works',
          style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w700),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This estimates your full-month bill by continuing your current '
              'daily usage pace through the rest of the month.',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.text2,
                height: 1.5,
              ),
            ),
            SizedBox(height: 16.h),
            _ProjectionInfoRow(
              label: 'So far',
              value:
                  '${state.kwhUsed.toStringAsFixed(0)} kWh '
                  'in $daysElapsed days',
            ),
            SizedBox(height: 8.h),
            _ProjectionInfoRow(
              label: 'Daily average',
              value: '${state.dailyAvg.toStringAsFixed(1)} kWh/day',
            ),
            SizedBox(height: 8.h),
            _ProjectionInfoRow(
              label: 'Projected month',
              value: '~${projectedKwh.toStringAsFixed(0)} kWh',
            ),
            SizedBox(height: 8.h),
            _ProjectionInfoRow(
              label: 'Projected bill',
              value: 'RM ${(state.projectedBill ?? 0).toStringAsFixed(2)}',
            ),
            SizedBox(height: 16.h),
            Text(
              'This is an estimate based on your readings. It is not your '
              'actual TNB bill and will change as you add more readings.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.text3,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProjectionInfoRow extends StatelessWidget {
  const _ProjectionInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.text2),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
