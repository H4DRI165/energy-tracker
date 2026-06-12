import 'package:energy_tracker/models/appliance.dart';

class DevicesPageState {
  const DevicesPageState({
    this.isLoading = true,
    this.appliances = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final List<Appliance> appliances;
  final String? errorMessage;
  static const Object _unset = Object();

  double get totalMonthlyKwh =>
      appliances.fold(0, (sum, a) => sum + a.monthlyKwh);

  double get totalMonthlyCost =>
      appliances.fold(0, (sum, a) => sum + a.monthlyCost);

  DevicesPageState copyWith({
    bool? isLoading,
    List<Appliance>? appliances,
    Object? errorMessage = _unset,
  }) {
    return DevicesPageState(
      isLoading: isLoading ?? this.isLoading,
      appliances: appliances ?? this.appliances,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
