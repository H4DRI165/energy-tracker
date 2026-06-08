class SettingsPageState {
  const SettingsPageState({
    this.isLoading = true,
    this.fullName = '',
    this.email = '',
    this.tnbAccountNo = '',
    this.tariffType = 'domestic',
    this.monthlyBudget = 150.0,
    this.budgetAlertsEnabled = true,
    this.billRemindersEnabled = true,
    this.monthlySummaryEnabled = false,
    this.isDarkMode = true,
    this.isSigningOut = false,
    this.errorMessage,
  });

  final bool isLoading;
  final String fullName;
  final String email;
  final String tnbAccountNo;
  final String tariffType;
  final double monthlyBudget;
  final bool budgetAlertsEnabled;
  final bool billRemindersEnabled;
  final bool monthlySummaryEnabled;
  final bool isDarkMode;
  final bool isSigningOut;
  final String? errorMessage;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  String get tariffLabel {
    switch (tariffType) {
      case 'commercial':
        return 'Commercial';
      default:
        return 'Domestic';
    }
  }

  String get formattedBudget => 'RM ${monthlyBudget.toStringAsFixed(0)}';

  static const Object _unset = Object();

  SettingsPageState copyWith({
    bool? isLoading,
    String? fullName,
    String? email,
    String? tnbAccountNo,
    String? tariffType,
    double? monthlyBudget,
    bool? budgetAlertsEnabled,
    bool? billRemindersEnabled,
    bool? monthlySummaryEnabled,
    bool? isDarkMode,
    bool? isSigningOut,
    Object? errorMessage = _unset,
  }) {
    return SettingsPageState(
      isLoading: isLoading ?? this.isLoading,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      tnbAccountNo: tnbAccountNo ?? this.tnbAccountNo,
      tariffType: tariffType ?? this.tariffType,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      billRemindersEnabled: billRemindersEnabled ?? this.billRemindersEnabled,
      monthlySummaryEnabled:
          monthlySummaryEnabled ?? this.monthlySummaryEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isSigningOut: isSigningOut ?? this.isSigningOut,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
