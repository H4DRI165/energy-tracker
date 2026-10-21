import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StatCardsRow extends StatelessWidget {
  const StatCardsRow({this.compact = false, super.key});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _DailyAvgCard(compact: compact)),
          SizedBox(width: 10.w),
          Expanded(child: _TariffCard(compact: compact)),
        ],
      ),
    );
  }
}

class _DailyAvgCard extends ConsumerWidget {
  const _DailyAvgCard({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAvg = ref.watch(
      dashboardProvider.select((s) => s.value?.dailyAvg ?? 0.0),
    );
    final monthlyBudget = ref.watch(
      dashboardProvider.select((s) => s.value?.monthlyBudget ?? 0.0),
    );
    final now = DateTime.now();
    final targetDailyKwh = monthlyBudget > 0
        ? TariffRates.estimateKwhFromBudget(monthlyBudget) /
              DateUtils.getDaysInMonth(now.year, now.month)
        : 0.0;
    final hasUsage = dailyAvg > 0;
    final isAboveTarget =
        hasUsage && targetDailyKwh > 0 && dailyAvg > targetDailyKwh * 1.05;

    final badge = !hasUsage
        ? 'No usage'
        : targetDailyKwh <= 0
        ? 'No budget target'
        : isAboveTarget
        ? '↑ Above target'
        : '↓ On track';
    final badgeColor = !hasUsage
        ? AppColors.text3
        : isAboveTarget
        ? AppColors.danger
        : AppColors.accent;
    final badgeBg = badgeColor.withValues(alpha: 0.12);

    return _StatCard(
      label: 'Daily Avg',
      value: dailyAvg.toStringAsFixed(1),
      unit: 'kWh',
      valueColor: AppColors.accent2,
      badge: badge,
      badgeColor: badgeColor,
      badgeBg: badgeBg,
      compact: compact,
    );
  }
}

class _TariffCard extends ConsumerWidget {
  const _TariffCard({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBand = ref.watch(
      dashboardProvider.select((s) => s.value?.currentEeiBand),
    );
    final kwhUsed = ref.watch(
      dashboardProvider.select((s) => s.value?.kwhUsed ?? 0.0),
    );
    final tierColor = ref.watch(
      dashboardProvider.select((s) => s.value?.tierColor),
    );

    const label = 'EEI Band';
    final isNoUsage = kwhUsed <= 0;
    final value = isNoUsage
        ? 'No usage'
        : currentBand?.number == 0
        ? 'No rebate'
        : 'Band ${currentBand?.number}';
    final badge = isNoUsage
        ? 'No usage'
        : currentBand?.number == 0
        ? 'No rebate'
        : currentBand == null
        ? ''
        : '${currentBand.rebateSenPerKwh.toStringAsFixed(1)} sen/kWh';

    return _StatCard(
      label: label,
      value: value,
      unit: '',
      valueColor: tierColor ?? AppColors.text,
      badge: badge,
      badgeColor: tierColor ?? AppColors.text,
      badgeBg: (tierColor ?? AppColors.text).withValues(alpha: 0.12),
      compact: compact,
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
    this.compact = false,
  });

  final String label;
  final String value;
  final String unit;
  final Color valueColor;
  final String badge;
  final Color badgeColor;
  final Color badgeBg;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        compact
            ? AppDimensions.cardPaddingSm * 0.7
            : AppDimensions.cardPaddingSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          SizedBox(height: 4.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTextStyles.statMd.copyWith(color: valueColor),
              ),
              if (unit.isNotEmpty) ...[
                SizedBox(width: 3.w),
                Text(unit, style: AppTextStyles.caption),
              ],
            ],
          ),
          SizedBox(height: compact ? 4.h : 6.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: AppTextStyles.tag.copyWith(
                color: badgeColor,
                fontSize: 10.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
