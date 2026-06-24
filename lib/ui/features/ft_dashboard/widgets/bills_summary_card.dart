import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:energy_tracker/services/notifiers/user_profile_notifier.dart';
import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BillSummaryCard extends ConsumerStatefulWidget {
  const BillSummaryCard({
    required this.state,
    super.key,
  });

  final DashboardPageState state;

  @override
  ConsumerState<BillSummaryCard> createState() => _BillSummaryCardState();
}

class _BillSummaryCardState extends ConsumerState<BillSummaryCard> {
  @override
  Widget build(BuildContext context) {
    final isAlert = widget.state.isNearBudget || widget.state.isOverBudget;
    final billColor = widget.state.billColor;

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
                              widget.state.monthLabel.toUpperCase(),
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
                                widget.state.tariffType.shortLabel,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.text2,
                                  fontSize: 9.sp,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.state.tariffType !=
                            ref.watch(tariffTypeProvider)) ...[
                          SizedBox(height: 4.h),
                          Text(
                            'Showing ${widget.state.tariffType.shortLabel} '
                            "rates — matches this month's readings",
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.text3),
                          ),
                        ],
                        SizedBox(height: 4.h),
                        Text(
                          'RM ${widget.state.estimatedBill.toStringAsFixed(2)}',
                          style: AppTextStyles.displayLg,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          isAlert && widget.state.projectedBill != null
                              ? '${widget.state.kwhUsed.toStringAsFixed(0)} kWh · '
                                  'Projected: RM '
                                  '${widget.state.projectedBill!.toStringAsFixed(0)}'
                              : 'Estimated bill · '
                                  '${widget.state.kwhUsed.toStringAsFixed(0)} '
                                  'kWh used',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.text2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.state.percentageVsLastMonth != 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _ChangeBadge(
                          percent: widget.state.percentageVsLastMonth,
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'vs last month',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budget used',
                    style: AppTextStyles.bodySm,
                  ),
                  Text(
                    'RM ${widget.state.estimatedBill.toStringAsFixed(0)} '
                    '/ RM ${widget.state.monthlyBudget.toStringAsFixed(0)}',
                    style: AppTextStyles.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isAlert ? AppColors.warn : AppColors.text,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: widget.state.budgetUsedPercent),
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
              SizedBox(height: 6.h),
              Text(
                widget.state.budgetStatusLabel,
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
