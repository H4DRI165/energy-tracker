import 'package:energy_tracker/constants/tariff_rates.dart';

class OnboardingPageState {
  const OnboardingPageState({
    this.currentStep = 0,
    this.monthlyBudget = 150.0,
    this.isLoading = false,
    this.errorMessage,
  });

  final int currentStep;
  final double monthlyBudget;
  final bool isLoading;
  final String? errorMessage;
  static const Object _noChange = Object();

  static const int totalSteps = 2;
  static const double minBudget = 50;
  static const double maxBudget = 500;

  String get estimatedKwh {
    final kwh = TariffRates.estimateKwhFromBudget(monthlyBudget);
    return '≈ ${kwh.toStringAsFixed(0)} kWh estimated';
  }

  double get progressValue => (currentStep + 1) / totalSteps;

  bool get canGoBack => currentStep > 0;

  OnboardingPageState copyWith({
    int? currentStep,
    double? monthlyBudget,
    bool? isLoading,
    Object? errorMessage = _noChange,
  }) {
    return OnboardingPageState(
      currentStep: currentStep ?? this.currentStep,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _noChange)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
