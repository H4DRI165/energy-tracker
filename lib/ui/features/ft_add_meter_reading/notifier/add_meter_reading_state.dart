import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/extensions/date_time_extension.dart';
import 'package:energy_tracker/extensions/tariff_type_extension.dart';

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
  final String? errorMessage;

  double get usageKwh {
    if (lastReadingDate == null) {
      return 0; // first-ever reading —  no usage to report yet
    }
    final usage = currentReading - lastReading;
    return usage > 0 ? usage : 0;
  }

  double get cumulativeKwh => monthToDateKwhBeforeThisReading + usageKwh;

  double incrementalCost(TariffType tariffType) =>
      TariffRates.calculate(cumulativeKwh, tariffType) -
      TariffRates.calculate(monthToDateKwhBeforeThisReading, tariffType);

  // For domestic, returns the EEI band number rather than the old usage tier.
  // For commercial, still returns the 2-tier int (unchanged tariff structure).
  int currentTier(TariffType tariffType) => tariffType == TariffType.domestic
      ? currentEeiBand.number
      : TariffRates.getTier(cumulativeKwh, TariffType.commercial);

  EeiBand get currentEeiBand => TariffRates.getEeiBand(cumulativeKwh);

  String tierLabel(TariffType tariffType) {
    if (tariffType == TariffType.domestic) {
      return TariffRates.getEeiBand(cumulativeKwh).label;
    }
    return TariffRates.getTierPriceKwhLabel(
      TariffRates.getTier(cumulativeKwh, TariffType.commercial),
      TariffType.commercial,
    );
  }

  bool get hasUsage => usageKwh > 0;

  bool get canSave =>
      !isLoadingLastReading && currentReading > 0 && readingError == null;

  bool get isBaselineReading => lastReadingDate == null;

  String get formattedLastReadingDate {
    if (lastReadingDate == null) return 'No previous reading';
    return lastReadingDate!.shortDayLabel;
  }

  String get formattedNextReadingDate {
    if (nextReadingDate == null) return '';
    return nextReadingDate!.shortDayLabel;
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
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
