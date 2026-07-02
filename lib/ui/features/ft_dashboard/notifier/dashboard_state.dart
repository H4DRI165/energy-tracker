import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/extensions/tariff_type_extension.dart';
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
    this.currentEeiBand = const EeiBand(
      number: 0,
      kwhRange: '0 kWh',
      rebateSenPerKwh: 0,
      color: AppColors.accent,
      label: 'No usage',
      description: 'No usage recorded',
    ),
    this.tariffType = TariffType.domestic,
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
  final EeiBand currentEeiBand;
  final TariffType tariffType;
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

  Color get tierColor => tariffType == TariffType.domestic
      ? currentEeiBand.color
      : TariffRates.getTierColor(currentEeiBand.number, TariffType.commercial);

  String get tierRange => tariffType == TariffType.domestic
      ? currentEeiBand.kwhRange
      : TariffRates.getTierKwhRange(
          currentEeiBand.number,
          TariffType.commercial,
        );

  // New — used by StatCardsRow badge.
  String get tierBadgeLabel => tariffType == TariffType.domestic
      ? currentEeiBand.label
      : TariffRates.tierBadgeLabel(
          currentEeiBand.number,
          TariffType.commercial,
        );

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
    TariffType? tariffType,
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
      currentEeiBand: currentEeiBand ?? this.currentEeiBand,
      tariffType: tariffType ?? this.tariffType,
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
    // EeiBand has no clean "default/sentinel" value to compare against,
    // so we check number != 0 (0 means "no usage / not set") as the proxy.
    // See note on merge()'s sentinel pattern in code comments.
    final otherBandIsSet = other.currentEeiBand.number != 0;

    return copyWith(
      userName: other.userName.isNotEmpty ? other.userName : null,
      monthlyBudget: other.monthlyBudget != 150 ? other.monthlyBudget : null,
      monthLabel: other.monthLabel.isNotEmpty ? other.monthLabel : null,
      kwhUsed: other.kwhUsed != 0 ? other.kwhUsed : null,
      estimatedBill: other.estimatedBill != 0 ? other.estimatedBill : null,
      currentEeiBand: otherBandIsSet ? other.currentEeiBand : null,
      tariffType:
          other.tariffType != TariffType.domestic ? other.tariffType : null,
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
