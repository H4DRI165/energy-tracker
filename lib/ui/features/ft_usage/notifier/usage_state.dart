import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/models/bill_record.dart';
import 'package:flutter/material.dart';

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

class TierBreakdown {
  const TierBreakdown({
    required this.label,
    required this.kwh,
    required this.rate,
    required this.amount,
    required this.color,
    required this.fillPercent,
  });

  final String label;
  final double kwh;
  final double rate;
  final double amount;
  final Color color;
  final double fillPercent;
}

class UsageState {
  const UsageState({
    this.filter = UsageFilter.monthly,
    this.monthlyData = const [],
    this.billHistory = const [],
    this.currentKwh = 0,
    this.currentBill = 0,
    this.currentMonthLabel = '',
  });

  final UsageFilter filter;
  final List<MonthlyUsage> monthlyData;
  final List<BillRecord> billHistory;
  final double currentKwh;
  final double currentBill;
  final String currentMonthLabel;

  List<TierBreakdown> get tierBreakdown {
    final kwh = currentKwh;
    final breakdowns = <TierBreakdown>[];

    // Tier 1: 1–200 kWh @ 21.8 sen
    if (kwh > 0) {
      final t1Kwh = kwh.clamp(0, 200).toDouble();
      final t1Amount = t1Kwh * 0.218;
      breakdowns.add(
        TierBreakdown(
          label: 'Tier 1 · 1–200 kWh · '
              '${(TariffRates.tier1Rate * 100).toStringAsFixed(1)} sen/kWh',
          kwh: t1Kwh,
          rate: 0.218,
          amount: t1Amount,
          color: const Color(0xFF00D4AA),
          fillPercent: (t1Kwh / 200).clamp(0.0, 1.0),
        ),
      );
    }

    // Tier 2: 201–300 kWh @ 33.4 sen
    if (kwh > 200) {
      final t2Kwh = (kwh - 200).clamp(0, 100).toDouble();
      final t2Amount = t2Kwh * 0.334;
      breakdowns.add(
        TierBreakdown(
          label: 'Tier 2 · 201–300 kWh · '
              '${(TariffRates.tier2Rate * 100).toStringAsFixed(1)} sen/kWh',
          kwh: t2Kwh,
          rate: 0.334,
          amount: t2Amount,
          color: const Color(0xFFFFB020),
          fillPercent: (t2Kwh / 100).clamp(0.0, 1.0),
        ),
      );
    }

    // Tier 3: 301–600 kWh @ 51.6 sen
    if (kwh > 300) {
      final t3Kwh = (kwh - 300).clamp(0, 300).toDouble();
      final t3Amount = t3Kwh * 0.516;
      breakdowns.add(
        TierBreakdown(
          label: 'Tier 3 · 301–600 kWh · '
              '${(TariffRates.tier3Rate * 100).toStringAsFixed(1)} sen/kWh',
          kwh: t3Kwh,
          rate: 0.516,
          amount: t3Amount,
          color: const Color(0xFFFF4D6A),
          fillPercent: (t3Kwh / 300).clamp(0.0, 1.0),
        ),
      );
    }

    // Tier 4: 601+ kWh @ 54.6 sen
    if (kwh > 600) {
      final t4Kwh = kwh - 600;
      final t4Amount = t4Kwh * 0.546;
      breakdowns.add(
        TierBreakdown(
          label: 'Tier 4 · 601+ kWh · '
              '${(TariffRates.tier4Rate * 100).toStringAsFixed(1)} sen/kWh',
          kwh: t4Kwh,
          rate: 0.546,
          amount: t4Amount,
          color: const Color(0xFFFF4D6A),
          fillPercent: (t4Kwh / 400).clamp(0.0, 1.0),
        ),
      );
    }

    return breakdowns;
  }

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
  }) {
    return UsageState(
      filter: filter ?? this.filter,
      monthlyData: monthlyData ?? this.monthlyData,
      billHistory: billHistory ?? this.billHistory,
      currentKwh: currentKwh ?? this.currentKwh,
      currentBill: currentBill ?? this.currentBill,
      currentMonthLabel: currentMonthLabel ?? this.currentMonthLabel,
    );
  }
}
