import 'package:energy_tracker/constants/constants.dart';
import 'package:energy_tracker/extensions/date_time_extension.dart';

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

  String get formattedDate => date.fullDateLabel;

  String get tierLabel {
    final band = TariffRates.getEeiBand(kwh);
    return band.number == 0 ? 'No rebate' : band.label;
  }
}
