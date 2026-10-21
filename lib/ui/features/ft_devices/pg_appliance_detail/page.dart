import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/ui/features/ft_devices/pg_devices/notifier/devices_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ApplianceDetailPage extends ConsumerWidget {
  const ApplianceDetailPage({required this.appliance, super.key});

  final Appliance appliance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(
      devicesProvider.select((state) {
        for (final item in state.appliances) {
          if (item.id == appliance.id) return item;
        }
        return appliance;
      }),
    );
    final totalKwh = ref.watch(
      devicesProvider.select((state) => state.totalMonthlyKwh),
    );
    final share = totalKwh > 0
        ? (current.monthlyKwh / totalKwh).clamp(0.0, 1.0)
        : 0.0;
    final savingPerMonth = current.hourlyCost * 30;
    final lowHours = current.estimatedLowDailyHours;
    final highHours = current.estimatedHighDailyHours;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.screenPaddingH,
                12.h,
                AppDimensions.screenPaddingH,
                8.h,
              ),
              child: Row(
                children: [
                  _IconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: 'Back',
                    onTap: () => context.pop(),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Appliance Details',
                      style: AppTextStyles.titleMd,
                    ),
                  ),
                  _IconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit appliance',
                    onTap: () => context.push(
                      AppRoutes.editAppliance,
                      extra: current,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppDimensions.screenPaddingH,
                  4.h,
                  AppDimensions.screenPaddingH,
                  28.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCard(
                      appliance: current,
                      share: share,
                    ),
                    SizedBox(height: 14.h),
                    _StatsCard(
                      appliance: current,
                      share: share,
                    ),
                    if (current.dailyHours > 1) ...[
                      SizedBox(height: 14.h),
                      _SavingCard(savingPerMonth: savingPerMonth),
                    ],
                    SizedBox(height: 14.h),
                    _HowWeEstimateCard(
                      appliance: current,
                      lowHours: lowHours,
                      highHours: highHours,
                    ),
                    SizedBox(height: 20.h),
                    GradientButton(
                      label: 'Edit Appliance',
                      isLoading: false,
                      onTap: () => context.push(
                        AppRoutes.editAppliance,
                        extra: current,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.r,
      height: 36.r,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 16.r, color: AppColors.text2),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.appliance, required this.share});

  final Appliance appliance;
  final double share;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.borderAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46.r,
                height: 46.r,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Center(
                  child: Text(
                    appliance.categoryEmoji,
                    style: TextStyle(fontSize: 22.sp),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appliance.name,
                      style: AppTextStyles.titleMd,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${appliance.category} · '
                      '${appliance.wattage.toStringAsFixed(0)}W rated',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            '~RM ${appliance.monthlyCost().toStringAsFixed(0)}/month',
            style: AppTextStyles.displayMd.copyWith(color: AppColors.accent),
          ),
          SizedBox(height: 4.h),
          Text(
            'Estimated at a typical ${appliance.dailyHours}h/day · '
            '${(share * 100).toStringAsFixed(0)}% of tracked usage',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.text2),
          ),
          SizedBox(height: 2.h),
          Text(
            'Range ~RM ${appliance.estimatedLowMonthlyCost.toStringAsFixed(0)}'
            '–${appliance.estimatedHighMonthlyCost.toStringAsFixed(0)}',
            style: AppTextStyles.caption.copyWith(color: AppColors.text3),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.appliance, required this.share});

  final Appliance appliance;
  final double share;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DetailStat(
                  label: 'Est. per day',
                  value: '~RM ${appliance.dailyCost().toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                child: _DetailStat(
                  label: 'Est. per hour',
                  value: '~RM ${appliance.hourlyCost.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _DetailStat(
                  label: 'Energy / month',
                  value: '~${appliance.monthlyKwh.toStringAsFixed(0)} kWh',
                ),
              ),
              Expanded(
                child: _DetailStat(
                  label: 'Share of tracked',
                  value: '${(share * 100).toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.text3),
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SavingCard extends StatelessWidget {
  const _SavingCard({required this.savingPerMonth});

  final double savingPerMonth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.borderAccent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.trending_down_rounded,
            size: 20.r,
            color: AppColors.accent,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What if you used it 1 hour less per day?',
                  style: AppTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'You could save roughly '
                  'RM ${savingPerMonth.toStringAsFixed(0)} per month.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.text2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HowWeEstimateCard extends StatelessWidget {
  const _HowWeEstimateCard({
    required this.appliance,
    required this.lowHours,
    required this.highHours,
  });

  final Appliance appliance;
  final double lowHours;
  final double highHours;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How this is estimated',
            style: AppTextStyles.bodySm.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '${appliance.wattage.toStringAsFixed(0)}W × '
            '${appliance.dailyHours}h/day × 30 days',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.text2),
          ),
          SizedBox(height: 4.h),
          Text(
            'Daily use varies, so the range is based on '
            '${lowHours.toStringAsFixed(1)}–${highHours.toStringAsFixed(1)} '
            'hours/day.',
            style: AppTextStyles.caption.copyWith(color: AppColors.text3),
          ),
          SizedBox(height: 6.h),
          Text(
            'Uses flat energy, capacity and network rates. It excludes EEI, '
            'KWTBB and SST, so it is not your TNB bill. Rated wattage may '
            'differ from actual draw, especially for inverter appliances.',
            style: AppTextStyles.caption.copyWith(color: AppColors.text3),
          ),
        ],
      ),
    );
  }
}
