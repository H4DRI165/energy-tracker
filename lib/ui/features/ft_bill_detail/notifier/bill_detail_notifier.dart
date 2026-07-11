import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:energy_tracker/models/bill_record.dart';
import 'package:energy_tracker/models/reading_record.dart';
import 'package:energy_tracker/services/auth/providers/current_uid_provider.dart';
import 'package:energy_tracker/services/billing/bill_recalculation_service.dart';
import 'package:energy_tracker/services/billing/reading_chain_service.dart';
import 'package:energy_tracker/ui/components/utils/logger.dart';
import 'package:energy_tracker/ui/features/ft_bill_detail/notifier/bill_detail_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final NotifierProvider<BillDetailNotifier, BillDetailPageState>
billDetailProvider =
    NotifierProvider.autoDispose<BillDetailNotifier, BillDetailPageState>(
      BillDetailNotifier.new,
    );

class BillDetailNotifier extends Notifier<BillDetailPageState> {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  late final ReadingChainService _chainService = ReadingChainService(
    _firestore,
  );
  late final BillRecalculationService _billService = BillRecalculationService(
    _firestore,
  );

  @override
  BillDetailPageState build() {
    return const BillDetailPageState();
  }

  Future<void> init(BillRecord bill) async {
    BillRecord? freshBill;
    try {
      freshBill = await _loadBill(bill.id);
    } on Exception catch (e, st) {
      AppLogger.error('Failed to load fresh bill ${bill.id}', e, st);
      freshBill = null;
    }

    final resolvedBill = freshBill ?? bill;

    state = state.copyWith(
      bill: resolvedBill,
      isPaid: resolvedBill.isPaid,
    );

    try {
      await _loadReadings(resolvedBill);
    } on Exception catch (e, st) {
      AppLogger.error('Failed to load readings for ${resolvedBill.id}', e, st);
    }
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
          .get();

      final readings = snap.docs.map((doc) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final rawTariffType = data['tariffType'] as String?;
        return ReadingRecord(
          id: doc.id,
          reading: (data['reading'] as num?)?.toDouble() ?? 0,
          kwh: (data['kwh'] as num?)?.toDouble() ?? 0,
          date: date,
          notes: data['notes'] as String? ?? '',
          estimatedBill: (data['estimatedBill'] as num?)?.toDouble() ?? 0,
          tier: (data['tier'] as num?)?.toInt() ?? 1,
          tariffType: rawTariffType == null
              ? bill.tariffType
              : TariffTypeX.fromValue(rawTariffType),
        );
      }).toList();

      state = state.copyWith(isLoading: false, readings: readings);
    } on FirebaseException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load readings: ${e.message}',
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
        isPaid: data['isPaid'] as bool? ?? false,
        tariffType: TariffTypeX.fromValue(
          data['tariffType'] as String? ?? TariffType.domestic.value,
        ),
        date: (data['date'] as Timestamp).toDate(),
      );
    } on FirebaseException catch (e, st) {
      AppLogger.error('Firestore error loading bill $billId', e, st);
      return null;
    }
  }

  Future<void> togglePaid(BillRecord bill) async {
    final uid = ref.read(currentUidProvider).value;
    if (uid == null) return;

    state = state.copyWith(isUpdatingPaid: true, errorMessage: null);
    final newIsPaid = !state.isPaid;

    try {
      final startOfMonth = DateTime(bill.date.year, bill.date.month);
      final endOfMonth = DateTime(bill.date.year, bill.date.month + 1);

      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('bills')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
          .get();

      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isPaid': newIsPaid});
      }
      await batch.commit();

      state = state.copyWith(isUpdatingPaid: false, isPaid: newIsPaid);
    } on FirebaseException catch (e) {
      state = state.copyWith(
        isUpdatingPaid: false,
        errorMessage: 'Failed to update payment status: ${e.message}',
      );
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
        _chainService.applyFix(batch, uid, fix);
      }

      await batch.commit();
      committed = true;

      await _billService.recalculateMonth(uid, reading.date, bill.tariffType);

      final fixInDifferentMonth =
          fix != null &&
          (fix.date.year != reading.date.year ||
              fix.date.month != reading.date.month);
      if (fixInDifferentMonth) {
        await _billService.recalculateMonth(uid, fix.date, fix.tariffType);
      }

      // Local state can no longer be cheaply patched given possible
      // cross-month effects — reload from source of truth.
      final freshBill = await _loadBill(bill.id);
      if (freshBill != null) {
        state = state.copyWith(bill: freshBill, isPaid: freshBill.isPaid);
        await _loadReadings(freshBill);
      } else {
        state = state.copyWith(
          readings: const [],
          billDeleted: true,
        );
      }

      return true;
    } on Exception catch (e, st) {
      if (!committed) {
        state = previousState;
        AppLogger.error('Failed to delete reading ${reading.id}', e, st);
        return false;
      }

      AppLogger.error('Failed to refresh bill after deleting reading', e, st);
      state = state.copyWith(
        errorMessage: 'Reading deleted, but failed to refresh the bill.',
      );
      return true;
    }
  }
}
