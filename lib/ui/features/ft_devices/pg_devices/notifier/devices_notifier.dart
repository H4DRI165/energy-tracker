import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/models/appliance.dart';
import 'package:energy_tracker/services/auth/providers/current_uid_provider.dart';
import 'package:energy_tracker/ui/features/ft_devices/pg_devices/notifier/devices_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<DevicesNotifier, DevicesPageState> devicesProvider =
    NotifierProvider.autoDispose<DevicesNotifier, DevicesPageState>(
      DevicesNotifier.new,
    );

class DevicesNotifier extends Notifier<DevicesPageState> {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  DevicesPageState build() {
    final uid = ref.watch(currentUidProvider).value;

    if (uid == null) {
      return const DevicesPageState(isLoading: false);
    }

    unawaited(Future.microtask(() => _loadAppliances(uid)));
    return const DevicesPageState();
  }

  Future<void> refresh() async {
    final uid = ref.read(currentUidProvider).value;
    if (uid == null) return;

    state = state.copyWith(isLoading: true);
    await _loadAppliances(uid);
  }

  Future<void> _loadAppliances(String uid) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('appliances')
          .orderBy('createdAt', descending: false)
          .get();

      if (!ref.mounted) return;

      final appliances = snap.docs
          .map((doc) => Appliance.fromDoc(doc.id, doc.data()))
          .toList();

      state = state.copyWith(isLoading: false, appliances: appliances);
    } on FirebaseException catch (e) {
      if (!ref.mounted) return;

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load appliances: ${e.message}',
      );
    }
  }

  Future<bool> deleteAppliance(String id) async {
    final uid = ref.read(currentUidProvider).value;
    if (uid == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('appliances')
          .doc(id)
          .delete();

      if (!ref.mounted) return true;

      state = state.copyWith(
        appliances: state.appliances.where((a) => a.id != id).toList(),
      );
      return true;
    } on FirebaseException catch (_) {
      return false;
    }
  }
}
