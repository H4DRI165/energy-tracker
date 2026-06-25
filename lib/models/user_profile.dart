import 'package:energy_tracker/extensions/tariff_type_extension.dart';

class UserProfile {
  const UserProfile({
    required this.fullName,
    required this.tariffType,
    required this.monthlyBudget,
    required this.tnbAccountNo,
    required this.monthlySummaryEnabled,
    required this.isGuest,
    required this.onboardingCompleted,
  });

  factory UserProfile.fromDoc(Map<String, dynamic> data) => UserProfile(
        fullName: data['fullName'] as String? ?? '',
        tariffType: TariffTypeX.fromValue(
          data['tariffType'] as String? ?? TariffType.domestic.value,
        ),
        monthlyBudget: (data['monthlyBudget'] as num?)?.toDouble() ?? 0,
        tnbAccountNo: data['tnbAccountNo'] as String? ?? '',
        monthlySummaryEnabled: data['monthlySummaryEnabled'] as bool? ?? true,
        isGuest: data['isGuest'] as bool? ?? false,
        onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
      );

  final String fullName;
  final TariffType tariffType;
  final double monthlyBudget;
  final String tnbAccountNo;
  final bool monthlySummaryEnabled;
  final bool isGuest;
  final bool onboardingCompleted;

  UserProfile copyWith({
    String? fullName,
    TariffType? tariffType,
    double? monthlyBudget,
    String? tnbAccountNo,
    bool? monthlySummaryEnabled,
    bool? isGuest,
    bool? onboardingCompleted,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      tariffType: tariffType ?? this.tariffType,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      tnbAccountNo: tnbAccountNo ?? this.tnbAccountNo,
      monthlySummaryEnabled:
          monthlySummaryEnabled ?? this.monthlySummaryEnabled,
      isGuest: isGuest ?? this.isGuest,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}
