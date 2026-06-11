import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/models/appliance.dart';
import 'package:energy_tracker/ui/features/ft_devices/devices/notifier/devices_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<DevicesNotifier, DevicesPageState> devicesProvider =
    NotifierProvider.autoDispose<DevicesNotifier, DevicesPageState>(
  DevicesNotifier.new,
);

class DevicesNotifier extends Notifier<DevicesPageState> {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  DevicesPageState build() {
    unawaited(Future.microtask(_loadAppliances));
    return const DevicesPageState();
  }

  Future<void> _loadAppliances() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('appliances')
          .orderBy('createdAt', descending: false)
          .get();

      final appliances = snap.docs
          .map((doc) => Appliance.fromDoc(doc.id, doc.data()))
          .toList();

      state = state.copyWith(isLoading: false, appliances: appliances);
    } on FirebaseException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load appliances: ${e.message}',
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadAppliances();
  }

  Future<bool> deleteAppliance(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('appliances')
          .doc(id)
          .delete();

      state = state.copyWith(
        appliances: state.appliances.where((a) => a.id != id).toList(),
      );
      return true;
    } on FirebaseException catch (_) {
      return false;
    }
  }
}
