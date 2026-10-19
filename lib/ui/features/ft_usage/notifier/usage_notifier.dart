import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/models/bill_record.dart';
import 'package:energy_tracker/models/reading_record.dart';
import 'package:energy_tracker/services/auth/providers/current_uid_provider.dart';
import 'package:energy_tracker/services/billing/usage_allocation_service.dart';
import 'package:energy_tracker/services/notifier/user_profile_notifier.dart';
import 'package:energy_tracker/ui/components/logging/notifier/loggable_notifier.dart';
import 'package:energy_tracker/ui/features/ft_usage/notifier/usage_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final AsyncNotifierProvider<UsageNotifier, UsageState> usageProvider =
    AsyncNotifierProvider<UsageNotifier, UsageState>(
      UsageNotifier.new,
    );

class UsageNotifier extends AsyncNotifier<UsageState>
    with LoggableNotifier<UsageState> {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  String get screenName => 'UsagePage';

  @override
  Future<UsageState> build() async {
    final uid = ref.watch(currentUidProvider).value;
    if (uid == null) return const UsageState();

    final monthlyBudget =
        ref.watch(userProfileProvider).profile?.monthlyBudget ?? 0;
    final selectedFilter = state.value?.filter ?? UsageFilter.monthly;
    final fresh = await _fetchUsageData(uid);
    return fresh.copyWith(
      filter: selectedFilter,
      monthlyBudget: monthlyBudget,
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<UsageState> _fetchUsageData(String uid) async {
    final now = DateTime.now();

    final results = await Future.wait([
      _firestore
          .collection('users')
          .doc(uid)
          .collection('readings')
          .orderBy('date', descending: false)
          .get(),
      _firestore
          .collection('users')
          .doc(uid)
          .collection('bills')
          .orderBy('date', descending: true)
          .limit(12)
          .get(),
    ]);
    final readingsSnap = results[0];
    final billsSnap = results[1];

    final billHistory = _buildBillHistory(billsSnap.docs);
    final readings = readingsSnap.docs
        .map((doc) => ReadingRecord.fromDoc(doc.id, doc.data()))
        .toList();
    final allocations = UsageAllocationService.monthly(
      readings: readings,
      from: DateTime(now.year, now.month - 11),
      to: now,
    );

    final monthlyData = allocations.map((allocation) {
      final month = DateTime(allocation.year, allocation.month);
      return MonthlyUsage(
        month: DateFormat('MMM').format(month),
        year: allocation.year,
        kwh: allocation.kwh,
        bill: TariffRates.calculate(
          allocation.kwh,
          billingMonth: month,
        ),
        isEstimated: allocation.isEstimated,
      );
    }).toList();
    final current = allocations.last;
    final currentKwh = current.kwh;
    final currentBill = TariffRates.calculate(
      currentKwh,
      billingMonth: now,
    );
    final currentMonthLabel = DateFormat('MMMM yyyy').format(now);

    return UsageState(
      monthlyData: monthlyData,
      billHistory: billHistory,
      currentKwh: currentKwh,
      currentBill: currentBill,
      currentMonthLabel: currentMonthLabel,
      readingCount: readings.length,
    );
  }

  void setFilter(UsageFilter filter) {
    state = state.whenData((s) => s.copyWith(filter: filter));
  }

  List<BillRecord> _buildBillHistory(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final formatter = DateFormat('MMM yyyy');

    return docs.map((doc) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();

      return BillRecord(
        id: doc.id,
        monthYear: formatter.format(date),
        kwh: (data['kwh'] as num?)?.toDouble() ?? 0,
        amount: (data['amount'] as num?)?.toDouble() ?? 0,
        date: date,
        isEstimated: data['isEstimated'] as bool? ?? false,
      );
    }).toList();
  }

  Future<void> deleteMonth(BillRecord bill) async {
    final uid = ref.read(currentUidProvider).value;
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
                      )
                    : m,
              )
              .toList(),
          readingCount: (s.readingCount - results[0].docs.length)
              .clamp(0, s.readingCount)
              .toInt(),
        ),
      );
    } on FirebaseException catch (e, st) {
      logError(
        'Failed to delete month (Firebase)',
        e,
        st,
        context: {'bill_id': bill.id, 'month_year': bill.monthYear},
      );
      // Re-fetch on error to ensure UI reflects actual server state
      state = const AsyncLoading();
      state = await AsyncValue.guard(() => _fetchUsageData(uid));
    } on Exception catch (e, st) {
      logError(
        'Failed to delete month',
        e,
        st,
        context: {'bill_id': bill.id, 'month_year': bill.monthYear},
      );
      state = const AsyncLoading();
      state = await AsyncValue.guard(() => _fetchUsageData(uid));
    }
  }
}
