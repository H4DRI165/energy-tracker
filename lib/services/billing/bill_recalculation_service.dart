import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/models/reading_record.dart';
import 'package:energy_tracker/services/billing/usage_allocation_service.dart';

class BillRecalculationService {
  BillRecalculationService(this._firestore);

  final FirebaseFirestore _firestore;

  String monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  /// Recomputes every bill month overlapping [from]–[to].
  ///
  /// Readings are interval deltas, so a reading can contribute to more than
  /// one month. Loading all readings keeps long gaps (for example a user who
  /// re-installs after six months) correctly distributed instead of dumped
  /// into a single month.
  Future<void> recalculateRange(
    String uid,
    DateTime from,
    DateTime to,
  ) async {
    final start = DateTime(from.year, from.month);
    final end = DateTime(to.year, to.month);
    if (end.isBefore(start)) return;

    final readingsSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('readings')
        .orderBy('date')
        .get();

    final readings = readingsSnap.docs
        .map((doc) => ReadingRecord.fromDoc(doc.id, doc.data()))
        .toList();

    // A bill is for the whole calendar month, regardless of which day was
    // passed in. Include the end month in full.
    final allocations = UsageAllocationService.monthly(
      readings: readings,
      from: start,
      to: end,
      includeFullEndMonth: true,
    );

    final batch = _firestore.batch();
    for (final allocation in allocations) {
      final month = DateTime(allocation.year, allocation.month);
      final ref = _firestore
          .collection('users')
          .doc(uid)
          .collection('bills')
          .doc(monthKey(month));

      if (allocation.kwh <= 0) {
        batch.delete(ref);
        continue;
      }

      batch.set(
        ref,
        {
          'kwh': allocation.kwh,
          'amount': TariffRates.calculate(
            allocation.kwh,
            billingMonth: month,
          ),
          'tier': TariffRates.getTier(allocation.kwh),
          'isEstimated': allocation.isEstimated,
          'date': Timestamp.fromDate(month),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  /// Convenience wrapper for a single month.
  Future<void> recalculateMonth(String uid, DateTime date) =>
      recalculateRange(uid, date, date);

  /// Rebuilds every bill in the user's history. Useful as a one-off migration
  /// after the interval-allocation change.
  Future<void> recalculateAll(String uid) async {
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('readings')
        .orderBy('date')
        .get();
    if (snap.docs.isEmpty) return;

    final first = (snap.docs.first.data()['date'] as Timestamp).toDate();
    final last = (snap.docs.last.data()['date'] as Timestamp).toDate();
    await recalculateRange(uid, first, last);
  }
}
