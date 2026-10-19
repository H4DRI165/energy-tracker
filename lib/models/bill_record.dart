class BillRecord {
  const BillRecord({
    required this.id,
    required this.monthYear,
    required this.kwh,
    required this.amount,
    required this.date,
  });

  final String id;
  final String monthYear;
  final double kwh;
  final double amount;
  final DateTime date;

  BillRecord copyWith({
    String? id,
    String? monthYear,
    double? kwh,
    double? amount,
    DateTime? date,
  }) {
    return BillRecord(
      id: id ?? this.id,
      monthYear: monthYear ?? this.monthYear,
      kwh: kwh ?? this.kwh,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }
}
