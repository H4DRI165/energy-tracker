import 'package:energy_tracker/extensions/tariff_type_extension.dart';
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
    return Row(
      children: [
        Expanded(child: _DailyAvgCard(compact: compact)),
        SizedBox(width: 10.w),
        Expanded(child: _TariffCard(compact: compact)),
      ],
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

    final badge = dailyAvg <= 8.0 ? '↓ Normal' : '↑ High';
    final badgeColor = dailyAvg <= 8.0 ? AppColors.accent : AppColors.danger;
    final badgeBg = dailyAvg <= 8.0
        ? AppColors.accent.withValues(alpha: 0.12)
        : AppColors.danger.withValues(alpha: 0.12);

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
    final tariffType = ref.watch(
      dashboardProvider.select((s) => s.value?.tariffType),
    );
    final currentBand = ref.watch(
      dashboardProvider.select((s) => s.value?.currentEeiBand),
    );
    final tierColor = ref.watch(
      dashboardProvider.select((s) => s.value?.tierColor),
    );
    final tierRange = ref.watch(
      dashboardProvider.select((s) => s.value?.tierRange),
    );

    final label =
        tariffType == TariffType.domestic ? 'EEI Band' : 'Tariff Tier';
    final value = tariffType == TariffType.domestic
        ? 'Band ${currentBand?.number == 0 ? '—' : currentBand?.number}'
        : 'Tier ${currentBand?.number}';
    final badge = tariffType == TariffType.domestic
        ? currentBand?.description ?? ''
        : tierRange ?? '';

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
