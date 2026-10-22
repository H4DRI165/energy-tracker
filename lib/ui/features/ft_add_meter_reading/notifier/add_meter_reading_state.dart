import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/extensions/date_time_extension.dart';
import 'package:energy_tracker/services/billing/usage_allocation_service.dart';

class AddReadingPageState {
  const AddReadingPageState({
    this.isLoadingLastReading = true,
    this.isSaving = false,
    this.lastReading = 0,
    this.lastReadingDate,
    this.nextReading,
    this.nextReadingDate,
    this.currentReading = 0,
    this.monthToDateKwhBeforeThisReading = 0,
    this.selectedDate,
    this.notes = '',
    this.readingError,
    this.loadError,
    this.errorMessage,
  });

  final bool isLoadingLastReading;
  final bool isSaving;
  final double lastReading;
  final DateTime? lastReadingDate;
  final double? nextReading;
  final DateTime? nextReadingDate;
  final double currentReading;
  final double monthToDateKwhBeforeThisReading;
  final DateTime? selectedDate;
  final String notes;
  final String? readingError;
  final String? loadError;
  final String? errorMessage;

  double get usageKwh {
    if (lastReadingDate == null) {
      return 0; // first-ever reading —  no usage to report yet
    }
    final usage = currentReading - lastReading;
    return usage > 0 ? usage : 0;
  }

  double get cumulativeKwh =>
      monthToDateKwhBeforeThisReading + currentMonthUsageShare;

  /// Portion of this reading's interval that falls in the selected month.
  /// A six-month gap no longer looks like six months of usage this month.
  double get currentMonthUsageShare {
    final end = selectedDate ?? DateTime.now();
    final start = lastReadingDate;
    if (start == null) return 0;

    return UsageAllocationService.monthShareForInterval(
      kwh: usageKwh,
      start: start,
      end: end,
      month: end,
    );
  }

  int? get intervalDays {
    final start = lastReadingDate;
    final end = selectedDate;
    if (start == null || end == null) return null;
    return DateTime(
      end.year,
      end.month,
      end.day,
    ).difference(DateTime(start.year, start.month, start.day)).inDays;
  }

  bool get isLongGap =>
      (intervalDays ?? 0) > UsageAllocationService.estimatedIntervalDays;

  double incrementalCost() =>
      TariffRates.calculate(cumulativeKwh, billingMonth: selectedDate) -
      TariffRates.calculate(
        monthToDateKwhBeforeThisReading,
        billingMonth: selectedDate,
      );

  int get currentTier => currentEeiBand.number;

  EeiBand get currentEeiBand => TariffRates.getEeiBand(cumulativeKwh);

  String get tierLabel => currentEeiBand.label;

  bool get hasUsage => usageKwh > 0;

  bool get canSave =>
      !isLoadingLastReading &&
      loadError == null &&
      currentReading > 0 &&
      readingError == null;

  bool get isBaselineReading => lastReadingDate == null;

  bool get isSameAsLastReading =>
      currentReading > 0 &&
      lastReadingDate != null &&
      (currentReading - lastReading).abs() < 0.0001;

  String get formattedLastReadingDate {
    if (lastReadingDate == null) return 'No previous reading';
    return lastReadingDate!.shortDayTimeLabel;
  }

  String get formattedNextReadingDate {
    if (nextReadingDate == null) return '';
    return nextReadingDate!.shortDayTimeLabel;
  }

  static const Object _unset = Object();

  AddReadingPageState copyWith({
    bool? isLoadingLastReading,
    bool? isSaving,
    double? lastReading,
    Object? lastReadingDate = _unset,
    Object? nextReading = _unset,
    Object? nextReadingDate = _unset,
    double? currentReading,
    double? monthToDateKwhBeforeThisReading,
    DateTime? selectedDate,
    String? notes,
    Object? readingError = _unset,
    Object? loadError = _unset,
    Object? errorMessage = _unset,
  }) {
    return AddReadingPageState(
      isLoadingLastReading: isLoadingLastReading ?? this.isLoadingLastReading,
      isSaving: isSaving ?? this.isSaving,
      lastReading: lastReading ?? this.lastReading,
      lastReadingDate: identical(lastReadingDate, _unset)
          ? this.lastReadingDate
          : lastReadingDate as DateTime?,
      nextReading: identical(nextReading, _unset)
          ? this.nextReading
          : nextReading as double?,
      nextReadingDate: identical(nextReadingDate, _unset)
          ? this.nextReadingDate
          : nextReadingDate as DateTime?,
      currentReading: currentReading ?? this.currentReading,
      monthToDateKwhBeforeThisReading:
          monthToDateKwhBeforeThisReading ??
          this.monthToDateKwhBeforeThisReading,
      selectedDate: selectedDate ?? this.selectedDate,
      notes: notes ?? this.notes,
      readingError: identical(readingError, _unset)
          ? this.readingError
          : readingError as String?,
      loadError: identical(loadError, _unset)
          ? this.loadError
          : loadError as String?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
