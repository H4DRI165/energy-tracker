import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/extensions/date_time_extension.dart';
import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:energy_tracker/models/reading_record.dart';
import 'package:energy_tracker/services/auth/providers/current_uid_provider.dart';
import 'package:energy_tracker/services/billing/bill_recalculation_service.dart';
import 'package:energy_tracker/services/billing/reading_chain_service.dart';
import 'package:energy_tracker/services/notifier/user_profile_notifier.dart';
import 'package:energy_tracker/ui/components/logging/app_logger.dart';
import 'package:energy_tracker/ui/components/logging/notifier/loggable_notifier.dart';
import 'package:energy_tracker/ui/features/ft_add_meter_reading/notifier/add_meter_reading_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<AddReadingNotifier, AddReadingPageState>
addReadingProvider =
    NotifierProvider.autoDispose<AddReadingNotifier, AddReadingPageState>(
      AddReadingNotifier.new,
    );

class AddReadingNotifier extends Notifier<AddReadingPageState>
    with LoggableNotifier<AddReadingPageState> {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  late final ReadingChainService _chainService = ReadingChainService(
    _firestore,
  );
  late final BillRecalculationService _billService = BillRecalculationService(
    _firestore,
  );
  int _loadRequestId = 0;
  DateTime? _editingDate;
  String? _editingReadingId;

  @override
  String get screenName => 'AddReadingPage';

  @override
  AddReadingPageState build() {
    final today = DateTime.now();
    unawaited(Future.microtask(() => _loadSurroundingReadings(today)));
    return AddReadingPageState(selectedDate: today);
  }

  void initForEdit(ReadingRecord reading) {
    _editingDate = reading.date;
    _editingReadingId = reading.id;

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

  DateTime _cutoffFor(DateTime selectedDate) {
    final now = DateTime.now();
    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
    return isToday
        ? now
        : DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            23,
            59,
            59,
          );
  }

  Future<void> _loadSurroundingReadings(DateTime selectedDate) async {
    final requestId = ++_loadRequestId;
    final uid = ref.read(currentUidProvider).value;
    if (uid == null) {
      if (requestId == _loadRequestId) {
        state = state.copyWith(isLoadingLastReading: false);
      }
      return;
    }

    try {
      final readingsCol = _firestore
          .collection('users')
          .doc(uid)
          .collection('readings');

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
        final cutoff = _cutoffFor(selectedDate);
        final startOfNextDay = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day + 1,
        );

        beforeQuery = readingsCol.where(
          'date',
          isLessThan: Timestamp.fromDate(cutoff),
        );
        nextQuery = readingsCol.where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfNextDay),
        );
      }

      final results = await Future.wait([
        beforeQuery.orderBy('date', descending: true).limit(1).get(),
        nextQuery.orderBy('date').limit(1).get(),
        _loadMonthToDateKwhBefore(uid, selectedDate),
      ]);

      final beforeSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
      final nextSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final monthToDateBefore = results[2] as double;

      final before = beforeSnap.docs.isEmpty
          ? null
          : _parse(beforeSnap.docs.first);
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
        monthToDateKwhBeforeThisReading: monthToDateBefore,
        readingError: _validateReading(
          reading: state.currentReading,
          lastReading: before?.reading ?? 0,
          nextReading: next?.reading,
          lastDate: before?.date,
          nextDate: next?.date,
        ),
      );
    } on FirebaseException catch (e, st) {
      logError(
        'Failed to load surrounding readings (Firebase)',
        e,
        st,
        context: {
          'selected_date': selectedDate.toIso8601String(),
          'is_editing': _editingDate != null,
        },
      );

      if (requestId == _loadRequestId) {
        state = state.copyWith(isLoadingLastReading: false);
      }
    } on Exception catch (e, st) {
      logError(
        'Failed to load surrounding readings',
        e,
        st,
        context: {
          'selected_date': selectedDate.toIso8601String(),
          'is_editing': _editingDate != null,
        },
      );
      if (requestId == _loadRequestId) {
        state = state.copyWith(isLoadingLastReading: false);
      }
    }
  }

  Future<double> _loadMonthToDateKwhBefore(
    String uid,
    DateTime selectedDate,
  ) async {
    final startOfMonth = DateTime(selectedDate.year, selectedDate.month);
    final cutoff = _editingDate ?? _cutoffFor(selectedDate);

    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('readings')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(cutoff))
        .get();

    return snap.docs
        .where((d) => d.id != _editingReadingId)
        .fold<double>(
          0,
          (total, d) => total + ((d.data()['kwh'] as num?)?.toDouble() ?? 0),
        );
  }

  ({double reading, DateTime date, String id}) _parse(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return (
      reading: (data['reading'] as num?)?.toDouble() ?? 0,
      date: (data['date'] as Timestamp).toDate(),
      id: doc.id,
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

  Future<bool> _applyChainFixAndRecalculate(
    String uid,
    DateTime date,
    TariffType tariffType,
  ) async {
    final next = await _chainService.findNext(uid, date);
    if (next != null) {
      final fix = _chainService.computeFix(next, state.currentReading);
      final batch = _firestore.batch();
      _chainService.applyFix(batch, uid, fix);
      await batch.commit();

      final sameMonth =
          fix.date.year == date.year && fix.date.month == date.month;
      if (!sameMonth) {
        await _billService.recalculateMonth(uid, fix.date, fix.tariffType);
      }
    }
    await _billService.recalculateMonth(uid, date, tariffType);
    return true;
  }

  Future<bool> saveReading() async {
    if (!state.canSave) return false;
    final uid = ref.read(currentUidProvider).value;

    if (uid == null) {
      state = state.copyWith(
        errorMessage: 'Session expired. Please sign in again.',
      );
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    final date = state.selectedDate ?? DateTime.now();
    final tariffType = ref.read(tariffTypeProvider);

    try {
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

      await _applyChainFixAndRecalculate(uid, date, tariffType);

      state = state.copyWith(isSaving: false);
      return true;
    } on FirebaseException catch (e, st) {
      logError(
        'Failed to save reading (Firebase)',
        e,
        st,
        context: {
          'reading_value': state.currentReading,
          'kwh': state.usageKwh,
          'date': date.toIso8601String(),
          'tariff_type': tariffType.value,
        },
      );
      state = state.copyWith(
        isSaving: false,
        errorMessage: mapFirebaseError(e.code),
      );
      return false;
    } on Exception catch (e, st) {
      logError(
        'Failed to save reading',
        e,
        st,
        context: {
          'reading_value': state.currentReading,
          'kwh': state.usageKwh,
          'date': date.toIso8601String(),
          'tariff_type': tariffType.value,
        },
      );
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save reading. Please try again.',
      );
      return false;
    }
  }

  Future<bool> updateReading(ReadingRecord reading) async {
    if (!state.canSave) return false;

    final uid = ref.read(currentUidProvider).value;
    if (uid == null) {
      state = state.copyWith(errorMessage: 'Session expired.');
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      // date is fixed in edit mode, never changes
      final date = reading.date;

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('readings')
          .doc(reading.id)
          .update({
            'reading': state.currentReading,
            'kwh': state.usageKwh,
            'notes': state.notes.trim(),
            'tier': state.currentTier(reading.tariffType),
          });

      await _applyChainFixAndRecalculate(uid, date, reading.tariffType);

      state = state.copyWith(isSaving: false);
      return true;
    } on FirebaseException catch (e, st) {
      logError(
        'Failed to update reading (Firebase)',
        e,
        st,
        context: {
          'reading_value': state.currentReading,
          'kwh': state.usageKwh,
        },
      );
      state = state.copyWith(
        isSaving: false,
        errorMessage: mapFirebaseError(e.code),
      );
      return false;
    } on Exception catch (e, st) {
      logError(
        'Failed to update reading',
        e,
        st,
        context: {
          'reading_value': state.currentReading,
          'kwh': state.usageKwh,
        },
      );
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to update reading. Please try again.',
      );
      return false;
    }
  }
}
