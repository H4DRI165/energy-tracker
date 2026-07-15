import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:energy_tracker/services/billing/bill_recalculation_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late BillRecalculationService service;
  late CollectionReference<Map<String, dynamic>> readings;
  late DocumentReference<Map<String, dynamic>> billDoc;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = BillRecalculationService(firestore);

    readings = firestore
        .collection('users')
        .doc('user-1')
        .collection('readings');

    billDoc = firestore
        .collection('users')
        .doc('user-1')
        .collection('bills')
        .doc('2026-07');
  });

  test('deletes a monthly bill when that month has no readings', () async {
    // Pre-seed a bill doc so we can prove it actually gets deleted,
    // not just "never existed".
    await billDoc.set({'kwh': 999.0});

    await service.recalculateMonth(
      'user-1',
      DateTime(2026, 7, 15),
      TariffType.domestic,
    );

    final snapshot = await billDoc.get();
    expect(snapshot.exists, isFalse);
  });

  test('sums readings and stores the calculated monthly bill', () async {
    await readings.add({
      'kwh': 80.0,
      'tariffType': 'commercial',
      'date': Timestamp.fromDate(DateTime(2026, 7, 10)),
    });
    await readings.add({
      'kwh': 120.0,
      'tariffType': 'commercial',
      'date': Timestamp.fromDate(DateTime(2026, 7, 20)),
    });

    // Reading outside the month — should NOT be included in the sum.
    await readings.add({
      'kwh': 500.0,
      'tariffType': 'commercial',
      'date': Timestamp.fromDate(DateTime(2026, 8)),
    });

    await service.recalculateMonth(
      'user-1',
      DateTime(2026, 7, 15),
      TariffType.domestic,
    );

    final snapshot = await billDoc.get();
    final data = snapshot.data();

    expect(data, isNotNull);
    expect(data!['kwh'], 200.0);
    expect(data['tariffType'], 'commercial');
    expect(data['tier'], 1);
    expect(data['amount'], closeTo(100.62976, 0.000001));
    expect(data['date'], Timestamp.fromDate(DateTime(2026, 7)));
  });
}
