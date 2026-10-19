class UserProfile {
  const UserProfile({
    required this.fullName,
    required this.monthlyBudget,
    required this.tnbAccountNo,
    required this.monthlySummaryEnabled,
    required this.isGuest,
    required this.onboardingCompleted,
  });

  factory UserProfile.fromDoc(Map<String, dynamic> data) => UserProfile(
    fullName: _readString(data['fullName']),
    monthlyBudget: _readDouble(data['monthlyBudget']),
    tnbAccountNo: _readString(data['tnbAccountNo']),
    monthlySummaryEnabled: _readBool(
      data['monthlySummaryEnabled'],
      fallback: true,
    ),
    isGuest: _readBool(data['isGuest']),
    onboardingCompleted: _readBool(data['onboardingCompleted']),
  );

  static String _readString(dynamic value, {String fallback = ''}) =>
      value is String ? value : fallback;

  static double _readDouble(dynamic value) =>
      value is num ? value.toDouble() : 0;

  static bool _readBool(dynamic value, {bool fallback = false}) =>
      value is bool ? value : fallback;

  final String fullName;
  final double monthlyBudget;
  final String tnbAccountNo;
  final bool monthlySummaryEnabled;
  final bool isGuest;
  final bool onboardingCompleted;

  UserProfile copyWith({
    String? fullName,
    double? monthlyBudget,
    String? tnbAccountNo,
    bool? monthlySummaryEnabled,
    bool? isGuest,
    bool? onboardingCompleted,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      tnbAccountNo: tnbAccountNo ?? this.tnbAccountNo,
      monthlySummaryEnabled:
          monthlySummaryEnabled ?? this.monthlySummaryEnabled,
      isGuest: isGuest ?? this.isGuest,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}
