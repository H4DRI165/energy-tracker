import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:energy_tracker/services/auth/providers/current_uid_provider.dart';
import 'package:energy_tracker/ui/components/logging/app_logger.dart';
import 'package:energy_tracker/ui/components/logging/notifier/loggable_notifier.dart';
import 'package:energy_tracker/ui/features/ft_onboarding/notifier/onboarding_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<OnboardingNotifier, OnboardingPageState>
onboardingProvider =
    NotifierProvider.autoDispose<OnboardingNotifier, OnboardingPageState>(
      OnboardingNotifier.new,
    );

class OnboardingNotifier extends Notifier<OnboardingPageState>
    with LoggableNotifier<OnboardingPageState> {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  String get screenName => 'OnboardingPage';

  @override
  OnboardingPageState build() => const OnboardingPageState();

  void selectTariff(TariffType tariff) {
    state = state.copyWith(selectedTariff: tariff);
  }

  void nextFromTariff() {
    state = state.copyWith(currentStep: 1);
  }

  void setBudget(double budget) {
    state = state.copyWith(monthlyBudget: budget);
  }

  void nextFromBudget() {
    state = state.copyWith(currentStep: 2);
  }

  void goBack() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<bool> completeOnboarding() async {
    final uid = ref.read(currentUidProvider).value;

    if (uid == null) {
      state = state.copyWith(
        errorMessage: 'User session expired. Please sign in again.',
      );

      return false;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      await _firestore.collection('users').doc(uid).set(
        {
          'tariffType': state.selectedTariff.value,
          'monthlyBudget': state.monthlyBudget,
          'onboardingCompleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return true;
    } on FirebaseException catch (e, st) {
      logError(
        'Failed to complete onboarding (Firebase)',
        e,
        st,
        context: {
          'tariff_type': state.selectedTariff.value,
          'monthly_budget': state.monthlyBudget,
        },
      );
      if (ref.mounted) {
        state = state.copyWith(errorMessage: mapFirebaseError(e.code));
      }
      return false;
    } on Exception catch (e, st) {
      logError(
        'Onboarding unexpected exception',
        e,
        st,
        context: {
          'tariff_type': state.selectedTariff.value,
          'monthly_budget': state.monthlyBudget,
        },
      );
      if (ref.mounted) {
        state = state.copyWith(
          errorMessage: 'Failed to save settings. Please try again.',
        );
      }
      return false;
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }
}
