import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/constants/tariff_types.dart';
import 'package:energy_tracker/ui/components/logger.dart';
import 'package:energy_tracker/ui/features/ft_onboarding/notifier/onboarding_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<OnboardingNotifier, OnboardingPageState>
    onboardingProvider =
    NotifierProvider.autoDispose<OnboardingNotifier, OnboardingPageState>(
  OnboardingNotifier.new,
);

class OnboardingNotifier extends Notifier<OnboardingPageState> {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

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

  bool get canGoBack => state.currentStep > 0;

  Future<bool> completeOnboarding() async {
    final uid = _auth.currentUser?.uid;

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
    } on FirebaseException catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          errorMessage: _mapFirestoreError(e.code),
        );
      }

      return false;
    } on Exception catch (e, stack) {
      if (ref.mounted) {
        AppLogger.error('Onboarding unexpected exception: ', e, stack);

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

  String _mapFirestoreError(String code) {
    switch (code) {
      case 'permission-denied':
        return 'Permission denied. Please check your account status.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Failed to save settings. Please try again.';
    }
  }
}
