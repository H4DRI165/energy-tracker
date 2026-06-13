import 'package:energy_tracker/constants/tariff_types.dart';

class OnboardingPageState {
  const OnboardingPageState({
    this.currentStep = 0,
    this.selectedTariff = TariffType.domestic,
    this.monthlyBudget = 150.0,
    this.isLoading = false,
    this.errorMessage,
  });

  final int currentStep;
  final TariffType selectedTariff;
  final double monthlyBudget;
  final bool isLoading;
  final String? errorMessage;
  static const Object _noChange = Object();

  static const int totalSteps = 3;
  static const double minBudget = 50;
  static const double maxBudget = 300;

  // Estimated kWh range based on RM budget (domestic tariff approximation)
  String get estimatedKwh {
    final low = (monthlyBudget / 0.30).round();
    final high = (monthlyBudget / 0.25).round();
    return '≈ $low–$high kWh estimated';
  }

  double get progressValue => (currentStep + 1) / totalSteps;

  OnboardingPageState copyWith({
    int? currentStep,
    TariffType? selectedTariff,
    double? monthlyBudget,
    bool? isLoading,
    Object? errorMessage = _noChange,
  }) {
    return OnboardingPageState(
      currentStep: currentStep ?? this.currentStep,
      selectedTariff: selectedTariff ?? this.selectedTariff,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _noChange)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
