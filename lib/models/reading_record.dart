class ReadingRecord {
  const ReadingRecord({
    required this.id,
    required this.reading,
    required this.kwh,
    required this.date,
    required this.notes,
    required this.estimatedBill,
    required this.tier,
  });

  final String id;
  final double reading;
  final double kwh;
  final DateTime date;
  final String notes;
  final double estimatedBill;
  final int tier;

  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String get tierLabel {
    switch (tier) {
      case 1:
        return 'Tier 1 — 21.8 sen/kWh';
      case 2:
        return 'Tier 2 — 33.4 sen/kWh';
      case 3:
        return 'Tier 3 — 51.6 sen/kWh';
      default:
        return 'Tier 4 — 54.6 sen/kWh';
    }
  }
}
