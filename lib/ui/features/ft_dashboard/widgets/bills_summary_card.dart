import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_state.dart';
import 'package:flutter/material.dart';

class BillSummaryCard extends StatelessWidget {
  const BillSummaryCard({
    required this.state,
    super.key,
  });

  final DashboardPageState state;

  @override
  Widget build(BuildContext context) {
    final isAlert = state.isNearBudget || state.isOverBudget;
    final billColor = state.billColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isAlert
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2D1A0A), Color(0xFF1E1A0A)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D2D24), Color(0xFF0A1E2E)],
              ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isAlert ? const Color(0x4DFFB020) : const Color(0x3300D4AA),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    billColor.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.monthLabel.toUpperCase(),
                          style: AppTextStyles.overline.copyWith(
                            color: billColor,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'RM ${state.estimatedBill.toStringAsFixed(2)}',
                          style: AppTextStyles.displayLg,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAlert && state.projectedBill != null
                              ? '${state.kwhUsed.toStringAsFixed(0)} kWh · '
                                  'Projected: RM '
                                  '${state.projectedBill!.toStringAsFixed(0)}'
                              : 'Estimated bill · '
                                  '${state.kwhUsed.toStringAsFixed(0)} '
                                  'kWh used',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.text2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.percentageVsLastMonth != 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _ChangeBadge(percent: state.percentageVsLastMonth),
                        const SizedBox(height: 6),
                        Text(
                          'vs last month',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budget used',
                    style: AppTextStyles.bodySm,
                  ),
                  Text(
                    'RM ${state.estimatedBill.toStringAsFixed(0)} '
                    '/ RM ${state.monthlyBudget.toStringAsFixed(0)}',
                    style: AppTextStyles.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isAlert ? AppColors.warn : AppColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: state.budgetUsedPercent),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: AppColors.surface3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isAlert ? AppColors.warn : AppColors.accent,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.budgetStatusLabel,
                style: AppTextStyles.caption.copyWith(color: billColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChangeBadge extends StatelessWidget {
  const _ChangeBadge({required this.percent});
  final double percent;

  @override
  Widget build(BuildContext context) {
    final isDown = percent <= 0;
    final color = isDown ? AppColors.accent : AppColors.danger;
    final bgColor = isDown
        ? AppColors.accent.withValues(alpha: 0.12)
        : AppColors.danger.withValues(alpha: 0.12);
    final arrow = isDown ? '↓' : '↑';
    final label = '$arrow ${percent.abs().toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.tag.copyWith(color: color),
      ),
    );
  }
}
