import 'dart:async';

import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_notifier.dart';
import 'package:energy_tracker/ui/features/ft_usage/notifier/usage_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class BarChartEntry {
  const BarChartEntry({
    required this.label,
    required this.kwh,
    this.isHighlighted = false,
  });

  final String label;
  final double kwh;
  final bool isHighlighted;
}

class WeeklyUsageChartCard extends ConsumerWidget {
  const WeeklyUsageChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyUsage = ref.watch(
      dashboardProvider.select(
        (asyncState) => asyncState.value?.weeklyUsage ?? const [],
      ),
    );

    return UsageBarChartCard(
      title: '7-Day Usage',
      subtitle: 'kWh/day',
      chartHeight: 80,
      entries: weeklyUsage
          .map(
            (day) => BarChartEntry(
              label: day.label,
              kwh: day.kwh,
              isHighlighted: day.isToday,
            ),
          )
          .toList(),
    );
  }
}

class MonthlyUsageChartCard extends ConsumerWidget {
  const MonthlyUsageChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartData = ref.watch(
      usageProvider.select(
        (asyncState) => asyncState.value?.chartData ?? const [],
      ),
    );

    final currentMonthAbbr = DateFormat('MMM').format(DateTime.now());
    final currentYear = DateTime.now().year;

    return UsageBarChartCard(
      title: 'kWh Usage',
      subtitle: 'kWh',
      entries: chartData
          .map(
            (month) => BarChartEntry(
              label: month.month,
              kwh: month.kwh,
              isHighlighted:
                  month.year == currentYear && month.month == currentMonthAbbr,
            ),
          )
          .toList(),
    );
  }
}

class UsageBarChartCard extends StatefulWidget {
  const UsageBarChartCard({
    required this.title,
    required this.subtitle,
    required this.entries,
    this.chartHeight = 110,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<BarChartEntry> entries;
  final double chartHeight;

  @override
  State<UsageBarChartCard> createState() => _UsageBarChartCardState();
}

class _UsageBarChartCardState extends State<UsageBarChartCard>
    with SingleTickerProviderStateMixin {
  static const double _valueLabelHeight = 16;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    unawaited(_controller.forward());
  }

  @override
  void didUpdateWidget(covariant UsageBarChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(
      oldWidget.entries.map((e) => e.kwh).toList(),
      widget.entries.map((e) => e.kwh).toList(),
    )) {
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
    final entries = widget.entries;
    final maxKwh = entries.isEmpty
        ? 1.0
        : entries.map((e) => e.kwh).reduce((a, b) => a > b ? a : b);
    final maxBarHeight = widget.chartHeight.h - _valueLabelHeight.h - 3.h;

    return Container(
      padding: EdgeInsets.all(AppDimensions.cardPaddingSm),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(widget.subtitle, style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (entries.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text('No readings yet', style: AppTextStyles.bodySm),
              ),
            )
          else ...[
            RepaintBoundary(
              child: SizedBox(
                height: widget.chartHeight.h,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(entries.length, (i) {
                    final entry = entries[i];
                    final heightFraction = maxKwh > 0
                        ? (entry.kwh <= 0
                              ? 0.0
                              : (entry.kwh / maxKwh).clamp(0.05, 1.0))
                        : 0.0;

                    final start = (i / entries.length) * 0.3;
                    final animation = CurvedAnimation(
                      parent: _controller,
                      curve: Interval(start, 1, curve: Curves.easeOutQuart),
                    );

                    return Expanded(
                      key: ValueKey(entry.label),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: _SlimBar(
                          animation: animation,
                          heightFraction: heightFraction,
                          isHighlighted: entry.isHighlighted,
                          kwh: entry.kwh,
                          maxBarHeight: maxBarHeight,
                          valueLabelHeight: _valueLabelHeight.h,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              children: entries.map((entry) {
                return Expanded(
                  child: Text(
                    entry.label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10.sp,
                      color: entry.isHighlighted
                          ? AppColors.accent
                          : AppColors.text3,
                      fontWeight: entry.isHighlighted
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SlimBar extends StatelessWidget {
  const _SlimBar({
    required this.animation,
    required this.heightFraction,
    required this.isHighlighted,
    required this.kwh,
    required this.maxBarHeight,
    required this.valueLabelHeight,
  });

  final Animation<double> animation;
  final double heightFraction;
  final bool isHighlighted;
  final double kwh;
  final double maxBarHeight;
  final double valueLabelHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: valueLabelHeight,
          child: kwh > 0
              ? Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    kwh.toStringAsFixed(0),
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 9.sp,
                      color: isHighlighted ? AppColors.accent : AppColors.text3,
                      fontWeight: isHighlighted
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        SizedBox(height: 3.h),
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final value = (animation.value * heightFraction).clamp(0.0, 1.0);
            return SizedBox(
              height: maxBarHeight * value,
              child: RepaintBoundary(
                child: Container(
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? AppColors.accent
                        : AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(4.r),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
