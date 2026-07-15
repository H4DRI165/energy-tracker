import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:energy_tracker/ui/features/ft_add_meter_reading/notifier/add_meter_reading_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('treats the first meter reading as a zero-usage baseline', () {
    const state = AddReadingPageState(
      isLoadingLastReading: false,
      currentReading: 500,
    );

    expect(state.isBaselineReading, isTrue);
    expect(state.usageKwh, 0);
    expect(state.hasUsage, isFalse);
    expect(state.canSave, isTrue);
  });

  test('calculates usage only when the new meter value increases', () {
    final state = AddReadingPageState(
      isLoadingLastReading: false,
      lastReading: 500,
      lastReadingDate: DateTime(2026, 6),
      currentReading: 700,
    );

    expect(state.usageKwh, 200);
    expect(state.hasUsage, isTrue);
    expect(state.currentTier(TariffType.commercial), 1);
    expect(state.estimatedBill(TariffType.commercial), closeTo(100.62976, 0.000001));
  });

  test('never reports negative usage and blocks saving with a validation error', () {
    final state = AddReadingPageState(
      isLoadingLastReading: false,
      lastReading: 700,
      lastReadingDate: DateTime(2026, 6),
      currentReading: 500,
      readingError: 'Meter reading cannot decrease',
    );

    expect(state.usageKwh, 0);
    expect(state.canSave, isFalse);
  });

  test('uses domestic EEI bands for the current tier', () {
    final state = AddReadingPageState(
      isLoadingLastReading: false,
      lastReading: 100,
      lastReadingDate: DateTime(2026, 6),
      currentReading: 1100,
    );

    expect(state.currentTier(TariffType.domestic), 17);
    expect(state.currentEeiBand.number, 17);
  });
}
