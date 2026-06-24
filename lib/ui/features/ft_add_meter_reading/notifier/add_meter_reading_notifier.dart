import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/extensions/date_time_extension.dart';
import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:energy_tracker/models/reading_record.dart';
import 'package:energy_tracker/services/notifiers/user_profile_notifier.dart';
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
  DateTime? _editingDate;

  @override
  AddReadingPageState build() {
    final today = DateTime.now();
    unawaited(Future.microtask(() => _loadSurroundingReadings(today)));
    return AddReadingPageState(selectedDate: today);
  }

  void initForEdit(ReadingRecord reading) {
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
      final readingsCol =
          _firestore.collection('users').doc(uid).collection('readings');

      Query<Map<String, dynamic>> beforeQuery;
      Query<Map<String, dynamic>> nextQuery;

      if (_editingDate != null) {
        // Editing: neighbours are simply the readings immediately
        // chronologically before/after this entry's original date.
        beforeQuery = readingsCol.where(
          'date',
          isLessThan: Timestamp.fromDate(_editingDate!),
        );
        nextQuery = readingsCol.where(
          'date',
          isGreaterThan: Timestamp.fromDate(_editingDate!),
        );
      } else {
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

        beforeQuery =
            readingsCol.where('date', isLessThan: Timestamp.fromDate(cutoff));
        nextQuery = readingsCol.where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfNextDay),
        );
      }

      final beforeSnap =
          await beforeQuery.orderBy('date', descending: true).limit(1).get();
      final nextSnap = await nextQuery.orderBy('date').limit(1).get();

      final before =
          beforeSnap.docs.isEmpty ? null : _parse(beforeSnap.docs.first);
      final next = nextSnap.docs.isEmpty ? null : _parse(nextSnap.docs.first);

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

  ({double reading, DateTime date}) _parse(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return (
      reading: (data['reading'] as num?)?.toDouble() ?? 0,
      date: (data['date'] as Timestamp).toDate(),
    );
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
      final label = lastDate != null ? ' (${lastDate.shortDayLabel})' : '';
      return 'Must be above ${lastReading.toStringAsFixed(0)} kWh$label';
    }

    if (nextReading != null && reading > nextReading) {
      final label = nextDate != null ? ' (${nextDate.shortDayLabel})' : '';
      return 'Must be below ${nextReading.toStringAsFixed(0)} kWh$label';
    }

    return null;
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

  String _monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

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
      final tariffType = ref.read(tariffTypeProvider);

      final conflict = await _checkTariffConflict(uid, date, tariffType);
      if (conflict != null) {
        state = state.copyWith(isSaving: false, errorMessage: conflict);
        return false;
      }

      await _firestore.collection('users').doc(uid).collection('readings').add({
        'reading': state.currentReading,
        'kwh': state.usageKwh,
        'date': Timestamp.fromDate(date),
        'notes': state.notes.trim(),
        'tier': state.currentTier(tariffType),
        'tariffType': tariffType.value,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _recalculateMonthBill(uid, date, tariffType);

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

  Future<String?> _checkTariffConflict(
    String uid,
    DateTime date,
    TariffType tariffType,
  ) async {
    final start = DateTime(date.year, date.month);
    final end = DateTime(date.year, date.month + 1);

    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('readings')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final existingTariffValue = snap.docs.first.data()['tariffType'] as String?;
    final existingTariff = TariffTypeX.fromValue(
      existingTariffValue ?? TariffType.domestic.value,
    );

    if (existingTariff != tariffType) {
      final monthLabel = date.monthYearLabel;
      return 'This month already has readings under '
          '${existingTariff.label}. Switch your tariff back, or add this '
          'reading to a different month, to keep $monthLabel consistent.';
    }

    return null;
  }

  Future<void> _recalculateMonthBill(
    String uid,
    DateTime date,
    TariffType tariffType,
  ) async {
    final key = _monthKey(date);
    final start = DateTime(date.year, date.month);
    final end = DateTime(date.year, date.month + 1);

    final readingsSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('readings')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    final billRef =
        _firestore.collection('users').doc(uid).collection('bills').doc(key);

    if (readingsSnap.docs.isEmpty) {
      await billRef.delete();
      return;
    }

    final totalKwh = readingsSnap.docs.fold<double>(
      0,
      (total, doc) => total + ((doc.data()['kwh'] as num?)?.toDouble() ?? 0),
    );

    await billRef.set(
      {
        'kwh': totalKwh,
        'amount': TariffRates.calculate(totalKwh, tariffType),
        'tier': TariffRates.getTier(totalKwh, tariffType),
        'tariffType': tariffType.value,
        'date': Timestamp.fromDate(start),
      },
      SetOptions(merge: true),
    );
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
      final oldDate = reading.date;

      final dateChangedMonth =
          date.month != oldDate.month || date.year != oldDate.year;

      if (dateChangedMonth) {
        final conflict =
            await _checkTariffConflict(uid, date, reading.tariffType);
        if (conflict != null) {
          state = state.copyWith(isSaving: false, errorMessage: conflict);
          return false;
        }
      }

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('readings')
          .doc(reading.id)
          .update({
        'reading': state.currentReading,
        'kwh': state.usageKwh,
        'date': Timestamp.fromDate(date),
        'notes': state.notes.trim(),
        'tier': state.currentTier(reading.tariffType),
      });

      await _recalculateMonthBill(uid, date, reading.tariffType);
      if (dateChangedMonth) {
        await _recalculateMonthBill(uid, oldDate, reading.tariffType);
      }

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
