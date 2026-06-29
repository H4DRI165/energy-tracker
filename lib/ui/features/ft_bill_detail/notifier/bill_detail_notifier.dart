import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:energy_tracker/models/bill_record.dart';
import 'package:energy_tracker/models/reading_record.dart';
import 'package:energy_tracker/ui/components/logger.dart';
import 'package:energy_tracker/ui/features/ft_bill_detail/notifier/bill_detail_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final NotifierProvider<BillDetailNotifier, BillDetailPageState>
    billDetailProvider =
    NotifierProvider.autoDispose<BillDetailNotifier, BillDetailPageState>(
  BillDetailNotifier.new,
);

class BillDetailNotifier extends Notifier<BillDetailPageState> {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

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
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      state =
          state.copyWith(isLoading: false, errorMessage: 'Session expired.');
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
    final uid = _auth.currentUser?.uid;
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
        monthYear:
            DateFormat('MMM yyyy').format((data['date'] as Timestamp).toDate()),
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
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    state = state.copyWith(isUpdatingPaid: true);
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
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final previousState = state;

    final sortedBefore = [...state.readings]
      ..sort((a, b) => a.date.compareTo(b.date));
    final deletedIndex = sortedBefore.indexWhere((r) => r.id == reading.id);
    final remaining = sortedBefore.where((r) => r.id != reading.id).toList();

    // Determine if the deleted reading's next-neighbour needs its kwh
    // recomputed against its new previous reading.
    ReadingRecord? fixedNext;
    final hadNext = deletedIndex >= 0 && deletedIndex < sortedBefore.length - 1;
    if (hadNext) {
      final next = sortedBefore[deletedIndex + 1];
      final hadPrevious = deletedIndex > 0;

      final double newKwh;
      if (!hadPrevious) {
        // The deleted reading had no previous reading — it WAS the baseline.
        // Its next-neighbors now becomes the new baseline, not a delta
        // against an assumed-zero meter value.
        newKwh = 0;
      } else {
        final newPreviousValue = sortedBefore[deletedIndex - 1].reading;
        newKwh = (next.reading - newPreviousValue)
            .clamp(0, double.infinity)
            .toDouble();
      }

      final tariffType = next.tariffType;
      fixedNext = ReadingRecord(
        id: next.id,
        reading: next.reading,
        kwh: newKwh,
        date: next.date,
        notes: next.notes,
        estimatedBill: next.estimatedBill,
        tier: TariffRates.getTier(newKwh, tariffType),
        tariffType: tariffType,
      );
    }

    final finalReadingsAscending = remaining
        .map((r) => fixedNext != null && r.id == fixedNext.id ? fixedNext : r)
        .toList();

    final totalKwh =
        finalReadingsAscending.fold<double>(0, (total, r) => total + r.kwh);
    final remainingTariffType = finalReadingsAscending.isEmpty
        ? bill.tariffType
        : finalReadingsAscending.last.tariffType;

    final finalReadingsDescending = [...finalReadingsAscending]
      ..sort((a, b) => b.date.compareTo(a.date));

    state = state.copyWith(
      readings: finalReadingsDescending,
      bill: state.bill!.copyWith(
        kwh: totalKwh,
        amount: TariffRates.calculate(totalKwh, remainingTariffType),
        tariffType: remainingTariffType,
      ),
    );

    try {
      final batch = _firestore.batch()
        ..delete(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('readings')
              .doc(reading.id),
        );

      if (fixedNext != null) {
        batch.update(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('readings')
              .doc(fixedNext.id),
          {'kwh': fixedNext.kwh, 'tier': fixedNext.tier},
        );
      }

      final billRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('bills')
          .doc(bill.id);

      if (finalReadingsAscending.isEmpty) {
        batch.delete(billRef);
      } else {
        batch.update(billRef, {
          'kwh': totalKwh,
          'amount': TariffRates.calculate(totalKwh, remainingTariffType),
          'tier': TariffRates.getTier(totalKwh, remainingTariffType),
          'tariffType': remainingTariffType.value,
        });
      }

      await batch.commit();
      return true;
    } on FirebaseException catch (_) {
      state = previousState;
      return false;
    }
  }
}
