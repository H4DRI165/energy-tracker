import 'package:energy_tracker/models/domestic_tariff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DomesticTariff', () {
    test('fallback is valid and covers the current rates', () {
      final tariff = DomesticTariff.fallback;

      expect(tariff.isValid, isTrue);
      expect(tariff.energySenPerKwh, 27.03);
      expect(tariff.protectionThresholdKwh(DateTime(2026, 10)), 800);
      expect(tariff.protectionThresholdKwh(DateTime(2027, 1)), 600);
      expect(tariff.afaSenPerKwh(DateTime(2026, 10)), 3.61);
      expect(tariff.afaSenPerKwh(DateTime(2030, 1)), isNull);
      expect(tariff.eeiSenPerKwh(200), 25);
      expect(tariff.eeiSenPerKwh(1000), 0.5);
      expect(tariff.eeiSenPerKwh(1001), 0);
    });

    test('round-trips through JSON', () {
      final decoded = DomesticTariff.fromJson(
        DomesticTariff.fallback.toJson(),
      );

      expect(decoded.isValid, isTrue);
      expect(decoded.energySenPerKwh, 27.03);
      expect(decoded.networkSenPerKwh, 12.85);
      expect(decoded.eeiBands.length, 17);
      expect(decoded.afaByMonth.length, 19);
      expect(decoded.protectionPeriods.single.thresholdKwh, 800);
    });

    test('rejects a schedule with unsorted EEI bands', () {
      final decoded = DomesticTariff.fromJson({
        ...DomesticTariff.fallback.toJson(),
        'eeiBands': [
          {'maxKwh': 300, 'senPerKwh': 20},
          {'maxKwh': 200, 'senPerKwh': 25},
        ],
      });

      expect(decoded.isValid, isFalse);
    });

    test('accepts numeric AFA values as well as objects', () {
      final decoded = DomesticTariff.fromJson({
        ...DomesticTariff.fallback.toJson(),
        'afaByMonth': {'2026-10': 3.61},
      });

      expect(decoded.afaSenPerKwh(DateTime(2026, 10)), 3.61);
      expect(decoded.afaRate(DateTime(2026, 10))?.status, 'final');
    });
  });
}
