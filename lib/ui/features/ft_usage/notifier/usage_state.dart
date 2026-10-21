import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/models/bill_record.dart';
import 'package:flutter/foundation.dart';

enum UsageFilter { monthly, yearly }

const Object _unset = Object();

@immutable
class MonthlyUsage {
  const MonthlyUsage({
    required this.month,
    required this.year,
    required this.kwh,
    required this.bill,
    this.isEstimated = false,
  });

  final String month;
  final int year;
  final double kwh;
  final double bill;
  final bool isEstimated;

  String get monthYear => '$month $year';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonthlyUsage &&
        other.month == month &&
        other.year == year &&
        other.kwh == kwh &&
        other.bill == bill &&
        other.isEstimated == isEstimated;
  }

  @override
  int get hashCode => Object.hash(month, year, kwh, bill, isEstimated);
}

@immutable
class UsageState {
  const UsageState({
    this.filter = UsageFilter.monthly,
    this.monthlyData = const [],
    this.billHistory = const [],
    this.currentKwh = 0,
    this.currentBill = 0,
    this.currentMonthLabel = '',
    this.monthlyBudget = 0,
    this.readingCount = 0,
    this.lastReadingDate,
    this.lastReadingKwh = 0,
  });

  final UsageFilter filter;
  final List<MonthlyUsage> monthlyData;
  final List<BillRecord> billHistory;
  final double currentKwh;
  final double currentBill;
  final String currentMonthLabel;
  final double monthlyBudget;

  /// Number of saved readings. One reading is only a baseline; a second
  /// reading is needed before any usage can be calculated.
  final int readingCount;

  /// Date of the latest saved reading, if any.
  final DateTime? lastReadingDate;

  /// Usage measured by the latest reading, since the previous reading.
  final double lastReadingKwh;

  bool get hasUsage =>
      monthlyData.any((month) => month.kwh > 0) || billHistory.isNotEmpty;

  List<ChargeLineItem> get chargeBreakdown =>
      TariffRates.breakdownFor(currentKwh, billingMonth: DateTime.now());

  List<MonthlyUsage> get chartData {
    if (filter == UsageFilter.yearly) {
      return monthlyData;
    }

    return monthlyData.length > 6
        ? monthlyData.sublist(monthlyData.length - 6)
        : monthlyData;
  }

  double get chartMaxKwh {
    if (chartData.isEmpty) return 100;
    return chartData.map((e) => e.kwh).reduce((a, b) => a > b ? a : b);
  }

  UsageState copyWith({
    UsageFilter? filter,
    List<MonthlyUsage>? monthlyData,
    List<BillRecord>? billHistory,
    double? currentKwh,
    double? currentBill,
    String? currentMonthLabel,
    double? monthlyBudget,
    int? readingCount,
    Object? lastReadingDate = _unset,
    double? lastReadingKwh,
  }) {
    return UsageState(
      filter: filter ?? this.filter,
      monthlyData: monthlyData ?? this.monthlyData,
      billHistory: billHistory ?? this.billHistory,
      currentKwh: currentKwh ?? this.currentKwh,
      currentBill: currentBill ?? this.currentBill,
      currentMonthLabel: currentMonthLabel ?? this.currentMonthLabel,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      readingCount: readingCount ?? this.readingCount,
      lastReadingDate: identical(lastReadingDate, _unset)
          ? this.lastReadingDate
          : lastReadingDate as DateTime?,
      lastReadingKwh: lastReadingKwh ?? this.lastReadingKwh,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsageState &&
        other.filter == filter &&
        listEquals(other.monthlyData, monthlyData) &&
        listEquals(other.billHistory, billHistory) &&
        other.currentKwh == currentKwh &&
        other.currentBill == currentBill &&
        other.currentMonthLabel == currentMonthLabel &&
        other.monthlyBudget == monthlyBudget &&
        other.readingCount == readingCount &&
        other.lastReadingDate == lastReadingDate &&
        other.lastReadingKwh == lastReadingKwh;
  }

  @override
  int get hashCode => Object.hash(
    filter,
    Object.hashAll(monthlyData),
    Object.hashAll(billHistory),
    currentKwh,
    currentBill,
    currentMonthLabel,
    monthlyBudget,
    readingCount,
    lastReadingDate,
    lastReadingKwh,
  );
}
