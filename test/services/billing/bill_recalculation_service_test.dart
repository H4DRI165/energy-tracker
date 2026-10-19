import 'package:cloud_firestore/cloud_firestore.dart';
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
    );

    final snapshot = await billDoc.get();
    expect(snapshot.exists, isFalse);
  });

  test('spreads a long gap across months and marks them estimated', () async {
    await readings.add({
      'reading': 1000.0,
      'kwh': 0.0,
      'date': Timestamp.fromDate(DateTime(2026, 1)),
    });
    await readings.add({
      'reading': 2200.0,
      'kwh': 1200.0,
      'periodStart': Timestamp.fromDate(DateTime(2026, 1)),
      'date': Timestamp.fromDate(DateTime(2026, 7)),
    });

    await service.recalculateRange(
      'user-1',
      DateTime(2026, 1),
      DateTime(2026, 7),
    );

    final bills = firestore
        .collection('users')
        .doc('user-1')
        .collection('bills');

    var total = 0.0;
    for (var month = 1; month <= 6; month++) {
      final snapshot = await bills.doc('2026-0$month').get();
      final data = snapshot.data();
      expect(data, isNotNull, reason: 'month $month');
      expect(data!['isEstimated'], isTrue);
      total += (data['kwh'] as num).toDouble();
    }
    expect(total, closeTo(1200, 0.000001));
    expect((await bills.doc('2026-07').get()).exists, isFalse);
  });

  test('sums readings and stores the calculated monthly bill', () async {
    await readings.add({
      'kwh': 80.0,
      'date': Timestamp.fromDate(DateTime(2026, 7, 10)),
    });
    await readings.add({
      'kwh': 120.0,
      'date': Timestamp.fromDate(DateTime(2026, 7, 20)),
    });

    await service.recalculateMonth(
      'user-1',
      DateTime(2026, 7, 15),
    );

    final snapshot = await billDoc.get();
    final data = snapshot.data();

    expect(data, isNotNull);
    expect(data!['kwh'], 200.0);
    expect(data['tier'], 1);
    expect(data['amount'], closeTo(38.86, 0.000001));
    expect(data['date'], Timestamp.fromDate(DateTime(2026, 7)));
  });
}
