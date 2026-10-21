import 'package:cloud_firestore/cloud_firestore.dart';
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
    this.periodStart,
  });

  factory ReadingRecord.fromDoc(String id, Map<String, dynamic> data) {
    final rawPeriodStart = data['periodStart'];
    return ReadingRecord(
      id: id,
      reading: (data['reading'] as num?)?.toDouble() ?? 0,
      kwh: (data['kwh'] as num?)?.toDouble() ?? 0,
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'] as String? ?? '',
      estimatedBill: (data['estimatedBill'] as num?)?.toDouble() ?? 0,
      tier: (data['tier'] as num?)?.toInt() ?? 1,
      periodStart: rawPeriodStart is Timestamp
          ? rawPeriodStart.toDate()
          : rawPeriodStart is String
          ? DateTime.tryParse(rawPeriodStart)
          : null,
    );
  }

  final String id;

  final double reading;

  /// Usage since the previous reading, not usage in [date]'s month.
  final double kwh;
  final DateTime date;
  final String notes;
  final double estimatedBill;
  final int tier;

  /// Start of the interval this reading covers. Null for the first reading.
  final DateTime? periodStart;

  String get formattedDate => date.fullDateLabel;

  String get tierLabel {
    final band = TariffRates.getEeiBand(kwh);
    return band.number == 0 ? 'No rebate' : band.label;
  }
}
