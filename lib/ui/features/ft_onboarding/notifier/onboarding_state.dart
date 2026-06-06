enum TariffType {
  domestic,
  commercial,
}

extension TariffTypeX on TariffType {
  String get label {
    switch (this) {
      case TariffType.domestic:
        return 'Domestic (Residential)';
      case TariffType.commercial:
        return 'Commercial (LV)';
    }
  }

  String get subtitle {
    switch (this) {
      case TariffType.domestic:
        return 'Tariff A — For homes & apartments';
      case TariffType.commercial:
        return 'Tariff B — Shops, offices';
    }
  }

  String get icon {
    switch (this) {
      case TariffType.domestic:
        return '🏠';
      case TariffType.commercial:
        return '🏢';
    }
  }

  String get value {
    switch (this) {
      case TariffType.domestic:
        return 'domestic';
      case TariffType.commercial:
        return 'commercial';
    }
  }
}

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
