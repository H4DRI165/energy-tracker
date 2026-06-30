import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/extensions/tariff_type_extension.dart';

/// A lightweight snapshot of a reading document, used internally by
/// [ReadingChainService] when resolving neighbors.
class AdjacentReading {
  const AdjacentReading({
    required this.id,
    required this.reading,
    required this.date,
    required this.notes,
    required this.estimatedBill,
    required this.tariffType,
  });

  factory AdjacentReading.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return AdjacentReading(
      id: doc.id,
      reading: (data['reading'] as num?)?.toDouble() ?? 0,
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'] as String? ?? '',
      estimatedBill: (data['estimatedBill'] as num?)?.toDouble() ?? 0,
      tariffType: TariffTypeX.fromValue(
        data['tariffType'] as String? ?? TariffType.domestic.value,
      ),
    );
  }

  final String id;
  final double reading;
  final DateTime date;
  final String notes;
  final double estimatedBill;
  final TariffType tariffType;
}

/// Result of fixing up a reading whose chain position changed (because a
/// neighbouring reading was inserted, edited, or deleted).
class ChainFixResult {
  const ChainFixResult({
    required this.readingId,
    required this.newKwh,
    required this.newTier,
    required this.date,
    required this.tariffType,
  });

  final String readingId;
  final double newKwh;
  final int newTier;
  final DateTime date;
  final TariffType tariffType;
}

/// Resolves true previous/next readings for a given date, globally across
/// all months — not scoped to whatever happens to be loaded in memory —
/// and computes corrected kwh/tier for a reading whose chain position
/// has changed.
class ReadingChainService {
  ReadingChainService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _readingsCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('readings');

  /// The reading immediately before [date], or null if [date] is the
  /// earliest reading on file.
  Future<AdjacentReading?> findPrevious(String uid, DateTime date) async {
    final snap = await _readingsCol(uid)
        .where('date', isLessThan: Timestamp.fromDate(date))
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : AdjacentReading.fromDoc(snap.docs.first);
  }

  /// The reading immediately after [date], or null if [date] is the
  /// latest reading on file.
  Future<AdjacentReading?> findNext(String uid, DateTime date) async {
    final snap = await _readingsCol(uid)
        .where('date', isGreaterThan: Timestamp.fromDate(date))
        .orderBy('date')
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : AdjacentReading.fromDoc(snap.docs.first);
  }

  /// Computes what [next]'s kwh/tier *should* be, given [previousValue]
  /// (the meter value it should now be measured against). Pass `null`
  /// for [previousValue] if [next] has become the new baseline (i.e.
  /// there is no reading before it at all).
  ChainFixResult computeFix(AdjacentReading next, double? previousValue) {
    final double newKwh;
    if (previousValue == null) {
      newKwh = 0.0;
    } else {
      final delta = next.reading - previousValue;
      if (delta < 0) {
        throw StateError('Next reading cannot be lower than previous reading');
      }
      newKwh = delta;
    }
    final newTier = TariffRates.getTier(newKwh, next.tariffType);

    return ChainFixResult(
      readingId: next.id,
      newKwh: newKwh,
      newTier: newTier,
      date: next.date,
      tariffType: next.tariffType,
    );
  }

  /// Writes a [ChainFixResult] to the reading document. Caller is
  /// responsible for recalculating any affected month's bill afterward.
  void applyFix(WriteBatch batch, String uid, ChainFixResult fix) {
    batch.update(_readingsCol(uid).doc(fix.readingId), {
      'kwh': fix.newKwh,
      'tier': fix.newTier,
    });
  }
}
