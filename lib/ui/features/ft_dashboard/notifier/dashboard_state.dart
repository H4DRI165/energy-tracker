import 'package:energy_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum BudgetStatus { normal, warning, exceeded }

class DailyUsage {
  const DailyUsage({
    required this.label,
    required this.kwh,
    this.isToday = false,
  });

  final String label;
  final double kwh;
  final bool isToday;
}

class DashboardPageState {
  const DashboardPageState({
    this.userName = '',
    this.monthLabel = '',
    this.estimatedBill = 0,
    this.kwhUsed = 0,
    this.monthlyBudget = 150,
    this.dailyAvg = 0,
    this.currentTier = 1,
    this.daysLeft = 0,
    this.percentageVsLastMonth = 0,
    this.projectedBill,
    this.weeklyUsage = const [],
    this.hasUnreadNotifications = false,
    this.errorMessage,
  });

  final String userName;
  final String monthLabel;
  final double estimatedBill;
  final double kwhUsed;
  final double monthlyBudget;
  final double dailyAvg;
  final int currentTier;
  final int daysLeft;
  final double percentageVsLastMonth;
  final double? projectedBill;
  final List<DailyUsage> weeklyUsage;
  final bool hasUnreadNotifications;
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

  String get tierRange {
    switch (currentTier) {
      case 1:
        return '1–200 kWh';
      case 2:
        return '201–300 kWh';
      case 3:
        return '301–600 kWh';
      default:
        return '600+ kWh';
    }
  }

  String get greetingEmoji {
    switch (budgetStatus) {
      case BudgetStatus.normal:
        return '👋';
      case BudgetStatus.warning:
      case BudgetStatus.exceeded:
        return '⚠️';
    }
  }

  Color get tierColor {
    switch (currentTier) {
      case 1:
        return AppColors.accent;
      case 2:
        return AppColors.warn;
      default:
        return AppColors.danger;
    }
  }

  DashboardPageState copyWith({
    String? userName,
    String? monthLabel,
    double? estimatedBill,
    double? kwhUsed,
    double? monthlyBudget,
    double? dailyAvg,
    int? currentTier,
    int? daysLeft,
    double? percentageVsLastMonth,
    Object? projectedBill = _unset,
    List<DailyUsage>? weeklyUsage,
    bool? hasUnreadNotifications,
    Object? errorMessage = _unset,
  }) {
    return DashboardPageState(
      userName: userName ?? this.userName,
      monthLabel: monthLabel ?? this.monthLabel,
      estimatedBill: estimatedBill ?? this.estimatedBill,
      kwhUsed: kwhUsed ?? this.kwhUsed,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      dailyAvg: dailyAvg ?? this.dailyAvg,
      currentTier: currentTier ?? this.currentTier,
      daysLeft: daysLeft ?? this.daysLeft,
      percentageVsLastMonth:
          percentageVsLastMonth ?? this.percentageVsLastMonth,
      projectedBill: identical(projectedBill, _unset)
          ? this.projectedBill
          : projectedBill as double?,
      weeklyUsage: weeklyUsage ?? this.weeklyUsage,
      hasUnreadNotifications:
          hasUnreadNotifications ?? this.hasUnreadNotifications,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  DashboardPageState merge(DashboardPageState other) {
    return copyWith(
      userName: other.userName.isNotEmpty ? other.userName : null,
      monthlyBudget: other.monthlyBudget != 150 ? other.monthlyBudget : null,
      monthLabel: other.monthLabel.isNotEmpty ? other.monthLabel : null,
      kwhUsed: other.kwhUsed != 0 ? other.kwhUsed : null,
      estimatedBill: other.estimatedBill != 0 ? other.estimatedBill : null,
      currentTier: other.currentTier != 1 ? other.currentTier : null,
      dailyAvg: other.dailyAvg != 0 ? other.dailyAvg : null,
      daysLeft: other.daysLeft != 0 ? other.daysLeft : null,
      percentageVsLastMonth:
          other.percentageVsLastMonth != 0 ? other.percentageVsLastMonth : null,
      projectedBill: other.projectedBill ?? projectedBill,
      weeklyUsage: other.weeklyUsage.isNotEmpty ? other.weeklyUsage : null,
      errorMessage: other.errorMessage ?? errorMessage,
    );
  }
}
