import 'package:energy_tracker/ui/features/ft_usage/notifier/usage_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UsageState.hasUsage', () {
    test('is false when there are no readings', () {
      const state = UsageState();

      expect(state.readingCount, 0);
      expect(state.hasUsage, isFalse);
    });

    test('is false for a single baseline reading', () {
      const state = UsageState(
        readingCount: 1,
        monthlyData: [
          MonthlyUsage(month: 'Oct', year: 2026, kwh: 0, bill: 0),
        ],
      );

      expect(state.hasUsage, isFalse);
    });

    test('is true when an allocation has kWh', () {
      const state = UsageState(
        readingCount: 2,
        monthlyData: [
          MonthlyUsage(month: 'Oct', year: 2026, kwh: 120, bill: 40),
        ],
      );

      expect(state.hasUsage, isTrue);
    });

    test('copyWith preserves the reading count', () {
      const state = UsageState(readingCount: 1);

      expect(state.copyWith(filter: UsageFilter.yearly).readingCount, 1);
    });
  });
}
