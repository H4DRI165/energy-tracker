import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/models/domestic_tariff.dart';
import 'package:energy_tracker/services/tariff/tariff_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TariffRepository', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('uses the bundled schedule when Firestore has no document', () async {
      final tariff = await TariffRepository(firestore: firestore).load();

      expect(tariff.id, 'domestic_general');
      expect(tariff.energySenPerKwh, 27.03);
      expect(tariff.protectionThresholdKwh(DateTime(2026, 10)), 800);
      expect(tariff.afaSenPerKwh(DateTime(2026, 10)), 3.61);
    });

    test('prefers a valid published schedule', () async {
      await firestore.doc('tariffs/domestic_general').set({
        'id': 'domestic_general',
        'schemaVersion': 1,
        'formulaVersion': 1,
        'effectiveFrom': '2025-07-01',
        'effectiveTo': '2027-12-31',
        'energySenPerKwh': 30.0,
        'energyHighSenPerKwh': 40.0,
        'highUsageThresholdKwh': 1500,
        'capacitySenPerKwh': 4.55,
        'networkSenPerKwh': 12.85,
        'retailRmPerMonth': 10,
        'kwtbbRate': 0.016,
        'sstRate': 0.08,
        'baseProtectionThresholdKwh': 600,
        'protectionPeriods': <Map<String, dynamic>>[],
        'eeiBands': DomesticTariff.fallback.eeiBands
            .map((band) => band.toJson())
            .toList(),
        'afaByMonth': {
          '2026-10': {'senPerKwh': 9.99, 'status': 'final'},
        },
        'updatedAt': Timestamp.fromDate(DateTime(2026, 10)),
      });

      final tariff = await TariffRepository(firestore: firestore).load();

      expect(tariff.energySenPerKwh, 30);
      expect(tariff.afaSenPerKwh(DateTime(2026, 10)), 9.99);
      expect(tariff.protectionThresholdKwh(DateTime(2026, 10)), 600);
    });

    test('falls back when the published schedule is invalid', () async {
      await firestore.doc('tariffs/domestic_general').set({
        'schemaVersion': 1,
        'energySenPerKwh': 0,
      });

      final tariff = await TariffRepository(firestore: firestore).load();

      expect(tariff.energySenPerKwh, 27.03);
    });
  });
}
