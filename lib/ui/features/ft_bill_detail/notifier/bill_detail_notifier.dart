import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/models/bill_record.dart';
import 'package:energy_tracker/models/reading_record.dart';
import 'package:energy_tracker/services/auth/providers/current_uid_provider.dart';
import 'package:energy_tracker/services/billing/bill_recalculation_service.dart';
import 'package:energy_tracker/services/billing/reading_chain_service.dart';
import 'package:energy_tracker/ui/components/logging/app_logger.dart';
import 'package:energy_tracker/ui/components/logging/notifier/loggable_notifier.dart';
import 'package:energy_tracker/ui/features/ft_bill_detail/notifier/bill_detail_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final NotifierProvider<BillDetailNotifier, BillDetailPageState>
billDetailProvider =
    NotifierProvider.autoDispose<BillDetailNotifier, BillDetailPageState>(
      BillDetailNotifier.new,
    );

extension ReadingRecordListX on List<ReadingRecord> {
  // sum of all kwh to get tier
  Map<String, String> cumulativeTierLabels() {
    final sorted = [...this]..sort((a, b) => a.date.compareTo(b.date));
    var runningKwh = 0.0;
    final labels = <String, String>{};

    for (final r in sorted) {
      runningKwh += r.kwh;
      final band = TariffRates.getEeiBand(runningKwh);
      labels[r.id] = band.number == 0 ? 'No rebate' : band.label;
    }
    return labels;
  }
}

class BillDetailNotifier extends Notifier<BillDetailPageState>
    with LoggableNotifier<BillDetailPageState> {
  /// A strict user taking four readings a day needs at most 124 per month.
  /// 150 leaves headroom while keeping the monthly query bounded.
  static const int maxReadingsPerMonth = 150;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  late final ReadingChainService _chainService = ReadingChainService(
    _firestore,
  );
  late final BillRecalculationService _billService = BillRecalculationService(
    _firestore,
  );

  @override
  String get screenName => 'BillDetailPage';

  @override
  BillDetailPageState build() {
    return const BillDetailPageState();
  }

  Future<void> init(String billId) async {
    final freshBill = await _loadBill(billId);

    if (freshBill == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Bill not found.',
      );
      return;
    }

    state = state.copyWith(bill: freshBill);

    await _loadReadings(freshBill);
  }

  Future<void> _loadReadings(BillRecord bill) async {
    final uid = ref.read(currentUidProvider).value;
    if (uid == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Session expired.',
      );
      return;
    }

    try {
      final startOfMonth = DateTime(bill.date.year, bill.date.month);
      final endOfMonth = DateTime(bill.date.year, bill.date.month + 1);

      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('readings')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
          .orderBy('date', descending: true)
          .limit(maxReadingsPerMonth + 1)
          .get();

      final hasMoreReadings = snap.docs.length > maxReadingsPerMonth;
      final readingDocs = hasMoreReadings
          ? snap.docs.take(maxReadingsPerMonth)
          : snap.docs;

      final readings = readingDocs.map((doc) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        return ReadingRecord(
          id: doc.id,
          reading: (data['reading'] as num?)?.toDouble() ?? 0,
          kwh: (data['kwh'] as num?)?.toDouble() ?? 0,
          date: date,
          notes: data['notes'] as String? ?? '',
          estimatedBill: (data['estimatedBill'] as num?)?.toDouble() ?? 0,
          tier: (data['tier'] as num?)?.toInt() ?? 1,
        );
      }).toList();

      state = state.copyWith(
        isLoading: false,
        readings: readings,
        hasMoreReadings: hasMoreReadings,
      );
    } on FirebaseException catch (e, st) {
      logError(
        'Failed to load readings (Firebase)',
        e,
        st,
        context: {'bill_id': bill.id},
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: mapFirebaseError(e.code),
      );
    } on Exception catch (e, st) {
      logError(
        'Failed to load readings',
        e,
        st,
        context: {'bill_id': bill.id},
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load readings. Please try again.',
      );
    }
  }

  Future<BillRecord?> _loadBill(String billId) async {
    final uid = ref.read(currentUidProvider).value;
    if (uid == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('bills')
          .doc(billId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;

      return BillRecord(
        id: doc.id,
        monthYear: DateFormat(
          'MMM yyyy',
        ).format((data['date'] as Timestamp).toDate()),
        kwh: (data['kwh'] as num).toDouble(),
        amount: (data['amount'] as num).toDouble(),
        date: (data['date'] as Timestamp).toDate(),
        isEstimated: data['isEstimated'] as bool? ?? false,
      );
    } on FirebaseException catch (e, st) {
      logError(
        'Failed to load bill (Firebase)',
        e,
        st,
        context: {'bill_id': billId},
      );
      return null;
    } on Exception catch (e, st) {
      logError(
        'Failed to load bill',
        e,
        st,
        context: {'bill_id': billId},
      );
      return null;
    }
  }

  Future<bool> deleteReading(ReadingRecord reading, BillRecord bill) async {
    final uid = ref.read(currentUidProvider).value;
    if (uid == null) return false;

    final previousState = state;

    // update widget tree update on Dismissible's
    state = state.copyWith(
      readings: state.readings.where((r) => r.id != reading.id).toList(),
      errorMessage: null,
    );

    var committed = false;
    try {
      final results = await Future.wait([
        _chainService.findPrevious(uid, reading.date),
        _chainService.findNext(uid, reading.date),
      ]);
      final previous = results[0];
      final next = results[1];

      final batch = _firestore.batch()
        ..delete(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('readings')
              .doc(reading.id),
        );

      ChainFixResult? fix;
      if (next != null) {
        // If there's no previous reading, the deleted reading WAS the
        // baseline — next becomes the new baseline (kwh: 0).
        fix = _chainService.computeFix(next, previous?.reading);
        _chainService.applyFix(
          batch,
          uid,
          fix,
          periodStart: previous?.date,
        );
      }

      await batch.commit();
      committed = true;

      final from = previous?.date ?? reading.date;
      final to = next?.date ?? reading.date;
      await _billService.recalculateRange(uid, from, to);

      // Local state can no longer be cheaply patched given possible
      // cross-month effects — reload from source of truth.
      final freshBill = await _loadBill(bill.id);
      if (freshBill != null) {
        state = state.copyWith(bill: freshBill);
        await _loadReadings(freshBill);
      } else {
        state = state.copyWith(
          readings: const [],
          billDeleted: true,
        );
      }

      return true;
    } on FirebaseException catch (e, st) {
      _logDeleteFailure(
        e,
        st,
        reading,
        bill,
        committed: committed,
        firebaseCode: e.code,
      );

      if (!committed) {
        state = state.copyWith(
          errorMessage: "Couldn't delete the reading. Please try again.",
        );
        return false;
      }
      state = state.copyWith(errorMessage: mapFirebaseError(e.code));
      return true;
    } on Exception catch (e, st) {
      _logDeleteFailure(e, st, reading, bill, committed: committed);

      if (!committed) {
        state = previousState;
        return false;
      }

      state = state.copyWith(
        errorMessage: 'Reading deleted, but failed to refresh the bill.',
      );
      return true;
    }
  }

  void _logDeleteFailure(
    Object error,
    StackTrace stackTrace,
    ReadingRecord reading,
    BillRecord bill, {
    required bool committed,
    String? firebaseCode,
  }) {
    final suffix = firebaseCode != null ? ' (Firebase)' : '';
    final message = committed
        ? 'Failed to refresh bill after deleting reading$suffix'
        : 'Failed to delete reading$suffix';

    logError(
      message,
      error,
      stackTrace,
      context: {'reading_id': reading.id, 'bill_id': bill.id},
    );
  }
}
