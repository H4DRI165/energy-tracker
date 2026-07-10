import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BudgetAlertBanner extends ConsumerWidget {
  const BudgetAlertBanner({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      dashboardProvider.select((s) => s.value),
    );

    if (state == null) return const SizedBox.shrink();

    final isExceeded = state.isOverBudget;
    final color = isExceeded ? AppColors.danger : AppColors.warn;
    final bgColor = color.withValues(alpha: 0.10);
    final borderColor = color.withValues(alpha: 0.30);
    final icon = isExceeded ? '🚨' : '⚠️';
    final title = isExceeded ? 'Budget Exceeded!' : '80% Budget Reached';
    final subtitle = isExceeded
        ? 'RM ${state.estimatedBill.toStringAsFixed(2)} used — RM '
            '${(state.estimatedBill - state.monthlyBudget).toStringAsFixed(2)} '
            'over your target.'
        : 'RM ${state.estimatedBill.toStringAsFixed(0)} used of RM '
            '${state.monthlyBudget.toStringAsFixed(0)} target. '
            '${state.daysLeft} days left.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: 22.sp)),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
