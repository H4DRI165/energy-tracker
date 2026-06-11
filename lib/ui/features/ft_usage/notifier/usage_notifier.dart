import 'package:cloud_firestore/cloud_firestore.dart';
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
      final billHistory = billsSnap.docs.map((doc) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        return BillRecord(
          id: doc.id,
          monthYear: DateFormat('MMM yyyy').format(date),
          kwh: (data['kwh'] as num?)?.toDouble() ?? 0,
          amount: (data['amount'] as num?)?.toDouble() ?? 0,
          isPaid: data['isPaid'] as bool? ?? true,
          date: date,
        );
      }).toList();

      // Current month data
      final currentMonthReadings = readingsSnap.docs.where((doc) {
        final date = (doc.data()['date'] as Timestamp).toDate();
        return date.year == now.year && date.month == now.month;
      }).toList();

      final currentKwh = currentMonthReadings.fold<double>(0, (total, doc) {
        final kwh = (doc.data()['kwh'] as num?)?.toDouble() ?? 0;
        return total + kwh;
      });

      final currentBill = _calculateBill(currentKwh);
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
          bill: _calculateBill(kwh),
          isPaid: i > 0,
        ),
      );
    }
    return result;
  }

  double _calculateBill(double kwh) {
    if (kwh <= 0) return 0;
    double bill = 0;
    bill += kwh.clamp(0, 200) * 0.218;
    if (kwh > 200) bill += (kwh - 200).clamp(0, 100) * 0.334;
    if (kwh > 300) bill += (kwh - 300).clamp(0, 300) * 0.516;
    if (kwh > 600) bill += (kwh - 600) * 0.546;
    return bill < 3.0 ? 3.0 : bill;
  }
}
