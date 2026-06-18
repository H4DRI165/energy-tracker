import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/models/reading_record.dart';
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
  int _loadRequestId = 0;
  String? _editingReadingId;
  DateTime? _editingDate;

  @override
  AddReadingPageState build() {
    final today = DateTime.now();
    unawaited(Future.microtask(() => _loadSurroundingReadings(today)));
    return AddReadingPageState(selectedDate: today);
  }

  void initForEdit(ReadingRecord reading) {
    _editingReadingId = reading.id;
    _editingDate = reading.date;

    state = state.copyWith(
      selectedDate: reading.date,
      currentReading: reading.reading,
      notes: reading.notes,
      isLoadingLastReading: true,
    );
    unawaited(
      Future.microtask(() => _loadSurroundingReadings(reading.date)),
    );
  }

  Future<void> _loadSurroundingReadings(DateTime selectedDate) async {
    final requestId = ++_loadRequestId;
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      if (requestId == _loadRequestId) {
        state = state.copyWith(isLoadingLastReading: false);
      }
      return;
    }

    try {
      // Single query — fetch all readings for selected month
      final startOfMonth = DateTime(selectedDate.year, selectedDate.month);
      final endOfMonth = DateTime(selectedDate.year, selectedDate.month + 1);

      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('readings')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where(
            'date',
            isLessThan: Timestamp.fromDate(endOfMonth),
          )
          .orderBy('date', descending: false)
          .get();

      // All readings this month, sorted oldest → newest
      // Exclude the entry being edited so it doesn't affect bounds
      final readings =
          snap.docs.where((doc) => doc.id != _editingReadingId).map((doc) {
        final data = doc.data();
        return (
          reading: (data['reading'] as num?)?.toDouble() ?? 0,
          date: (data['date'] as Timestamp).toDate(),
        );
      }).toList();

      // Cutoff: for today use now, for past use end of selected day
      final now = DateTime.now();
      final isToday = selectedDate.year == now.year &&
          selectedDate.month == now.month &&
          selectedDate.day == now.day;

      final cutoff = isToday
          ? now
          : DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              23,
              59,
              59,
            );

      final startOfNextDay = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day + 1,
      );

      ({double reading, DateTime date})? before;
      ({double reading, DateTime date})? next;

      if (_editingDate != null) {
        before =
            readings.where((r) => r.date.isBefore(_editingDate!)).lastOrNull;

        next = readings.where((r) => r.date.isAfter(_editingDate!)).firstOrNull;
      } else {
        // Previous: latest reading before or on selected day
        before = readings.where((r) => r.date.isBefore(cutoff)).lastOrNull;

        // Next: earliest reading after selected day
        // Group by day and get the last reading of the next day
        final afterReadings =
            readings.where((r) => !r.date.isBefore(startOfNextDay)).toList();

        if (afterReadings.isNotEmpty) {
          // Find the first day after selected date
          final nextDay = afterReadings.first.date;
          final nextDayStart =
              DateTime(nextDay.year, nextDay.month, nextDay.day);
          final nextDayEnd =
              DateTime(nextDay.year, nextDay.month, nextDay.day + 1);

          // Last entry of that day = highest meter reading of that day
          next = afterReadings
              .where(
                (r) =>
                    !r.date.isBefore(nextDayStart) &&
                    r.date.isBefore(nextDayEnd),
              )
              .lastOrNull;
        }
      }

      if (requestId != _loadRequestId || state.selectedDate != selectedDate) {
        return;
      }

      state = state.copyWith(
        isLoadingLastReading: false,
        lastReading: before?.reading ?? 0,
        lastReadingDate: before?.date,
        nextReading: next?.reading,
        nextReadingDate: next?.date,
        readingError: _validateReading(
          reading: state.currentReading,
          lastReading: before?.reading ?? 0,
          nextReading: next?.reading,
          lastDate: before?.date,
          nextDate: next?.date,
        ),
      );
    } on Exception catch (_) {
      if (requestId == _loadRequestId) {
        state = state.copyWith(isLoadingLastReading: false);
      }
    }
  }

  String? _validateReading({
    required double reading,
    required double lastReading,
    required double? nextReading,
    required DateTime? lastDate,
    required DateTime? nextDate,
  }) {
    if (reading <= 0) return null;

    if (lastReading > 0 && reading < lastReading) {
      final label = lastDate != null ? ' (${_formatDate(lastDate)})' : '';
      return 'Must be above ${lastReading.toStringAsFixed(0)} kWh$label';
    }

    if (nextReading != null && reading > nextReading) {
      final label = nextDate != null ? ' (${_formatDate(nextDate)})' : '';
      return 'Must be below ${nextReading.toStringAsFixed(0)} kWh$label';
    }

    return null;
  }

  String _formatDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}';
  }

  void setReading(String value) {
    final reading = double.tryParse(value) ?? 0;
    state = state.copyWith(
      currentReading: reading,
      readingError: _validateReading(
        reading: reading,
        lastReading: state.lastReading,
        nextReading: state.nextReading,
        lastDate: state.lastReadingDate,
        nextDate: state.nextReadingDate,
      ),
      errorMessage: null,
    );
  }

  void setDate(DateTime date) {
    state = state.copyWith(
      selectedDate: date,
      isLoadingLastReading: true,
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

  Future<bool> updateReading(ReadingRecord reading) async {
    if (!state.canSave) return false;

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      state = state.copyWith(errorMessage: 'Session expired.');
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final date = state.selectedDate ?? DateTime.now();
      final batch = _firestore.batch()
        ..update(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('readings')
              .doc(reading.id),
          {
            'reading': state.currentReading,
            'kwh': state.usageKwh,
            'date': Timestamp.fromDate(date),
            'notes': state.notes.trim(),
            'tier': state.currentTier,
          },
        );

      final startOfDay =
          DateTime(reading.date.year, reading.date.month, reading.date.day);
      final endOfDay =
          DateTime(reading.date.year, reading.date.month, reading.date.day + 1);
      final billSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('bills')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      for (final doc in billSnap.docs) {
        batch.update(doc.reference, {
          'kwh': state.usageKwh,
          'amount': state.estimatedBill,
          'date': Timestamp.fromDate(date),
          'tier': state.currentTier,
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
        errorMessage: 'Failed to update reading. Please try again.',
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
