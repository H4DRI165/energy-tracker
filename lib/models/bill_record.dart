class BillRecord {
  const BillRecord({
    required this.id,
    required this.monthYear,
    required this.kwh,
    required this.amount,
    required this.isPaid,
    required this.date,
  });

  final String id;
  final String monthYear;
  final double kwh;
  final double amount;
  final bool isPaid;
  final DateTime date;
}
