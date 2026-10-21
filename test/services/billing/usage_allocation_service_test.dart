import 'package:energy_tracker/models/reading_record.dart';
import 'package:energy_tracker/services/billing/usage_allocation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ReadingRecord reading({
    required String id,
    required DateTime date,
    required double kwh,
    DateTime? periodStart,
  }) {
    return ReadingRecord(
      id: id,
      reading: 0,
      kwh: kwh,
      date: date,
      notes: '',
      estimatedBill: 0,
      tier: 1,
      periodStart: periodStart,
    );
  }

  group('UsageAllocationService.monthly', () {
    test('keeps normal intervals inside their month', () {
      final allocations = UsageAllocationService.monthly(
        readings: [
          reading(
            id: '1',
            date: DateTime(2026, 7, 10),
            kwh: 80,
            periodStart: DateTime(2026, 7),
          ),
          reading(
            id: '2',
            date: DateTime(2026, 7, 20),
            kwh: 120,
            periodStart: DateTime(2026, 7, 10),
          ),
        ],
        from: DateTime(2026, 7),
        to: DateTime(2026, 7, 31),
      );

      final july = allocations.single;
      expect(july.kwh, closeTo(200, 0.0001));
      expect(july.isEstimated, isFalse);
    });

    test('splits a reading that crosses a month boundary', () {
      final allocations = UsageAllocationService.monthly(
        readings: [
          reading(
            id: '1',
            date: DateTime(2026, 7, 20),
            kwh: 0,
            periodStart: DateTime(2026, 7, 20),
          ),
          reading(
            id: '2',
            date: DateTime(2026, 8, 5),
            kwh: 160,
            periodStart: DateTime(2026, 7, 20),
          ),
        ],
        from: DateTime(2026, 7),
        to: DateTime(2026, 8, 31),
      );

      final july = allocations.firstWhere((a) => a.month == 7);
      final august = allocations.firstWhere((a) => a.month == 8);
      // 12 of 16 days in July, 4 in August.
      expect(july.kwh, closeTo(120, 0.0001));
      expect(august.kwh, closeTo(40, 0.0001));
      expect(july.isEstimated, isFalse);
    });

    test('spreads a six-month gap across the months it covers', () {
      final allocations = UsageAllocationService.monthly(
        readings: [
          reading(
            id: '1',
            date: DateTime(2026),
            kwh: 0,
          ),
          reading(
            id: '2',
            date: DateTime(2026, 7),
            kwh: 1200,
            periodStart: DateTime(2026),
          ),
        ],
        from: DateTime(2026),
        to: DateTime(2026, 7, 31),
      );

      final total = allocations.fold<double>(0, (sum, a) => sum + a.kwh);
      expect(total, closeTo(1200, 0.0001));
      expect(
        allocations.where((a) => a.kwh > 0).every((a) => a.isEstimated),
        isTrue,
      );
      expect(
        allocations.firstWhere((a) => a.month == 7).kwh,
        closeTo(0, 0.0001),
      );
      expect(
        allocations.firstWhere((a) => a.month == 4).kwh,
        closeTo(1200 * 30 / 181, 0.0001),
      );
    });

    test('keeps a same-day reading delta on that day', () {
      final allocations = UsageAllocationService.monthly(
        readings: [
          reading(
            id: '1',
            date: DateTime(2026, 7, 10),
            kwh: 0,
            periodStart: DateTime(2026, 7, 10),
          ),
          reading(
            id: '2',
            date: DateTime(2026, 7, 10),
            kwh: 10,
            periodStart: DateTime(2026, 7, 10),
          ),
        ],
        from: DateTime(2026, 7),
        to: DateTime(2026, 7, 31),
      );

      expect(allocations.single.kwh, closeTo(10, 0.0001));
    });

    test('keeps a legacy first reading in its own month', () {
      final allocations = UsageAllocationService.monthly(
        readings: [
          reading(id: '1', date: DateTime(2026, 7, 10), kwh: 80),
        ],
        from: DateTime(2026, 7),
        to: DateTime(2026, 7, 31),
      );

      expect(allocations.single.kwh, closeTo(80, 0.0001));
    });
  });

  group('UsageAllocationService.dailyKwh', () {
    test('distributes an interval across days and includes the latest day', () {
      final daily = UsageAllocationService.dailyKwh(
        readings: [
          reading(
            id: '1',
            date: DateTime(2026, 7, 10),
            kwh: 100,
            periodStart: DateTime(2026, 7, 5),
          ),
        ],
        from: DateTime(2026, 7, 5),
        to: DateTime(2026, 7, 10),
      );

      expect(daily.length, 6);
      expect(
        daily.values.fold<double>(0, (sum, kwh) => sum + kwh),
        closeTo(100, 0.0001),
      );
      expect(daily['2026-07-05'], closeTo(100 / 6, 0.0001));
      expect(daily['2026-07-10'], closeTo(100 / 6, 0.0001));
    });

    test('puts a same-day reading delta on the reading day', () {
      final daily = UsageAllocationService.dailyKwh(
        readings: [
          reading(
            id: '1',
            date: DateTime(2026, 7, 10),
            kwh: 0,
            periodStart: DateTime(2026, 7, 10),
          ),
          reading(
            id: '2',
            date: DateTime(2026, 7, 10),
            kwh: 10,
            periodStart: DateTime(2026, 7, 10),
          ),
        ],
        from: DateTime(2026, 7, 4),
        to: DateTime(2026, 7, 10),
      );

      expect(daily, {'2026-07-10': 10});
    });
  });
}
