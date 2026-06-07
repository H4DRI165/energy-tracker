import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/ui/features/ft_settings/ft_profile/notifier/profile_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsNotifier extends ChangeNotifier {
  SettingsNotifier({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  bool _disposed = false;

  SettingsPageState _state = const SettingsPageState();
  SettingsPageState get state => _state;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> init() async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    _notify();

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      _state = _state.copyWith(
        fullName: data['fullName'] as String? ?? '',
        email: _auth.currentUser?.email ?? '',
        tnbAccountNo: data['tnbAccountNo'] as String? ?? '',
        tariffType: data['tariffType'] as String? ?? 'domestic',
        monthlyBudget: (data['monthlyBudget'] as num?)?.toDouble() ?? 150.0,
        budgetAlertsEnabled: data['budgetAlertsEnabled'] as bool? ?? true,
        billRemindersEnabled: data['billRemindersEnabled'] as bool? ?? true,
        monthlySummaryEnabled: data['monthlySummaryEnabled'] as bool? ?? false,
      );
    } on Exception catch (_) {
      _state = _state.copyWith(
        errorMessage: 'Failed to load settings.',
      );
    } finally {
      _state = _state.copyWith(isLoading: false);
      _notify();
    }
  }

  Future<void> toggleBudgetAlerts({required bool value}) async {
    _state = _state.copyWith(budgetAlertsEnabled: value);
    _notify();
    await _updateFirestore({'budgetAlertsEnabled': value});
  }

  Future<void> toggleBillReminders({required bool value}) async {
    _state = _state.copyWith(billRemindersEnabled: value);
    _notify();
    await _updateFirestore({'billRemindersEnabled': value});
  }

  Future<void> toggleMonthlySummary({required bool value}) async {
    _state = _state.copyWith(monthlySummaryEnabled: value);
    _notify();
    await _updateFirestore({'monthlySummaryEnabled': value});
  }

  Future<bool> signOut() async {
    _state = _state.copyWith(isSigningOut: true, errorMessage: null);
    _notify();

    try {
      await _auth.signOut();
      return true;
    } on Exception catch (_) {
      _state = _state.copyWith(
        errorMessage: 'Failed to sign out. Please try again.',
      );
      _notify();
      return false;
    } finally {
      _state = _state.copyWith(isSigningOut: false);
      _notify();
    }
  }

  Future<void> _updateFirestore(Map<String, dynamic> data) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      await _firestore.collection('users').doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (_) {
      // Silent fail for toggle updates — state already updated optimistically
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
