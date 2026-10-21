import 'dart:async';

import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_notifier.dart';
import 'package:energy_tracker/ui/features/ft_usage/notifier/usage_notifier.dart';
import 'package:energy_tracker/ui/features/ft_usage/notifier/usage_state.dart';
import 'package:energy_tracker/ui/features/ft_usage/widgets/usage_filter_tab.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class BarChartEntry {
  const BarChartEntry({
    required this.label,
    required this.kwh,
    this.detail,
    this.isEstimated = false,
    this.isHighlighted = false,
  });

  final String label;
  final double kwh;

  final String? detail;
  final bool isEstimated;
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
    final weeklyTotal = weeklyUsage.fold<double>(
      0,
      (total, day) => total + day.kwh,
    );

    return UsageBarChartCard(
      title: '7-Day Usage',
      subtitle: 'kWh/day',
      chartHeight: 76,
      insight: weeklyUsage.isEmpty
          ? null
          : Text(
              'Total ${weeklyTotal.toStringAsFixed(0)} kWh · '
              'from reading intervals',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(color: AppColors.text2),
            ),
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
    final state = ref.watch(usageProvider).value;

    if (state == null) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(usageProvider.notifier);
    final now = DateTime.now();
    final currentMonthAbbr = DateFormat('MMM').format(now);
    final currentYear = now.year;
    final displayed = state.chartData;
    final hasCurrentMonth =
        displayed.isNotEmpty &&
        displayed.last.year == currentYear &&
        displayed.last.month == currentMonthAbbr;
    final monthlyBudget = state.monthlyBudget;
    final targetKwh = monthlyBudget > 0
        ? TariffRates.estimateKwhFromBudget(monthlyBudget)
        : null;

    double? trendPercent;
    String? previousMonthLabel;
    String? trendBasis;
    if (hasCurrentMonth && state.monthlyData.length >= 2) {
      final current = state.monthlyData.last;
      final previous = state.monthlyData[state.monthlyData.length - 2];
      if (current.kwh > 0 && previous.kwh > 0) {
        final monthComplete =
            now.day >= DateUtils.getDaysInMonth(now.year, now.month);
        if (monthComplete) {
          trendPercent = ((current.kwh - previous.kwh) / previous.kwh) * 100;
          trendBasis = 'total';
        } else {
          final previousDays = DateUtils.getDaysInMonth(
            previous.year,
            now.month - 1,
          );
          final currentPace = current.kwh / now.day;
          final previousPace = previous.kwh / previousDays;
          if (previousPace > 0) {
            trendPercent = ((currentPace - previousPace) / previousPace) * 100;
            trendBasis = 'daily pace';
          }
        }
        previousMonthLabel = previous.month;
      }
    }

    if (trendPercent == null) {
      final withData = state.monthlyData.where((m) => m.kwh > 0).toList();
      if (withData.length >= 2) {
        final latest = withData.last;
        final previous = withData[withData.length - 2];
        trendPercent = ((latest.kwh - previous.kwh) / previous.kwh) * 100;
        previousMonthLabel = previous.month;
        trendBasis = 'total';
      }
    }

    return UsageBarChartCard(
      title: 'Usage Trend',
      subtitle: 'kWh',
      chartHeight: 96,
      showValueLabels: state.filter == UsageFilter.monthly,
      targetKwh: targetKwh,
      insight: trendPercent == null || previousMonthLabel == null
          ? null
          : _TrendIndicator(
              percent: trendPercent,
              previousMonthLabel: previousMonthLabel,
              basis: trendBasis ?? 'total',
            ),
      trailing: SizedBox(
        width: 116.w,
        child: UsageFilterTabs(
          selected: state.filter,
          onChanged: notifier.setFilter,
        ),
      ),
      entries: displayed
          .map(
            (month) => BarChartEntry(
              label: month.month,
              kwh: month.kwh,
              detail: month.kwh > 0
                  ? 'RM ${month.bill.toStringAsFixed(2)}'
                  : null,
              isEstimated: month.isEstimated,
              isHighlighted:
                  month.year == currentYear && month.month == currentMonthAbbr,
            ),
          )
          .toList(),
    );
  }
}

class _TrendIndicator extends StatelessWidget {
  const _TrendIndicator({
    required this.percent,
    required this.previousMonthLabel,
    required this.basis,
  });

  final double percent;
  final String previousMonthLabel;
  final String basis;

  @override
  Widget build(BuildContext context) {
    final isFlat = percent.abs() < 0.5;
    final isUp = percent > 0;
    final color = isFlat
        ? AppColors.text3
        : isUp
        ? AppColors.danger
        : AppColors.accent;
    final icon = isFlat
        ? Icons.trending_flat_rounded
        : isUp
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final direction = isUp ? 'higher' : 'lower';
    final subject = basis == 'total' ? 'Total usage' : 'Usage pace';

    return Semantics(
      label: isFlat
          ? '$subject is flat versus $previousMonthLabel'
          : '$subject is ${percent.abs().toStringAsFixed(0)} percent '
                '$direction than $previousMonthLabel',
      child: Wrap(
        spacing: 6.w,
        runSpacing: 2.h,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22.r, color: color),
                SizedBox(width: 4.w),
                Text(
                  isFlat
                      ? '0%'
                      : '${isUp ? '+' : '−'}'
                            '${percent.abs().toStringAsFixed(0)}%',
                  style: AppTextStyles.displayMd.copyWith(
                    color: color,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Text(
            'vs $previousMonthLabel · $basis',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.text3,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class UsageBarChartCard extends StatefulWidget {
  const UsageBarChartCard({
    required this.title,
    required this.subtitle,
    required this.entries,
    this.trailing,
    this.insight,
    this.showValueLabels = true,
    this.targetKwh,
    this.chartHeight = 110,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<BarChartEntry> entries;

  final Widget? trailing;

  final Widget? insight;

  final bool showValueLabels;

  final double? targetKwh;
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
    final dataMax = entries.isEmpty
        ? 1.0
        : entries.map((e) => e.kwh).reduce((a, b) => a > b ? a : b);
    final target = widget.targetKwh ?? 0;
    final maxKwh = dataMax > target ? dataMax : (target > 0 ? target : 1.0);
    final valueLabelHeight = widget.showValueLabels ? _valueLabelHeight.h : 0.0;
    final maxBarHeight = widget.chartHeight.h - valueLabelHeight - 3.h;

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
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: AppDimensions.s8),
              widget.trailing ??
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
          SizedBox(height: 8.h),
          if (widget.insight != null) ...[
            widget.insight!,
            SizedBox(height: 8.h),
          ],
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: valueLabelHeight + 3.h,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            4,
                            (i) => Container(
                              height: 1,
                              color: AppColors.text3.withValues(
                                alpha: i == 3 ? 0.16 : 0.06,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
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
                        final detail = entry.detail;
                        final estimated = entry.isEstimated
                            ? ' (estimated)'
                            : '';
                        final semanticsLabel =
                            '${entry.label}: '
                            '${entry.kwh.toStringAsFixed(0)} kWh'
                            '${detail != null ? ', $detail' : ''}'
                            '$estimated';
                        final tooltipMessage =
                            '${entry.label} · '
                            '${entry.kwh.toStringAsFixed(0)} kWh'
                            '${detail != null ? ' · $detail' : ''}'
                            '$estimated';

                        return Expanded(
                          key: ValueKey(entry.label),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3.w),
                            child: Semantics(
                              label: semanticsLabel,
                              child: Tooltip(
                                message: tooltipMessage,
                                triggerMode: TooltipTriggerMode.tap,
                                child: ExcludeSemantics(
                                  child: _SlimBar(
                                    animation: animation,
                                    heightFraction: heightFraction,
                                    isHighlighted: entry.isHighlighted,
                                    isEstimated: entry.isEstimated,
                                    kwh: entry.kwh,
                                    maxBarHeight: maxBarHeight,
                                    valueLabelHeight: valueLabelHeight,
                                    showValueLabel: widget.showValueLabels,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    if (widget.targetKwh != null && widget.targetKwh! > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: maxBarHeight * (widget.targetKwh! / maxKwh),
                        child: IgnorePointer(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 1,
                                  child: CustomPaint(
                                    painter: _DashedLinePainter(
                                      color: AppColors.warn.withValues(
                                        alpha: 0.55,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 3.w,
                                  vertical: 1.h,
                                ),
                                color: AppColors.surface2,
                                child: Text(
                                  'Budget',
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 9.sp,
                                    color: AppColors.warn,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _TrendLinePainter(
                            values: entries.map((e) => e.kwh).toList(),
                            maxValue: maxKwh,
                            barAreaHeight: maxBarHeight,
                            color: AppColors.accent.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              children: entries.map((entry) {
                return Expanded(
                  child: Text(
                    entry.isEstimated ? '${entry.label}*' : entry.label,
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
    required this.isEstimated,
    required this.kwh,
    required this.maxBarHeight,
    required this.valueLabelHeight,
    required this.showValueLabel,
  });

  final Animation<double> animation;
  final double heightFraction;
  final bool isHighlighted;
  final bool isEstimated;
  final double kwh;
  final double maxBarHeight;
  final double valueLabelHeight;
  final bool showValueLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showValueLabel) ...[
          SizedBox(
            height: valueLabelHeight,
            child: kwh > 0
                ? Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      kwh.toStringAsFixed(0),
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 9.sp,
                        color: isHighlighted
                            ? AppColors.accent
                            : AppColors.text3,
                        fontWeight: isHighlighted
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          SizedBox(height: 3.h),
        ],
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
                        ? AppColors.accent.withValues(
                            alpha: isEstimated ? 0.60 : 1,
                          )
                        : AppColors.accent.withValues(
                            alpha: isEstimated ? 0.10 : 0.22,
                          ),
                    border: isEstimated
                        ? Border.all(
                            color: AppColors.accent.withValues(alpha: 0.45),
                          )
                        : null,
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

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      final end = x + dash > size.width ? size.width : x + dash;
      canvas.drawLine(Offset(x, 0), Offset(end, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _TrendLinePainter extends CustomPainter {
  const _TrendLinePainter({
    required this.values,
    required this.maxValue,
    required this.barAreaHeight,
    required this.color,
  });

  final List<double> values;
  final double maxValue;
  final double barAreaHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || maxValue <= 0 || barAreaHeight <= 0) return;

    final line = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final step = size.width / values.length;
    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < values.length; i++) {
      final fraction = values[i] <= 0
          ? 0.0
          : (values[i] / maxValue).clamp(0.0, 1.0);
      final point = Offset(
        step * (i + 0.5),
        size.height - barAreaHeight * fraction,
      );
      points.add(point);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(path, line);
    for (final point in points) {
      canvas.drawCircle(point, 1.8, dot);
    }
  }

  @override
  bool shouldRepaint(_TrendLinePainter oldDelegate) =>
      !listEquals(oldDelegate.values, values) ||
      oldDelegate.maxValue != maxValue ||
      oldDelegate.barAreaHeight != barAreaHeight ||
      oldDelegate.color != color;
}
