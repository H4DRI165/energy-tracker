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
    final today = DateTime.now();
    unawaited(Future.microtask(() => _loadSurroundingReadings(today)));
    return AddReadingPageState(selectedDate: today);
  }

  Future<void> _loadSurroundingReadings(DateTime selectedDate) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      state = state.copyWith(isLoadingLastReading: false);
      return;
    }

    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    final startOfMonth = DateTime(selectedDate.year, selectedDate.month);
    final endOfMonth = DateTime(selectedDate.year, selectedDate.month + 1);

    final endOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      23,
      59,
      59,
    );

    // Today: use now so only past entries today are considered
    // Past: use end of selected day so entries on that day are included
    final beforeCutoff = isToday ? now : endOfDay;

    try {
      final beforeSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('readings')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where('date', isLessThan: Timestamp.fromDate(beforeCutoff))
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      final nextFirstSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('readings')
          .where('date', isGreaterThan: Timestamp.fromDate(endOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
          .orderBy('date', descending: false)
          .limit(1)
          .get();

      double lastReading = 0;
      DateTime? lastReadingDate;
      double? nextReading;
      DateTime? nextReadingDate;

      if (beforeSnap.docs.isNotEmpty) {
        final data = beforeSnap.docs.first.data();
        lastReading = (data['reading'] as num?)?.toDouble() ?? 0;
        lastReadingDate = (data['date'] as Timestamp).toDate();
      }

      if (nextFirstSnap.docs.isNotEmpty) {
        final nextEntryDate =
            (nextFirstSnap.docs.first.data()['date'] as Timestamp).toDate();

        final nextDayStart = DateTime(
          nextEntryDate.year,
          nextEntryDate.month,
          nextEntryDate.day,
        );
        final nextDayEnd = DateTime(
          nextEntryDate.year,
          nextEntryDate.month,
          nextEntryDate.day,
          23,
          59,
          59,
        );

        final nextLastSnap = await _firestore
            .collection('users')
            .doc(uid)
            .collection('readings')
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(nextDayStart),
            )
            .where(
              'date',
              isLessThanOrEqualTo: Timestamp.fromDate(nextDayEnd),
            )
            .orderBy('date', descending: true)
            .limit(1)
            .get();

        if (nextLastSnap.docs.isNotEmpty) {
          final data = nextLastSnap.docs.first.data();
          nextReading = (data['reading'] as num?)?.toDouble();
          nextReadingDate = (data['date'] as Timestamp).toDate();
        }
      }

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      final lastDateLabel = lastReadingDate != null
          ? '${months[lastReadingDate.month - 1]} ${lastReadingDate.day}'
          : '';

      final nextDateLabel = nextReadingDate != null
          ? '${months[nextReadingDate.month - 1]} ${nextReadingDate.day}'
          : '';

      state = state.copyWith(
        isLoadingLastReading: false,
        lastReading: lastReading,
        lastReadingDate: lastReadingDate,
        nextReading: nextReading,
        nextReadingDate: nextReadingDate,
        readingError: _validateReading(
          state.currentReading,
          lastReading,
          nextReading,
          lastReadingDateLabel: lastDateLabel,
          nextReadingDateLabel: nextDateLabel,
        ),
      );
    } on Exception catch (_) {
      state = state.copyWith(isLoadingLastReading: false);
    }
  }

  String? _validateReading(
    double reading,
    double lastReading,
    double? nextReading, {
    String lastReadingDateLabel = '',
    String nextReadingDateLabel = '',
  }) {
    if (reading <= 0) return null;

    if (lastReading > 0 && reading < lastReading) {
      return 'Must be above ${lastReading.toStringAsFixed(0)} kWh'
          '${lastReadingDateLabel.isNotEmpty ? ' ($lastReadingDateLabel)' : ''}';
    }

    if (nextReading != null && reading > nextReading) {
      return 'Must be below ${nextReading.toStringAsFixed(0)} kWh'
          '${nextReadingDateLabel.isNotEmpty ? ' ($nextReadingDateLabel)' : ''}';
    }

    return null;
  }

  // Helper getters for formatted dates used in _validateReading
  String get formattedLastReadingDate => state.formattedLastReadingDate;
  String get formattedNextReadingDate => state.formattedNextReadingDate;

  void setReading(String value) {
    final reading = double.tryParse(value) ?? 0;

    state = state.copyWith(
      currentReading: reading,
      readingError: _validateReading(
        reading,
        state.lastReading,
        state.nextReading,
        lastReadingDateLabel: state.formattedLastReadingDate,
        nextReadingDateLabel: state.formattedNextReadingDate,
      ),
      errorMessage: null,
    );
  }

  void setDate(DateTime date) {
    state = state.copyWith(
      selectedDate: date,
      isLoadingLastReading: true,
      // Clear bounds while re-fetching
      nextReading: null,
      nextReadingDate: null,
    );
    unawaited(Future.microtask(() => _loadSurroundingReadings(date)));
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
      state = state.copyWith(
        isSaving: false,
        errorMessage: _mapError(e.code),
      );
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
