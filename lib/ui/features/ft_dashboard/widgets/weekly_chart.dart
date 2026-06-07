import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_state.dart';
import 'package:flutter/material.dart';

class WeeklyChart extends StatelessWidget {
  const WeeklyChart({
    required this.weeklyUsage,
    super.key,
  });

  final List<DailyUsage> weeklyUsage;

  @override
  Widget build(BuildContext context) {
    final maxKwh = weeklyUsage.isEmpty
        ? 1.0
        : weeklyUsage.map((e) => e.kwh).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7-Day Usage',
                style:
                    AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
              ),
              Text('kWh/day', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: weeklyUsage.isEmpty
                ? Center(
                    child: Text(
                      'No readings yet',
                      style: AppTextStyles.caption,
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: weeklyUsage.map((day) {
                      final heightFraction = maxKwh > 0
                          ? (day.kwh / maxKwh).clamp(0.05, 1.0)
                          : 0.05;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _Bar(
                            heightFraction: heightFraction,
                            isToday: day.isToday,
                            kwh: day.kwh,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 6),
          if (weeklyUsage.isNotEmpty)
            Row(
              children: weeklyUsage.map(
                (day) {
                  return Expanded(
                    child: Text(
                      day.label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        color: day.isToday ? AppColors.accent : AppColors.text3,
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.heightFraction,
    required this.isToday,
    required this.kwh,
  });

  final double heightFraction;
  final bool isToday;
  final double kwh;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: heightFraction),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return FractionallySizedBox(
          heightFactor: value,
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
              gradient: isToday
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.accent,
                        Color(0x6600D4AA),
                      ],
                    )
                  : null,
              color: isToday ? null : AppColors.surface3,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
              boxShadow: isToday
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.30),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      },
    );
  }
}
