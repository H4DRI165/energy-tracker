import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:energy_tracker/models/bill_record.dart';

enum UsageFilter { monthly, yearly }

class MonthlyUsage {
  const MonthlyUsage({
    required this.month,
    required this.year,
    required this.kwh,
    required this.bill,
    required this.isPaid,
  });

  final String month;
  final int year;
  final double kwh;
  final double bill;
  final bool isPaid;

  String get monthYear => '$month $year';
}

class UsageState {
  const UsageState({
    this.filter = UsageFilter.monthly,
    this.monthlyData = const [],
    this.billHistory = const [],
    this.currentKwh = 0,
    this.currentBill = 0,
    this.currentTariffType = TariffType.domestic,
    this.currentMonthLabel = '',
  });

  final UsageFilter filter;
  final List<MonthlyUsage> monthlyData;
  final List<BillRecord> billHistory;
  final double currentKwh;
  final double currentBill;
  final TariffType currentTariffType;
  final String currentMonthLabel;

  List<TierBreakdown> get tierBreakdown =>
      TariffRates.breakdownFor(currentKwh, currentTariffType);

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
    TariffType? currentTariffType,
    String? currentMonthLabel,
  }) {
    return UsageState(
      filter: filter ?? this.filter,
      monthlyData: monthlyData ?? this.monthlyData,
      billHistory: billHistory ?? this.billHistory,
      currentKwh: currentKwh ?? this.currentKwh,
      currentBill: currentBill ?? this.currentBill,
      currentTariffType: currentTariffType ?? this.currentTariffType,
      currentMonthLabel: currentMonthLabel ?? this.currentMonthLabel,
    );
  }
}
