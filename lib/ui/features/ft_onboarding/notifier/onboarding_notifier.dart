import 'package:cloud_firestore/cloud_firestore.dart';
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

  OnboardingPageState _state = const OnboardingPageState();
  OnboardingPageState get state => _state;

  void selectTariff(TariffType tariff) {
    _state = _state.copyWith(selectedTariff: tariff);
    notifyListeners();
  }

  void nextFromTariff() {
    _state = _state.copyWith(currentStep: 1);
    notifyListeners();
  }

  void setBudget(double budget) {
    _state = _state.copyWith(monthlyBudget: budget);
    notifyListeners();
  }

  void nextFromBudget() {
    _state = _state.copyWith(currentStep: 2);
    notifyListeners();
  }

  void goBack() {
    if (_state.currentStep > 0) {
      _state = _state.copyWith(currentStep: _state.currentStep - 1);
      notifyListeners();
    }
  }

  bool get canGoBack => _state.currentStep > 0;

  Future<bool> completeOnboarding() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _state = _state.copyWith(
          errorMessage: 'User session expired. Please sign in again.');
      notifyListeners();
      return false;
    }

    _state = _state.copyWith(isLoading: true);
    notifyListeners();

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
    } catch (e) {
      _state = _state.copyWith(
        errorMessage: 'Failed to save settings. Please try again.',
      );
      notifyListeners();
      return false;
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }
}
