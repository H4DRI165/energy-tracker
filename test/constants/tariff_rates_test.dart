import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/models/domestic_tariff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final oct2026 = DateTime(2026, 10);
  final jan2027 = DateTime(2027, 1);

  setUp(TariffRates.resetToFallback);
  tearDown(TariffRates.resetToFallback);

  group('TariffRates', () {
    test('returns zero for zero or negative consumption', () {
      expect(TariffRates.calculateDomestic(0), 0);
      expect(TariffRates.calculateDomestic(-1), 0);
    });

    test('applies the domestic EEI rebate at 200 kWh', () {
      expect(
        TariffRates.calculateDomestic(200, billingMonth: oct2026),
        closeTo(38.86, 0.000001),
      );
    });

    test('uses EEI bands as the tier proxy', () {
      expect(TariffRates.getTier(200), 1);
      expect(TariffRates.getTier(1001), 0);
    });

    test('uses the expected domestic EEI band boundaries', () {
      expect(TariffRates.getEeiBand(200).number, 1);
      expect(TariffRates.getEeiBand(200.1).number, 2);
      expect(TariffRates.getEeiBand(1000).number, 17);
      expect(TariffRates.getEeiBand(1000.1).number, 0);
    });

    group('domestic protection threshold', () {
      test('is 600 kWh except for Sep–Dec 2026', () {
        expect(TariffRates.protectionThresholdKwh(DateTime(2026, 8)), 600);
        expect(TariffRates.protectionThresholdKwh(DateTime(2026, 9)), 800);
        expect(TariffRates.protectionThresholdKwh(DateTime(2026, 12)), 800);
        expect(TariffRates.protectionThresholdKwh(DateTime(2027, 1)), 600);
      });

      test('waives retail and SST up to 800 kWh in Oct 2026', () {
        final relief = TariffRates.domesticBreakdown(
          700,
          billingMonth: oct2026,
        );
        final normal = TariffRates.domesticBreakdown(
          700,
          billingMonth: jan2027,
        );

        expect(relief.any((line) => line.label == 'Retail'), isFalse);
        expect(
          relief.any((line) => line.label == 'Service Tax (SST)'),
          isFalse,
        );
        expect(normal.any((line) => line.label == 'Retail'), isTrue);
        expect(
          normal.any((line) => line.label == 'Service Tax (SST)'),
          isTrue,
        );
      });

      test('charges AFA only above the month threshold', () {
        expect(
          TariffRates.afaChargeable(700, billingMonth: oct2026),
          isFalse,
        );
        expect(
          TariffRates.afaChargeable(801, billingMonth: oct2026),
          isTrue,
        );
        expect(
          TariffRates.afaChargeable(601, billingMonth: jan2027),
          isTrue,
        );
      });
    });

    group('matches TNB calculator', () {
      test('during the 800 kWh relief period (Oct 2026)', () {
        expect(
          TariffRates.calculateDomestic(700, billingMonth: oct2026),
          closeTo(276.87, 0.0001),
        );
        expect(
          TariffRates.calculateDomestic(800, billingMonth: oct2026),
          closeTo(328.62, 0.0001),
        );
        expect(
          TariffRates.calculateDomestic(801, billingMonth: oct2026),
          closeTo(380.99, 0.0001),
        );
        expect(
          TariffRates.calculateDomestic(900, billingMonth: oct2026),
          closeTo(444.17, 0.0001),
        );
      });

      test('after the relief period (Jan 2027)', () {
        expect(
          TariffRates.calculateDomestic(601, billingMonth: jan2027),
          closeTo(281.96, 0.0001),
        );
        expect(
          TariffRates.calculateDomestic(900, billingMonth: jan2027),
          closeTo(488.47, 0.0001),
        );
        expect(
          TariffRates.calculateDomestic(1600, billingMonth: jan2027),
          closeTo(1066.67, 0.0001),
        );
      });

      test('can exclude AFA explicitly', () {
        expect(
          TariffRates.calculateDomestic(
            900,
            billingMonth: oct2026,
            afaSenPerKwh: 0,
          ),
          closeTo(411.39, 0.0001),
        );
        expect(
          TariffRates.calculateDomestic(
            900,
            billingMonth: jan2027,
            afaSenPerKwh: 0,
          ),
          closeTo(418.34, 0.0001),
        );
      });
    });

    test('makes every breakdown total equal the calculated bill', () {
      for (final month in [oct2026, jan2027]) {
        for (final kwh in [200.0, 601.0, 800.0, 900.0, 1501.0, 1600.0]) {
          final breakdown = TariffRates.domesticBreakdown(
            kwh,
            billingMonth: month,
          );
          final total = breakdown.fold<double>(
            0,
            (sum, line) => sum + line.amount,
          );

          expect(
            total,
            closeTo(
              TariffRates.calculateDomestic(kwh, billingMonth: month),
              0.000001,
            ),
            reason: '$kwh kWh in $month',
          );
        }
      }
    });

    test('configure applies a published schedule', () {
      final custom = DomesticTariff.fallback.copyWith(
        energySenPerKwh: 30,
        energyHighSenPerKwh: 40,
      );

      TariffRates.configure(custom);
      expect(TariffRates.domesticGenerationLow, 0.30);

      TariffRates.configure(DomesticTariff.fallback);
      expect(TariffRates.domesticGenerationLow, 0.2703);
    });

    test('ignores an invalid schedule', () {
      final invalid = DomesticTariff.fallback.copyWith(energySenPerKwh: 0);
      TariffRates.configure(invalid);
      expect(TariffRates.domesticGenerationLow, 0.2703);
    });
  });
}
