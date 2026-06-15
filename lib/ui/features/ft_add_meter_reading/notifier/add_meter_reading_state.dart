import 'package:energy_tracker/constants/tariff_rates.dart';

class AddReadingPageState {
  const AddReadingPageState({
    this.isLoadingLastReading = true,
    this.isSaving = false,
    this.lastReading = 0,
    this.lastReadingDate,
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
  final double currentReading;
  final DateTime? selectedDate;
  final String notes;
  final String? readingError;
  final String? errorMessage;

  double get usageKwh {
    final usage = currentReading - lastReading;
    return usage > 0 ? usage : 0;
  }

  double get estimatedBill => TariffRates.calculateDomestic(usageKwh);

  int get currentTier => TariffRates.getTier(usageKwh);

  String get tierLabel => TariffRates.getTierPriceKwhLabel(currentTier);

  bool get hasUsage => usageKwh > 0;
  bool get canSave =>
      !isLoadingLastReading && currentReading > 0 && readingError == null;

  String get formattedLastReadingDate {
    if (lastReadingDate == null) return 'No previous reading';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[lastReadingDate!.month - 1]} ${lastReadingDate!.day}';
  }

  static const Object _unset = Object();

  AddReadingPageState copyWith({
    bool? isLoadingLastReading,
    bool? isSaving,
    double? lastReading,
    DateTime? lastReadingDate,
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
