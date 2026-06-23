import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/services/app_info.dart';
import 'package:energy_tracker/ui/features/ft_settings/pg_settings/notifier/settings_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, SettingsPageState>(
  SettingsNotifier.new,
);

final appVersionProvider = FutureProvider<String>((ref) async {
  final appInfo = await getAppInfo();
  return appInfo.fullVersion;
});

class SettingsNotifier extends AsyncNotifier<SettingsPageState> {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  Future<SettingsPageState> build() async {
    return _fetchSettings();
  }

  Future<SettingsPageState> _fetchSettings() async {
    final user = _auth.currentUser;
    if (user == null) return const SettingsPageState();

    final uid = user.uid;

    // Fallback to auth display name if Firestore is slow
    final authName = user.displayName ?? '';

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      return SettingsPageState(
        fullName: authName,
        email: user.email ?? '',
      );
    }

    final data = doc.data()!;
    return SettingsPageState(
      fullName: data['fullName'] as String? ?? authName,
      email: _auth.currentUser?.email ?? '',
      tnbAccountNo: data['tnbAccountNo'] as String? ?? '',
      tariffType: data['tariffType'] as String? ?? 'domestic',
      monthlyBudget: (data['monthlyBudget'] as num?)?.toDouble() ?? 150.0,
      budgetAlertsEnabled: data['budgetAlertsEnabled'] as bool? ?? true,
      billRemindersEnabled: data['billRemindersEnabled'] as bool? ?? true,
      monthlySummaryEnabled: data['monthlySummaryEnabled'] as bool? ?? false,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchSettings);
  }

  Future<bool> updateTariffType(String value) async {
    final previous = state.value;
    _updateState((s) => s.copyWith(tariffType: value, errorMessage: null));

    final ok = await _updateFirestore({'tariffType': value});

    if (!ok && previous != null) {
      state = AsyncData(
        previous.copyWith(
          errorMessage: 'Failed to update tariff type. Please try again.',
        ),
      );
    }

    return ok;
  }

  Future<bool> updateMonthlyBudget(double value) async {
    final previous = state.value;
    _updateState((s) => s.copyWith(monthlyBudget: value, errorMessage: null));

    final ok = await _updateFirestore({'monthlyBudget': value});

    if (!ok && previous != null) {
      state = AsyncData(
        previous.copyWith(
          errorMessage: 'Failed to update monthly budget. Please try again.',
        ),
      );
    }

    return ok;
  }

  Future<void> toggleBudgetAlerts({required bool value}) async {
    _updateState((s) => s.copyWith(budgetAlertsEnabled: value));
    await _updateFirestore({'budgetAlertsEnabled': value});
  }

  Future<void> toggleBillReminders({required bool value}) async {
    _updateState((s) => s.copyWith(billRemindersEnabled: value));
    await _updateFirestore({'billRemindersEnabled': value});
  }

  Future<void> toggleMonthlySummary({required bool value}) async {
    _updateState((s) => s.copyWith(monthlySummaryEnabled: value));
    await _updateFirestore({'monthlySummaryEnabled': value});
  }

  Future<bool> signOut() async {
    _updateState((s) => s.copyWith(isSigningOut: true, errorMessage: null));
    try {
      await _auth.signOut();
      return true;
    } on Exception catch (_) {
      _updateState(
        (s) => s.copyWith(
          isSigningOut: false,
          errorMessage: 'Failed to sign out. Please try again.',
        ),
      );
      return false;
    }
  }

  void _updateState(SettingsPageState Function(SettingsPageState) updater) {
    state = state.whenData(updater);
  }

  Future<bool> _updateFirestore(Map<String, dynamic> data) async {
    try {
      final uid = _auth.currentUser?.uid;

      if (uid == null) return false;

      await _firestore.collection('users').doc(uid).set(
        {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return true;
    } on Exception catch (_) {
      return false;
    }
  }
}
