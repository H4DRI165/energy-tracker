import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/ui/features/ft_add_meter_reading/notifier/add_meter_reading_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<AddReadingNotifier, AddReadingPageState>
    addReadingProvider =
    NotifierProvider.autoDispose<AddReadingNotifier, AddReadingPageState>(
  AddReadingNotifier.new,
);

class AddReadingNotifier extends Notifier<AddReadingPageState> {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  AddReadingPageState build() {
    unawaited(Future.microtask(_loadLastReading));
    return AddReadingPageState(selectedDate: DateTime.now());
  }

  Future<void> _loadLastReading() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      state = state.copyWith(isLoadingLastReading: false);
      return;
    }

    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('readings')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        state = state.copyWith(isLoadingLastReading: false);
        return;
      }

      final data = snap.docs.first.data();
      final reading = (data['reading'] as num?)?.toDouble() ?? 0;
      final date = (data['date'] as Timestamp).toDate();

      state = state.copyWith(
        isLoadingLastReading: false,
        lastReading: reading,
        lastReadingDate: date,
      );
    } on Exception catch (_) {
      state = state.copyWith(isLoadingLastReading: false);
    }
  }

  void setReading(String value) {
    final reading = double.tryParse(value) ?? 0;

    String? error;
    if (reading < state.lastReading && state.lastReading > 0) {
      error = 'Reading cannot be less than previous '
          'reading (${state.lastReading.toStringAsFixed(0)})';
    }

    state = state.copyWith(
      currentReading: reading,
      readingError: error,
      errorMessage: null,
    );
  }

  void setDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void setNotes(String value) {
    state = state.copyWith(notes: value);
  }

  Future<bool> saveReading() async {
    if (!state.canSave) return false;

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      state = state.copyWith(
        errorMessage: 'Session expired. Please sign in again.',
      );
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final date = state.selectedDate ?? DateTime.now();
      final batch = _firestore.batch();

      final readingRef =
          _firestore.collection('users').doc(uid).collection('readings').doc();

      batch.set(readingRef, {
        'reading': state.currentReading,
        'kwh': state.usageKwh,
        'date': Timestamp.fromDate(date),
        'notes': state.notes.trim(),
        'estimatedBill': state.estimatedBill,
        'tier': state.currentTier,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (state.hasUsage) {
        final billRef =
            _firestore.collection('users').doc(uid).collection('bills').doc();

        batch.set(billRef, {
          'kwh': state.usageKwh,
          'amount': state.estimatedBill,
          'date': Timestamp.fromDate(date),
          'tier': state.currentTier,
          'isPaid': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      state = state.copyWith(isSaving: false);
      return true;
    } on FirebaseException catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: _mapError(e.code));
      return false;
    } on Exception catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save reading. Please try again.',
      );
      return false;
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'permission-denied':
        return 'Permission denied. Please check your account.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Failed to save reading. Please try again.';
    }
  }
}
