import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_state.dart';
import 'package:flutter/material.dart';

class StatCardsRow extends StatelessWidget {
  const StatCardsRow({
    required this.state,
    this.compact = false,
    super.key,
  });

  final DashboardPageState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Daily Avg',
            value: state.dailyAvg.toStringAsFixed(1),
            unit: 'kWh',
            valueColor: AppColors.accent2,
            badge: state.dailyAvg <= 8.0 ? '↓ Normal' : '↑ High',
            badgeColor:
                state.dailyAvg <= 8.0 ? AppColors.accent : AppColors.danger,
            badgeBg: state.dailyAvg <= 8.0
                ? AppColors.accent.withValues(alpha: 0.12)
                : AppColors.danger.withValues(alpha: 0.12),
          ),
        ),
        const SizedBox(width: 10),
        // Tariff tier
        Expanded(
          child: _StatCard(
            label: 'Tariff Tier',
            value: 'Tier ${state.currentTier}',
            unit: '',
            valueColor: state.tierColor,
            badge: state.tierRange,
            badgeColor: state.tierColor,
            badgeBg: state.tierColor.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.valueColor,
    required this.badge,
    required this.badgeColor,
    required this.badgeBg,
  });

  final String label;
  final String value;
  final String unit;
  final Color valueColor;
  final String badge;
  final Color badgeColor;
  final Color badgeBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTextStyles.statMd.copyWith(color: valueColor),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(unit, style: AppTextStyles.caption),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: AppTextStyles.tag.copyWith(
                color: badgeColor,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
