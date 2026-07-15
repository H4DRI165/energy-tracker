import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TariffRates', () {
    test('returns zero for zero or negative consumption', () {
      expect(TariffRates.calculateDomestic(0), 0);
      expect(TariffRates.calculateDomestic(-1), 0);
      expect(TariffRates.calculateCommercial(0), 0);
      expect(TariffRates.calculateCommercial(-1), 0);
    });

    test('calculates the verified commercial 200 kWh bill', () {
      expect(
        TariffRates.calculate(200, TariffType.commercial),
        closeTo(100.62976, 0.000001),
      );
    });

    test('applies the domestic EEI rebate at 200 kWh', () {
      expect(
        TariffRates.calculate(200, TariffType.domestic),
        closeTo(38.86, 0.000001),
      );
    });

    test('uses the expected tier for each tariff type', () {
      expect(TariffRates.getTier(200, TariffType.commercial), 1);
      expect(TariffRates.getTier(201, TariffType.commercial), 2);
      expect(TariffRates.getTier(200, TariffType.domestic), 1);
      expect(TariffRates.getTier(1001, TariffType.domestic), 0);
    });

    test('only applies domestic AFA above 600 kWh', () {
      expect(TariffRates.afaApplies(TariffType.domestic, 600), isFalse);
      expect(TariffRates.afaApplies(TariffType.domestic, 601), isTrue);
      expect(TariffRates.afaApplies(TariffType.commercial, 1), isTrue);
    });

    test('uses the expected domestic EEI band boundaries', () {
      expect(TariffRates.getEeiBand(200).number, 1);
      expect(TariffRates.getEeiBand(200.1).number, 2);
      expect(TariffRates.getEeiBand(1000).number, 17);
      expect(TariffRates.getEeiBand(1000.1).number, 0);
    });

    test('includes retail and SST only above 600 domestic kWh', () {
      final at600 = TariffRates.domesticBreakdown(600);
      final at601 = TariffRates.domesticBreakdown(601);

      expect(at600.any((line) => line.label == 'Retail'), isFalse);
      expect(at600.any((line) => line.label == 'Service Tax (SST)'), isFalse);
      expect(at601.any((line) => line.label == 'Retail'), isTrue);
      expect(at601.any((line) => line.label == 'Service Tax (SST)'), isTrue);
    });

    test('makes every breakdown total equal the calculated bill', () {
      for (final kwh in [200.0, 600.0, 601.0, 1000.0, 1501.0]) {
        final breakdown = TariffRates.domesticBreakdown(kwh);
        final total = breakdown.fold<double>(
          0,
          (sum, line) => sum + line.amount,
        );

        expect(total, closeTo(TariffRates.calculateDomestic(kwh), 0.000001));
      }
    });
  });
}
