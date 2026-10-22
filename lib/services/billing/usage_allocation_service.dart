import 'package:energy_tracker/models/reading_record.dart';

/// Usage attributed to a calendar month.
class MonthlyAllocation {
  const MonthlyAllocation({
    required this.year,
    required this.month,
    required this.kwh,
    required this.isEstimated,
  });

  final int year;
  final int month;
  final double kwh;

  /// True when a month includes usage from an interval longer than a normal
  /// billing cycle, so its split is an estimate rather than a reading.
  final bool isEstimated;

  DateTime get monthStart => DateTime(year, month);
}

/// Turns reading-to-reading deltas into calendar-month and calendar-day usage.
///
/// A reading's [ReadingRecord.kwh] is an interval delta. The interval starts
/// at [ReadingRecord.periodStart] (or the previous reading date for legacy
/// documents) and ends at [ReadingRecord.date]. Usage is spread across the
/// months the interval overlaps, proportionally to the number of days.
class UsageAllocationService {
  const UsageAllocationService._();

  /// Intervals longer than this are treated as estimated. A normal monthly
  /// reading is roughly 28–31 days; 35 gives some slack for late readings.
  static const int estimatedIntervalDays = 35;

  static List<MonthlyAllocation> monthly({
    required List<ReadingRecord> readings,
    required DateTime from,
    required DateTime to,
    bool includeFullEndMonth = false,
  }) {
    final fromDate = _dateOnly(from);
    final toDate = _dateOnly(to);
    final clipEnd = includeFullEndMonth
        ? DateTime(toDate.year, toDate.month + 1)
        : toDate;
    final totals = <String, _MonthAccumulator>{};
    final sorted = [...readings]..sort((a, b) => a.date.compareTo(b.date));
    DateTime? previousDate;

    for (final reading in sorted) {
      final end = _dateOnly(reading.date);
      final start = _intervalStart(reading, previousDate, end);
      previousDate = end;

      if (start == null || reading.kwh <= 0) {
        continue;
      }

      // Same-day readings have a zero-length interval. Their delta belongs
      // to that day/month; spreading it from the start of the month would
      // make a 10 kWh test entry look like ~0.5 kWh/day for weeks.
      if (!end.isAfter(start)) {
        final key = _monthKey(end);
        totals.putIfAbsent(key, _MonthAccumulator.new).kwh += reading.kwh;
        continue;
      }

      final intervalDays = end.difference(start).inDays;
      if (intervalDays <= 0) continue;

      final estimated = intervalDays > estimatedIntervalDays;
      final clippedStart = start.isBefore(fromDate) ? fromDate : start;
      final clippedEnd = end.isAfter(clipEnd) ? clipEnd : end;
      if (!clippedEnd.isAfter(clippedStart)) continue;

      var month = DateTime(clippedStart.year, clippedStart.month);
      while (month.isBefore(clippedEnd)) {
        final monthEnd = DateTime(month.year, month.month + 1);
        final overlapStart = clippedStart.isAfter(month) ? clippedStart : month;
        final overlapEnd = clippedEnd.isBefore(monthEnd)
            ? clippedEnd
            : monthEnd;
        final overlapDays = overlapEnd.difference(overlapStart).inDays;

        if (overlapDays > 0) {
          final key = _monthKey(month);
          final acc = totals.putIfAbsent(key, _MonthAccumulator.new);
          acc
            ..kwh += reading.kwh * overlapDays / intervalDays
            ..isEstimated = acc.isEstimated || estimated;
        }

        month = DateTime(month.year, month.month + 1);
      }
    }

    final result = <MonthlyAllocation>[];
    var month = DateTime(fromDate.year, fromDate.month);
    final lastMonth = DateTime(toDate.year, toDate.month);
    while (!month.isAfter(lastMonth)) {
      final acc = totals[_monthKey(month)];
      result.add(
        MonthlyAllocation(
          year: month.year,
          month: month.month,
          kwh: acc?.kwh ?? 0,
          isEstimated: acc?.isEstimated ?? false,
        ),
      );
      month = DateTime(month.year, month.month + 1);
    }
    return result;
  }

  /// Current-month share of one reading interval.
  ///
  /// Same-day intervals are zero-length and belong entirely to the reading
  /// month, matching [monthly]. Longer intervals use the same day-overlap
  /// split as [monthly].
  static double monthShareForInterval({
    required double kwh,
    required DateTime start,
    required DateTime end,
    required DateTime month,
  }) {
    if (kwh <= 0) return 0;

    final startDate = _dateOnly(start);
    final endDate = _dateOnly(end);
    if (!endDate.isAfter(startDate)) {
      return _sameMonth(endDate, month) ? kwh : 0;
    }

    final intervalDays = endDate.difference(startDate).inDays;
    if (intervalDays <= 0) return 0;

    final monthStart = DateTime(month.year, month.month);
    final monthEnd = DateTime(month.year, month.month + 1);
    final overlapStart = startDate.isAfter(monthStart) ? startDate : monthStart;
    final overlapEnd = endDate.isBefore(monthEnd) ? endDate : monthEnd;
    final overlapDays = overlapEnd.difference(overlapStart).inDays;
    if (overlapDays <= 0) return 0;

    return kwh * overlapDays / intervalDays;
  }

  /// Daily kWh for compact charts. Days without usage are omitted.
  static Map<String, double> dailyKwh({
    required List<ReadingRecord> readings,
    required DateTime from,
    required DateTime to,
  }) {
    final fromDate = _dateOnly(from);
    final toDate = _dateOnly(to);
    final result = <String, double>{};
    final sorted = [...readings]..sort((a, b) => a.date.compareTo(b.date));
    DateTime? previousDate;

    for (var i = 0; i < sorted.length; i++) {
      final reading = sorted[i];
      final isLatest = i == sorted.length - 1;
      final end = _dateOnly(reading.date);
      final start = _intervalStart(reading, previousDate, end);
      previousDate = end;

      if (start == null || reading.kwh <= 0) {
        continue;
      }

      // Same-day readings: the delta belongs to the reading day itself.
      if (!end.isAfter(start)) {
        if (end.isBefore(fromDate) || end.isAfter(toDate)) continue;
        final key = _dayKey(end);
        result[key] = (result[key] ?? 0) + reading.kwh;
        continue;
      }

      final intervalDays = end.difference(start).inDays;
      if (intervalDays <= 0) continue;

      // The latest interval has no following reading, so include its end day.
      // This prevents "Today" from showing 0 simply because the interval is
      // treated as half-open. Historical intervals stay half-open so the
      // boundary day is not counted by both neighboring readings.
      final allocationEnd = isLatest ? end.add(const Duration(days: 1)) : end;
      final allocationDays = isLatest ? intervalDays + 1 : intervalDays;
      final clippedStart = start.isBefore(fromDate) ? fromDate : start;
      final windowEnd = toDate.add(const Duration(days: 1));
      final clippedEnd = allocationEnd.isAfter(windowEnd)
          ? windowEnd
          : allocationEnd;
      if (!clippedEnd.isAfter(clippedStart)) continue;

      final perDay = reading.kwh / allocationDays;
      for (
        var day = clippedStart;
        day.isBefore(clippedEnd);
        day = DateTime(day.year, day.month, day.day + 1)
      ) {
        final key = _dayKey(day);
        result[key] = (result[key] ?? 0) + perDay;
      }
    }
    return result;
  }

  static DateTime? _intervalStart(
    ReadingRecord reading,
    DateTime? previousDate,
    DateTime end,
  ) {
    final explicit = reading.periodStart == null
        ? null
        : _dateOnly(reading.periodStart!);
    if (explicit != null && !explicit.isAfter(end)) return explicit;
    if (previousDate != null && !previousDate.isAfter(end)) {
      return previousDate;
    }

    // Legacy first reading with a non-zero delta: keep it in its own month.
    if (reading.kwh > 0) return DateTime(end.year, end.month);
    return null;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static String _monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  static String _dayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class _MonthAccumulator {
  double kwh = 0;
  bool isEstimated = false;
}
