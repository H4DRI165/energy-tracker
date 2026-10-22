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
      selectedDate: DateTime(2026, 6, 20),
      currentReading: 700,
    );

    expect(state.usageKwh, 200);
    expect(state.hasUsage, isTrue);
    expect(state.currentTier, 1);
    expect(state.incrementalCost(), closeTo(38.86, 0.000001));
  });

  test(
    'never reports negative usage and blocks saving with a validation error',
    () {
      final state = AddReadingPageState(
        isLoadingLastReading: false,
        lastReading: 700,
        lastReadingDate: DateTime(2026, 6),
        currentReading: 500,
        readingError: 'Meter reading cannot decrease',
      );

      expect(state.usageKwh, 0);
      expect(state.canSave, isFalse);
    },
  );

  test('blocks saving when surrounding readings could not be loaded', () {
    const state = AddReadingPageState(
      isLoadingLastReading: false,
      currentReading: 500,
      loadError: 'Could not load your previous reading.',
    );

    expect(state.canSave, isFalse);
  });

  test('identifies a reading that matches the previous meter value', () {
    final state = AddReadingPageState(
      isLoadingLastReading: false,
      lastReading: 500,
      lastReadingDate: DateTime(2026, 6, 20, 14, 30),
      selectedDate: DateTime(2026, 6, 20, 18, 5),
      currentReading: 500,
    );

    expect(state.usageKwh, 0);
    expect(state.hasUsage, isFalse);
    expect(state.isSameAsLastReading, isTrue);
  });

  test('includes a same-day reading in the cost preview', () {
    final selectedDate = DateTime(2026, 10, 22);
    final state = AddReadingPageState(
      isLoadingLastReading: false,
      lastReading: 300,
      lastReadingDate: selectedDate,
      selectedDate: selectedDate,
      currentReading: 341,
      monthToDateKwhBeforeThisReading: 300,
    );

    expect(state.usageKwh, 41);
    expect(state.currentMonthUsageShare, 41);
    expect(state.cumulativeKwh, 341);
    expect(state.incrementalCost(), closeTo(15.39, 0.01));
  });

  test('shows the time for readings recorded on the same day', () {
    final state = AddReadingPageState(
      isLoadingLastReading: false,
      lastReading: 500,
      lastReadingDate: DateTime(2026, 6, 20, 14, 30),
      nextReadingDate: DateTime(2026, 6, 20, 18, 5),
      currentReading: 520,
    );

    expect(state.formattedLastReadingDate, 'Jun 20, 2:30 PM');
    expect(state.formattedNextReadingDate, 'Jun 20, 6:05 PM');
  });

  test('keeps date-only labels for backdated readings', () {
    final state = AddReadingPageState(
      isLoadingLastReading: false,
      lastReading: 500,
      lastReadingDate: DateTime(2026, 6, 20),
      currentReading: 520,
    );

    expect(state.formattedLastReadingDate, 'Jun 20');
  });

  test('only previews the current month share of a long gap', () {
    final state = AddReadingPageState(
      isLoadingLastReading: false,
      lastReading: 1000,
      lastReadingDate: DateTime(2026),
      selectedDate: DateTime(2026, 7, 15),
      currentReading: 2200,
    );

    expect(state.usageKwh, 1200);
    expect(state.currentMonthUsageShare, greaterThan(0));
    expect(state.currentMonthUsageShare, lessThan(state.usageKwh));
    expect(state.cumulativeKwh, lessThan(state.usageKwh));
  });

  test('uses domestic EEI bands for the current tier', () {
    final state = AddReadingPageState(
      isLoadingLastReading: false,
      lastReading: 100,
      lastReadingDate: DateTime(2026, 6),
      selectedDate: DateTime(2026, 6, 30),
      currentReading: 1100,
    );

    expect(state.currentTier, 17);
    expect(state.currentEeiBand.number, 17);
  });
}
