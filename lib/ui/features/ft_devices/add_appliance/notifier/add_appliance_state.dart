const _categories = [
  'Cooling',
  'Lighting',
  'Kitchen',
  'Entertainment',
  'Washing',
  'Heating',
  'Other',
];

class AddAppliancePageState {
  const AddAppliancePageState({
    this.name = '',
    this.category = 'Cooling',
    this.wattage = 0,
    this.dailyHours = 1,
    this.isSaving = false,
    this.nameError,
    this.wattageError,
    this.errorMessage,
  });

  final String name;
  final String category;
  final double wattage;
  final double dailyHours;
  final bool isSaving;
  final String? nameError;
  final String? wattageError;
  final String? errorMessage;

  static List<String> get categories => _categories;

  double get monthlyKwh => (wattage / 1000) * dailyHours * 30;

  double get monthlyCost {
    final kwh = monthlyKwh;
    if (kwh <= 0) return 0;
    double bill = 0;
    bill += kwh.clamp(0.0, 200.0) * 0.218;
    if (kwh > 200) bill += (kwh - 200).clamp(0.0, 100.0) * 0.334;
    if (kwh > 300) bill += (kwh - 300).clamp(0.0, 300.0) * 0.516;
    if (kwh > 600) bill += (kwh - 600) * 0.546;
    return bill;
  }

  bool get canSave =>
      name.trim().isNotEmpty &&
      wattage > 0 &&
      dailyHours > 0 &&
      nameError == null &&
      wattageError == null;

  static const Object _unset = Object();

  AddAppliancePageState copyWith({
    String? name,
    String? category,
    double? wattage,
    double? dailyHours,
    bool? isSaving,
    Object? nameError = _unset,
    Object? wattageError = _unset,
    Object? errorMessage = _unset,
  }) {
    return AddAppliancePageState(
      name: name ?? this.name,
      category: category ?? this.category,
      wattage: wattage ?? this.wattage,
      dailyHours: dailyHours ?? this.dailyHours,
      isSaving: isSaving ?? this.isSaving,
      nameError:
          identical(nameError, _unset) ? this.nameError : nameError as String?,
      wattageError: identical(wattageError, _unset)
          ? this.wattageError
          : wattageError as String?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
