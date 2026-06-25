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
    this.nextReadingId,
    this.currentReading = 0,
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
  final String? nextReadingId;
  final double currentReading;
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

  double estimatedBill(TariffType tariffType) =>
      TariffRates.calculate(usageKwh, tariffType);

  int currentTier(TariffType tariffType) =>
      TariffRates.getTier(usageKwh, tariffType);

  String tierLabel(TariffType tariffType) =>
      TariffRates.getTierPriceKwhLabel(currentTier(tariffType), tariffType);

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
    DateTime? lastReadingDate,
    Object? nextReading = _unset,
    Object? nextReadingDate = _unset,
    Object? nextReadingId = _unset,
    double? currentReading,
    DateTime? selectedDate,
    String? notes,
    Object? readingError = _unset,
    Object? errorMessage = _unset,
  }) {
    return AddReadingPageState(
      isLoadingLastReading: isLoadingLastReading ?? this.isLoadingLastReading,
      isSaving: isSaving ?? this.isSaving,
      lastReading: lastReading ?? this.lastReading,
      lastReadingDate: lastReadingDate ?? this.lastReadingDate,
      nextReading: identical(nextReading, _unset)
          ? this.nextReading
          : nextReading as double?,
      nextReadingDate: identical(nextReadingDate, _unset)
          ? this.nextReadingDate
          : nextReadingDate as DateTime?,
      nextReadingId: identical(nextReadingId, _unset)
          ? this.nextReadingId
          : nextReadingId as String?,
      currentReading: currentReading ?? this.currentReading,
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
