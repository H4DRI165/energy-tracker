import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:energy_tracker/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a complete Firestore user profile document', () {
    final profile = UserProfile.fromDoc({
      'fullName': 'Hadri',
      'tariffType': 'commercial',
      'monthlyBudget': 150,
      'tnbAccountNo': '123456789012',
      'monthlySummaryEnabled': false,
      'isGuest': false,
      'onboardingCompleted': true,
    });

    expect(profile.fullName, 'Hadri');
    expect(profile.tariffType, TariffType.commercial);
    expect(profile.monthlyBudget, 150.0);
    expect(profile.monthlySummaryEnabled, isFalse);
    expect(profile.onboardingCompleted, isTrue);
  });

  test('uses safe defaults for absent or invalid Firestore fields', () {
    final profile = UserProfile.fromDoc({
      'fullName': 42,
      'tariffType': 'unknown',
      'monthlyBudget': 'invalid',
    });

    expect(profile.fullName, '');
    expect(profile.tariffType, TariffType.domestic);
    expect(profile.monthlyBudget, 0);
    expect(profile.tnbAccountNo, '');
    expect(profile.monthlySummaryEnabled, isTrue);
    expect(profile.isGuest, isFalse);
    expect(profile.onboardingCompleted, isFalse);
  });

  test('copyWith preserves unchanged user profile fields', () {
    const original = UserProfile(
      fullName: 'Hadri',
      tariffType: TariffType.domestic,
      monthlyBudget: 100,
      tnbAccountNo: '123',
      monthlySummaryEnabled: true,
      isGuest: false,
      onboardingCompleted: false,
    );

    final updated = original.copyWith(
      monthlyBudget: 200,
      onboardingCompleted: true,
    );

    expect(updated.fullName, 'Hadri');
    expect(updated.tariffType, TariffType.domestic);
    expect(updated.monthlyBudget, 200);
    expect(updated.onboardingCompleted, isTrue);
    expect(updated.tnbAccountNo, '123');
  });
}
