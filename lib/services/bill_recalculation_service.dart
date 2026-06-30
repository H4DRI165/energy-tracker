import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/extensions/tariff_type_extension.dart';

class BillRecalculationService {
  BillRecalculationService(this._firestore);

  final FirebaseFirestore _firestore;

  String monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  /// Recomputes and writes the bill document for [date]'s month, summing
  /// whatever readings currently exist in Firestore for that month.
  /// Deletes the bill doc entirely if no readings remain.
  Future<void> recalculateMonth(
    String uid,
    DateTime date,
    TariffType tariffType,
  ) async {
    final key = monthKey(date);
    final start = DateTime(date.year, date.month);
    final end = DateTime(date.year, date.month + 1);

    final readingsSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('readings')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    final billRef =
        _firestore.collection('users').doc(uid).collection('bills').doc(key);

    if (readingsSnap.docs.isEmpty) {
      await billRef.delete();
      return;
    }

    final totalKwh = readingsSnap.docs.fold<double>(
      0,
      (total, doc) => total + ((doc.data()['kwh'] as num?)?.toDouble() ?? 0),
    );

    await billRef.set(
      {
        'kwh': totalKwh,
        'amount': TariffRates.calculate(totalKwh, tariffType),
        'tier': TariffRates.getTier(totalKwh, tariffType),
        'tariffType': tariffType.value,
        'date': Timestamp.fromDate(start),
      },
      SetOptions(merge: true),
    );
  }
}
