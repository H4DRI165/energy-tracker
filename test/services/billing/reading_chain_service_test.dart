import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:energy_tracker/services/billing/reading_chain_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late DocumentReference<Map<String, dynamic>> readingDocument;
  late ReadingChainService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = ReadingChainService(firestore);

    readingDocument = firestore
        .collection('users')
        .doc('user-1')
        .collection('readings')
        .doc('reading-2');
  });

  AdjacentReading nextReading({double reading = 700}) => AdjacentReading(
    id: 'reading-2',
    reading: reading,
    date: DateTime(2026, 7, 15),
    notes: 'July reading',
    estimatedBill: 0,
    tariffType: TariffType.commercial,
  );

  test('calculates usage and tier using the previous meter value', () {
    final result = service.computeFix(nextReading(), 500);

    expect(result.readingId, 'reading-2');
    expect(result.newKwh, 200);
    expect(result.newTier, 1);
    expect(result.tariffType, TariffType.commercial);
  });

  test('creates a zero-usage baseline when there is no previous reading', () {
    final result = service.computeFix(nextReading(), null);

    expect(result.newKwh, 0);
    expect(result.newTier, 1);
  });

  test('rejects a next reading lower than its previous reading', () {
    expect(
      () => service.computeFix(nextReading(reading: 499), 500),
      throwsStateError,
    );
  });

  test(
    'writes the corrected kWh and tier through the provided batch',
    () async {
      // Seed the doc so `batch.update` has something to update
      // (real Firestore throws if you `update()` a doc that doesn't exist).
      await readingDocument.set({
        'reading': 700,
        'kwh': 0,
        'tier': 0,
      });

      final batch = firestore.batch();
      final fix = service.computeFix(nextReading(), 500);

      service.applyFix(batch, 'user-1', fix);
      await batch.commit();

      final snapshot = await readingDocument.get();
      final data = snapshot.data();

      expect(data, isNotNull);
      expect(data!['kwh'], 200.0);
      expect(data['tier'], 1);
    },
  );
}
