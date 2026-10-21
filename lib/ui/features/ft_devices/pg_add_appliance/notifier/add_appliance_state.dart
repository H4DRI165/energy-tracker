import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/models/appliance.dart';

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
  double get dailyKwh => (wattage / 1000) * dailyHours;

  double monthlyKwhAt(double hours) => (wattage / 1000) * hours * 30;

  double monthlyCost() => TariffRates.marginalCost(monthlyKwh);

  double monthlyCostAt(double hours) =>
      TariffRates.marginalCost(monthlyKwhAt(hours));

  double dailyCost() => TariffRates.marginalCost(dailyKwh);

  double get hourlyCost => TariffRates.marginalCost(wattage / 1000);

  double get estimatedLowMonthlyCost =>
      monthlyCostAt(dailyHours * kApplianceEstimateLowFactor);

  double get estimatedHighMonthlyCost =>
      monthlyCostAt(dailyHours * kApplianceEstimateHighFactor);

  double get estimatedLowDailyHours => dailyHours * kApplianceEstimateLowFactor;

  double get estimatedHighDailyHours =>
      dailyHours * kApplianceEstimateHighFactor;

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
      nameError: identical(nameError, _unset)
          ? this.nameError
          : nameError as String?,
      wattageError: identical(wattageError, _unset)
          ? this.wattageError
          : wattageError as String?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
