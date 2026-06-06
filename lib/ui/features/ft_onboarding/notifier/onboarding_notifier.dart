import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/ui/components/logger.dart';
import 'package:energy_tracker/ui/features/ft_onboarding/notifier/onboarding_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OnboardingNotifier extends ChangeNotifier {
  OnboardingNotifier({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  bool _disposed = false;

  OnboardingPageState _state = const OnboardingPageState();
  OnboardingPageState get state => _state;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void selectTariff(TariffType tariff) {
    _state = _state.copyWith(selectedTariff: tariff);
    _notify();
  }

  void nextFromTariff() {
    _state = _state.copyWith(currentStep: 1);
    _notify();
  }

  void setBudget(double budget) {
    _state = _state.copyWith(monthlyBudget: budget);
    _notify();
  }

  void nextFromBudget() {
    _state = _state.copyWith(currentStep: 2);
    _notify();
  }

  void goBack() {
    if (_state.currentStep > 0) {
      _state = _state.copyWith(currentStep: _state.currentStep - 1);
      _notify();
    }
  }

  bool get canGoBack => _state.currentStep > 0;

  Future<bool> completeOnboarding() async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      _state = _state.copyWith(
        errorMessage: 'User session expired. Please sign in again.',
      );
      _notify();
      return false;
    }

    _state = _state.copyWith(isLoading: true);
    _notify();

    try {
      await _firestore.collection('users').doc(uid).set(
        {
          'tariffType': _state.selectedTariff.value,
          'monthlyBudget': _state.monthlyBudget,
          'onboardingCompleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return true;
    } on FirebaseException catch (e) {
      _state = _state.copyWith(
        errorMessage: _mapFirestoreError(e.code),
      );
      _notify();
      return false;
    } on Exception catch (e, stack) {
      AppLogger.error('Onboarding unexpected exception: ', e, stack);

      _state = _state.copyWith(
        errorMessage: 'Failed to save settings. Please try again.',
      );
      _notify();
      return false;
    } finally {
      _state = _state.copyWith(isLoading: false);
      _notify();
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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
