import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/models/bill_record.dart';
import 'package:energy_tracker/models/reading_record.dart';
import 'package:energy_tracker/ui/features/ft_bill_detail/notifier/bill_detail_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    state = state.copyWith(
      bill: bill,
      isPaid: bill.isPaid,
    );

    await _loadReadings(bill);
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

      state = state.copyWith(isLoading: false, readings: readings);
    } on FirebaseException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load readings: ${e.message}',
      );
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

    final updatedReadings =
        state.readings.where((r) => r.id != reading.id).toList();

    final totalKwh = updatedReadings.fold<double>(
      0,
      (sum, r) => sum + r.kwh,
    );

    state = state.copyWith(
      readings: updatedReadings,
      bill: state.bill!.copyWith(
        kwh: totalKwh,
        amount: TariffRates.calculateDomestic(totalKwh),
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

      final billSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('bills')
          .where('date', isEqualTo: Timestamp.fromDate(reading.date))
          .get();

      for (final doc in billSnap.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      return true;
    } on FirebaseException catch (_) {
      state = previousState;
      return false;
    }
  }
}
