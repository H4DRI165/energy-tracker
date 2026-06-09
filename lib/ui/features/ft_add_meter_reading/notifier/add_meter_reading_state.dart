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

  double get estimatedBill {
    final kwh = usageKwh;
    if (kwh <= 0) return 0;
    double bill = 0;
    bill += kwh.clamp(0.0, 200.0) * 0.218;
    if (kwh > 200) bill += (kwh - 200).clamp(0.0, 100.0) * 0.334;
    if (kwh > 300) bill += (kwh - 300).clamp(0.0, 300.0) * 0.516;
    if (kwh > 600) bill += (kwh - 600) * 0.546;
    return bill < 3.0 && kwh > 0 ? 3.0 : bill;
  }

  int get currentTier {
    final kwh = usageKwh;
    if (kwh <= 200) return 1;
    if (kwh <= 300) return 2;
    if (kwh <= 600) return 3;
    return 4;
  }

  String get tierLabel {
    switch (currentTier) {
      case 1:
        return 'Tier 1 — 21.8 sen/kWh';
      case 2:
        return 'Tier 2 — 33.4 sen/kWh';
      case 3:
        return 'Tier 3 — 51.6 sen/kWh';
      default:
        return 'Tier 4 — 54.6 sen/kWh';
    }
  }

  bool get hasUsage => usageKwh > 0;
  bool get canSave => currentReading > 0 && readingError == null;

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
