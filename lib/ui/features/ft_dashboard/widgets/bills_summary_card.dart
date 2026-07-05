import 'dart:async';

import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:energy_tracker/services/notifiers/user_profile_notifier.dart';
import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BillSummaryCard extends ConsumerWidget {
  const BillSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      dashboardProvider.select((s) => s.value),
    );
    if (state == null) return const SizedBox.shrink();

    final tariffType = ref.watch(tariffTypeProvider);
    final isAlert = state.isNearBudget || state.isOverBudget;
    final billColor = state.billColor;

    return Container(
      padding: EdgeInsets.all(20.r),
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
              width: 120.r,
              height: 120.r,
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
                        Row(
                          children: [
                            Text(
                              state.monthLabel.toUpperCase(),
                              style: AppTextStyles.overline.copyWith(
                                color: billColor,
                                letterSpacing: 2,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.surface3.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: AppColors.text3.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                state.tariffType.shortLabel,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.text2,
                                  fontSize: 9.sp,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (state.tariffType != tariffType) ...[
                          SizedBox(height: 4.h),
                          Text(
                            'Showing ${state.tariffType.shortLabel} '
                            "rates — matches this month's readings",
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.text3),
                          ),
                        ],
                        SizedBox(height: 4.h),
                        Text(
                          'RM ${state.estimatedBill.toStringAsFixed(2)}',
                          style: AppTextStyles.displayLg,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          isAlert && state.projectedBill != null
                              ? '${state.kwhUsed.toStringAsFixed(0)} kWh · '
                                  'Projected: RM ${state.projectedBill!.toStringAsFixed(0)}'
                              : 'Estimated bill · ${state.kwhUsed.toStringAsFixed(0)} kWh used',
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
                        SizedBox(height: 6.h),
                        Text('vs last month', style: AppTextStyles.caption),
                      ],
                    ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Budget used', style: AppTextStyles.bodySm),
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
              SizedBox(height: 6.h),
              _AnimatedBudgetProgress(
                value: state.budgetUsedPercent,
                isAlert: isAlert,
              ),
              SizedBox(height: 6.h),
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
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

class _AnimatedBudgetProgress extends StatefulWidget {
  const _AnimatedBudgetProgress({
    required this.value,
    required this.isAlert,
  });

  final double value;
  final bool isAlert;

  @override
  State<_AnimatedBudgetProgress> createState() =>
      _AnimatedBudgetProgressState();
}

class _AnimatedBudgetProgressState extends State<_AnimatedBudgetProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut)
        .drive(Tween(begin: 0, end: widget.value));
    unawaited(_controller.forward());
  }

  @override
  void didUpdateWidget(covariant _AnimatedBudgetProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut)
          .drive(Tween(begin: _animation.value, end: widget.value));
      unawaited(_controller.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          return LinearProgressIndicator(
            value: _animation.value,
            minHeight: 8,
            backgroundColor: AppColors.surface3,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.isAlert ? AppColors.warn : AppColors.accent,
            ),
          );
        },
      ),
    );
  }
}
