import 'package:energy_tracker/constants/tariff_rates.dart';

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

  String get tierLabel => TariffRates.getTierPriceKwhLabel(tier);
}
