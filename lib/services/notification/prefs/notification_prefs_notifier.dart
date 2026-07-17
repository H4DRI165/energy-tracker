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

  Future<void> _load() async {
    final uid = ref.read(currentUidProvider).value;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    state = state.copyWith(
      alert80Enabled: data?['alert80Enabled'] as bool? ?? true,
      alert100Enabled: data?['alert100Enabled'] as bool? ?? true,
      isLoading: false,
    );
  }

  Future<void> setAlert80({required bool value}) async {
    state = state.copyWith(alert80Enabled: value);
    await _update('alert80Enabled', value);
  }

  Future<void> setAlert100({required bool value}) async {
    state = state.copyWith(alert100Enabled: value);
    await _update('alert100Enabled', value);
  }

  Future<void> _update(String field, bool value) async {
    final uid = ref.read(currentUidProvider).value;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).set(
      {field: value},
      SetOptions(merge: true),
    );
  }
}
