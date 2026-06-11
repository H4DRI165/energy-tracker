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

  double get totalMonthlyKwh =>
      appliances.fold(0, (sum, a) => sum + a.monthlyKwh);

  double get totalMonthlyCost =>
      appliances.fold(0, (sum, a) => sum + a.monthlyCost);

  DevicesPageState copyWith({
    bool? isLoading,
    List<Appliance>? appliances,
    String? errorMessage,
  }) {
    return DevicesPageState(
      isLoading: isLoading ?? this.isLoading,
      appliances: appliances ?? this.appliances,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
