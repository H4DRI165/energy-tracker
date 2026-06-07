import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_state.dart';
import 'package:flutter/material.dart';

class BudgetAlertBanner extends StatelessWidget {
  const BudgetAlertBanner({
    required this.state,
    super.key,
  });

  final DashboardPageState state;

  @override
  Widget build(BuildContext context) {
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
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
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
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
