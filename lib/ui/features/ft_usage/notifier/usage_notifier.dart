import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/models/bill_record.dart';
import 'package:energy_tracker/ui/features/ft_usage/notifier/usage_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final AsyncNotifierProvider<UsageNotifier, UsageState> usageProvider =
    AsyncNotifierProvider<UsageNotifier, UsageState>(
  UsageNotifier.new,
);

class UsageNotifier extends AsyncNotifier<UsageState> {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  Future<UsageState> build() async {
    return _fetchUsageData();
  }

  Future<UsageState> _fetchUsageData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const UsageState();

    final now = DateTime.now();

    try {
      // Fetch readings for the past 12 months
      final startOf12MonthsAgo = DateTime(now.year - 1, now.month);

      final readingsSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('readings')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOf12MonthsAgo),
          )
          .orderBy('date', descending: false)
          .get();

      final billsSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('bills')
          .orderBy('date', descending: true)
          .limit(12)
          .get();

      final monthlyData = _buildMonthlyData(readingsSnap.docs, now);
      final billHistory = _buildBillHistory(billsSnap.docs);

      // Current month data
      final currentMonthReadings = readingsSnap.docs.where((doc) {
        final date = (doc.data()['date'] as Timestamp).toDate();
        return date.year == now.year && date.month == now.month;
      }).toList();

      final currentKwh = currentMonthReadings.fold<double>(0, (total, doc) {
        return total + ((doc.data()['kwh'] as num?)?.toDouble() ?? 0);
      });

      final currentBill = TariffRates.calculateDomestic(currentKwh);
      final currentMonthLabel = DateFormat('MMMM yyyy').format(now);

      return UsageState(
        monthlyData: monthlyData,
        billHistory: billHistory,
        currentKwh: currentKwh,
        currentBill: currentBill,
        currentMonthLabel: currentMonthLabel,
      );
    } on FirebaseException catch (e) {
      throw Exception('Failed to load usage: ${e.message}');
    }
  }

  void setFilter(UsageFilter filter) {
    state = state.whenData((s) => s.copyWith(filter: filter));
  }

  Future<void> refresh() async {
    final selectedFilter = state.asData?.value.filter ?? UsageFilter.monthly;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final fresh = await _fetchUsageData();
      return fresh.copyWith(filter: selectedFilter);
    });
  }

  List<MonthlyUsage> _buildMonthlyData(
    List<QueryDocumentSnapshot> docs,
    DateTime now,
  ) {
    final monthlyMap = <String, double>{};

    for (final doc in docs) {
      final data = doc.data()! as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final key = DateFormat('MMM-yyyy').format(date);
      final kwh = (data['kwh'] as num?)?.toDouble() ?? 0;
      monthlyMap[key] = (monthlyMap[key] ?? 0) + kwh;
    }

    final result = <MonthlyUsage>[];
    for (var i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final key = DateFormat('MMM-yyyy').format(month);
      final kwh = monthlyMap[key] ?? 0;

      result.add(
        MonthlyUsage(
          month: DateFormat('MMM').format(month),
          year: month.year,
          kwh: kwh,
          bill: TariffRates.calculateDomestic(kwh),
          isPaid: i > 0,
        ),
      );
    }
    return result;
  }

  List<BillRecord> _buildBillHistory(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final byMonth = <String, ({double kwh, DateTime date, bool isPaid})>{};

    for (final doc in docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final kwh = (data['kwh'] as num?)?.toDouble() ?? 0;
      final docIsPaid = data['isPaid'] as bool? ?? false;

      if (byMonth.containsKey(key)) {
        byMonth[key] = (
          kwh: byMonth[key]!.kwh + kwh,
          date: byMonth[key]!.date,
          isPaid: byMonth[key]!.isPaid && docIsPaid,
        );
      } else {
        byMonth[key] = (kwh: kwh, date: date, isPaid: docIsPaid);
      }
    }

    return byMonth.entries.map((e) {
      final totalKwh = e.value.kwh;
      final amount = TariffRates.calculateDomestic(totalKwh);

      return BillRecord(
        id: e.key,
        monthYear: DateFormat('MMM yyyy').format(e.value.date),
        kwh: totalKwh,
        amount: amount,
        isPaid: e.value.isPaid,
        date: e.value.date,
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> deleteMonth(BillRecord bill) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final startOfMonth = DateTime(bill.date.year, bill.date.month);
    final endOfMonth = DateTime(bill.date.year, bill.date.month + 1);

    try {
      // Fetch all readings and bills for this month
      final results = await Future.wait([
        _firestore
            .collection('users')
            .doc(uid)
            .collection('readings')
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
            )
            .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
            .get(),
        _firestore
            .collection('users')
            .doc(uid)
            .collection('bills')
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
            )
            .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
            .get(),
      ]);

      final batch = _firestore.batch();

      for (final doc in results[0].docs) {
        batch.delete(doc.reference);
      }

      for (final doc in results[1].docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Remove from local state without re-fetching
      state = state.whenData(
        (s) => s.copyWith(
          billHistory: s.billHistory.where((b) => b.id != bill.id).toList(),
          monthlyData: s.monthlyData
              .map(
                (m) => m.monthYear == bill.monthYear
                    ? MonthlyUsage(
                        month: m.month,
                        year: m.year,
                        kwh: 0,
                        bill: 0,
                        isPaid: false,
                      )
                    : m,
              )
              .toList(),
        ),
      );
    } on FirebaseException catch (_) {
      // Re-fetch on error
      state = const AsyncLoading();
      state = await AsyncValue.guard(_fetchUsageData);
    }
  }
}
