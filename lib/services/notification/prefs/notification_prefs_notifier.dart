import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/services/auth/providers/current_uid_provider.dart';
import 'package:energy_tracker/services/notification/prefs/notification_prefs_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<NotificationPrefsNotifier, NotificationPrefsState>
notificationPrefsProvider =
    NotifierProvider.autoDispose<
      NotificationPrefsNotifier,
      NotificationPrefsState
    >(
      NotificationPrefsNotifier.new,
    );

class NotificationPrefsNotifier extends Notifier<NotificationPrefsState> {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  NotificationPrefsState build() {
    ref.watch(currentUidProvider.select((s) => s.value));
    unawaited(_load());
    return const NotificationPrefsState();
  }

  Future<void> reload() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _load();
  }

  Future<void> _load() async {
    final uid = ref.read(currentUidProvider).value;
    if (uid == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Session expired. Please sign in again.',
      );
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      state = state.copyWith(
        alert80Enabled: data?['alert80Enabled'] as bool? ?? true,
        alert100Enabled: data?['alert100Enabled'] as bool? ?? true,
        isLoading: false,
        hasLoaded: true,
        errorMessage: null,
      );
    } on Exception {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Could not load notification settings. Check your connection.',
      );
    }
  }

  Future<bool> setAlert80({required bool value}) =>
      _update('alert80Enabled', value, alert80Enabled: value);

  Future<bool> setAlert100({required bool value}) =>
      _update('alert100Enabled', value, alert100Enabled: value);

  Future<bool> _update(
    String field,
    bool value, {
    bool? alert80Enabled,
    bool? alert100Enabled,
  }) async {
    final previous = state;
    state = state.copyWith(
      alert80Enabled: alert80Enabled,
      alert100Enabled: alert100Enabled,
      isSaving: true,
      errorMessage: null,
    );

    try {
      final uid = ref.read(currentUidProvider).value;
      if (uid == null) throw Exception('Session expired');
      await _firestore.collection('users').doc(uid).set(
        {field: value},
        SetOptions(merge: true),
      );
      state = state.copyWith(isSaving: false);
      return true;
    } on Exception {
      state = previous.copyWith(
        isSaving: false,
        errorMessage:
            'Could not save this setting. Check your connection and try again.',
      );
      return false;
    }
  }
}
