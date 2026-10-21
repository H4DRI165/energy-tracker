import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum BudgetStatus { normal, warning, exceeded }

@immutable
class DailyUsage {
  const DailyUsage({
    required this.label,
    required this.kwh,
    this.isToday = false,
  });

  final String label;
  final double kwh;
  final bool isToday;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyUsage &&
        other.label == label &&
        other.kwh == kwh &&
        other.isToday == isToday;
  }

  @override
  int get hashCode => Object.hash(label, kwh, isToday);
}

@immutable
class DashboardPageState {
  DashboardPageState({
    this.userName = '',
    this.monthLabel = '',
    this.estimatedBill = 0,
    this.kwhUsed = 0,
    this.monthlyBudget = 150,
    this.dailyAvg = 0,
    EeiBand? currentEeiBand,
    this.daysLeft = 0,
    this.percentageVsLastMonth = 0,
    this.projectedBill,
    this.weeklyUsage = const [],
    this.readingCount = 0,
    this.errorMessage,
  }) : currentEeiBand = currentEeiBand ?? EeiBand.none;

  final String userName;
  final String monthLabel;
  final double estimatedBill;
  final double kwhUsed;
  final double monthlyBudget;
  final double dailyAvg;
  final EeiBand currentEeiBand;
  final int daysLeft;
  final double percentageVsLastMonth;
  final double? projectedBill;
  final List<DailyUsage> weeklyUsage;

  /// Total saved readings; zero means the dashboard has no data to show yet.
  final int readingCount;
  final String? errorMessage;
  static const Object _unset = Object();

  double get budgetUsedPercent =>
      monthlyBudget > 0 ? (estimatedBill / monthlyBudget).clamp(0.0, 1.0) : 0;

  BudgetStatus get budgetStatus {
    if (budgetUsedPercent >= 1.0) return BudgetStatus.exceeded;
    if (budgetUsedPercent >= 0.80) return BudgetStatus.warning;
    return BudgetStatus.normal;
  }

  bool get isOverBudget => budgetStatus == BudgetStatus.exceeded;
  bool get isNearBudget => budgetStatus == BudgetStatus.warning;

  Color get billColor {
    switch (budgetStatus) {
      case BudgetStatus.normal:
        return AppColors.accent;
      case BudgetStatus.warning:
        return AppColors.warn;
      case BudgetStatus.exceeded:
        return AppColors.danger;
    }
  }

  String get budgetStatusLabel {
    final pct = (budgetUsedPercent * 100).toStringAsFixed(0);
    switch (budgetStatus) {
      case BudgetStatus.normal:
        return '$pct% of target · $daysLeft days left';
      case BudgetStatus.warning:
        return '$pct% used · Reduce usage to stay on track';
      case BudgetStatus.exceeded:
        return 'Budget exceeded · '
            'RM ${(estimatedBill - monthlyBudget).toStringAsFixed(2)} over';
    }
  }

  // Recompute from kWh so the colour reflects the active light/dark palette.
  Color get tierColor => TariffRates.getEeiBand(kwhUsed).color;

  String get tierRange => TariffRates.getEeiBand(kwhUsed).kwhRange;

  // Used by StatCardsRow badge.
  String get tierBadgeLabel => TariffRates.getEeiBand(kwhUsed).label;

  String get greetingEmoji {
    switch (budgetStatus) {
      case BudgetStatus.normal:
        return '👋';
      case BudgetStatus.warning:
      case BudgetStatus.exceeded:
        return '⚠️';
    }
  }

  DashboardPageState copyWith({
    String? userName,
    String? monthLabel,
    double? estimatedBill,
    double? kwhUsed,
    double? monthlyBudget,
    double? dailyAvg,
    EeiBand? currentEeiBand,
    int? daysLeft,
    double? percentageVsLastMonth,
    Object? projectedBill = _unset,
    List<DailyUsage>? weeklyUsage,
    int? readingCount,
    Object? errorMessage = _unset,
  }) {
    return DashboardPageState(
      userName: userName ?? this.userName,
      monthLabel: monthLabel ?? this.monthLabel,
      estimatedBill: estimatedBill ?? this.estimatedBill,
      kwhUsed: kwhUsed ?? this.kwhUsed,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      dailyAvg: dailyAvg ?? this.dailyAvg,
      currentEeiBand: currentEeiBand ?? this.currentEeiBand,
      daysLeft: daysLeft ?? this.daysLeft,
      percentageVsLastMonth:
          percentageVsLastMonth ?? this.percentageVsLastMonth,
      projectedBill: identical(projectedBill, _unset)
          ? this.projectedBill
          : projectedBill as double?,
      weeklyUsage: weeklyUsage ?? this.weeklyUsage,
      readingCount: readingCount ?? this.readingCount,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  DashboardPageState merge(DashboardPageState other) {
    // Gate EeiBand on kwhUsed rather than band.number, since number==0
    // is legitimately returned for >1000 kWh usage ("no rebate" band)
    // and would be incorrectly treated as "not set" by the old check.
    final otherHasUsageData = other.kwhUsed != 0;

    return copyWith(
      userName: other.userName.isNotEmpty ? other.userName : null,
      monthlyBudget: other.monthlyBudget != 150 ? other.monthlyBudget : null,
      monthLabel: other.monthLabel.isNotEmpty ? other.monthLabel : null,
      kwhUsed: other.kwhUsed != 0 ? other.kwhUsed : null,
      estimatedBill: other.estimatedBill != 0 ? other.estimatedBill : null,
      currentEeiBand: otherHasUsageData ? other.currentEeiBand : null,
      dailyAvg: other.dailyAvg != 0 ? other.dailyAvg : null,
      daysLeft: other.daysLeft != 0 ? other.daysLeft : null,
      percentageVsLastMonth: other.percentageVsLastMonth != 0
          ? other.percentageVsLastMonth
          : null,
      projectedBill: other.projectedBill ?? projectedBill,
      weeklyUsage: other.weeklyUsage.isNotEmpty ? other.weeklyUsage : null,
      readingCount: other.readingCount != 0 ? other.readingCount : null,
      errorMessage: other.errorMessage ?? errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardPageState &&
        other.userName == userName &&
        other.monthLabel == monthLabel &&
        other.estimatedBill == estimatedBill &&
        other.kwhUsed == kwhUsed &&
        other.monthlyBudget == monthlyBudget &&
        other.dailyAvg == dailyAvg &&
        other.currentEeiBand == currentEeiBand &&
        other.daysLeft == daysLeft &&
        other.percentageVsLastMonth == percentageVsLastMonth &&
        other.projectedBill == projectedBill &&
        listEquals(other.weeklyUsage, weeklyUsage) &&
        other.readingCount == readingCount &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
    userName,
    monthLabel,
    estimatedBill,
    kwhUsed,
    monthlyBudget,
    dailyAvg,
    currentEeiBand,
    daysLeft,
    percentageVsLastMonth,
    projectedBill,
    Object.hashAll(weeklyUsage),
    readingCount,
    errorMessage,
  );
}
