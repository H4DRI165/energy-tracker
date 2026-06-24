import 'package:energy_tracker/extensions/tariff_type_extension.dart';

class BillRecord {
  const BillRecord({
    required this.id,
    required this.monthYear,
    required this.kwh,
    required this.amount,
    required this.isPaid,
    required this.date,
    required this.tariffType,
  });

  final String id;
  final String monthYear;
  final double kwh;
  final double amount;
  final bool isPaid;
  final DateTime date;
  final TariffType tariffType;

  BillRecord copyWith({
    String? id,
    String? monthYear,
    double? kwh,
    double? amount,
    bool? isPaid,
    DateTime? date,
    TariffType? tariffType,
  }) {
    return BillRecord(
      id: id ?? this.id,
      monthYear: monthYear ?? this.monthYear,
      kwh: kwh ?? this.kwh,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      date: date ?? this.date,
      tariffType: tariffType ?? this.tariffType,
    );
  }
}
