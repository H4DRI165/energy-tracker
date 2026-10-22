import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/models/reading_record.dart';
import 'package:energy_tracker/services/auth/providers/current_uid_provider.dart';
import 'package:energy_tracker/services/billing/usage_allocation_service.dart';
import 'package:energy_tracker/ui/components/logging/app_logger.dart';
import 'package:energy_tracker/ui/components/logging/notifier/loggable_notifier.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardPageState>(
      DashboardNotifier.new,
    );

class DashboardNotifier extends AsyncNotifier<DashboardPageState>
    with LoggableNotifier<DashboardPageState> {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  String get screenName => 'DashboardPage';

  @override
  Future<DashboardPageState> build() async {
    final uid = ref.watch(currentUidProvider).value;
    if (uid == null) return DashboardPageState();

    final authName = _auth.currentUser?.displayName ?? '';
    final results = await Future.wait([
      _loadUserProfile(uid, authName),
      _loadUsageData(uid),
    ]);

    return results[0].merge(results[1]);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<DashboardPageState> _loadUserProfile(
    String uid,
    String authName,
  ) async {
    try {
      final authFirstName = authName.isNotEmpty
          ? authName.split(' ').first
          : '';

      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return DashboardPageState(userName: authFirstName);

      final data = doc.data()!;
      final rawName = data['fullName'];
      final fullName = rawName is String ? rawName : authName;
      final firstName = fullName.isNotEmpty
          ? fullName.split(' ').first
          : authFirstName;
      final rawBudget = data['monthlyBudget'];
      final budget = rawBudget is num ? rawBudget.toDouble() : 150.0;

      return DashboardPageState(userName: firstName, monthlyBudget: budget);
    } on FirebaseException catch (e, st) {
      logError(
        'Failed to load user profile (Firebase)',
        e,
        st,
      );
      return DashboardPageState(errorMessage: mapFirebaseError(e.code));
    } on Object catch (e, st) {
      logError('Failed to load user profile', e, st);
      return DashboardPageState(errorMessage: 'Failed to load profile.');
    }
  }

  Future<DashboardPageState> _loadUsageData(String uid) async {
    try {
      final now = DateTime.now();
      final monthLabel = DateFormat('MMMM yyyy').format(now);
      final daysLeft = DateUtils.getDaysInMonth(now.year, now.month) - now.day;

      final startOfMonth = DateTime(now.year, now.month);
      final startOf7DayWindow = DateTime(now.year, now.month, now.day - 6);
      final startOfLastMonth = DateTime(now.year, now.month - 1);
      final lastMonthDays = DateUtils.getDaysInMonth(
        startOfLastMonth.year,
        startOfLastMonth.month,
      );
      final comparisonDay = now.day > lastMonthDays ? lastMonthDays : now.day;

      final readingsSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('readings')
          .orderBy('date', descending: false)
          .get();
      final readings = readingsSnap.docs
          .map((doc) => ReadingRecord.fromDoc(doc.id, doc.data()))
          .toList();

      final currentAllocations = UsageAllocationService.monthly(
        readings: readings,
        from: startOfMonth,
        to: now,
      );
      final kwhUsed = currentAllocations.first.kwh;

      // Compare like with like: the same calendar days from last month.
      final lastMonthAllocations = UsageAllocationService.monthly(
        readings: readings,
        from: startOfLastMonth,
        to: DateTime(
          startOfLastMonth.year,
          startOfLastMonth.month,
          comparisonDay,
        ),
      );
      final lastMonthKwh = lastMonthAllocations.first.kwh;

      final weeklyKwh = UsageAllocationService.dailyKwh(
        readings: readings,
        from: startOf7DayWindow,
        to: now,
      );

      final percentVsLast = lastMonthKwh > 0
          ? ((kwhUsed - lastMonthKwh) / lastMonthKwh) * 100
          : 0.0;

      final bill = TariffRates.calculate(kwhUsed, billingMonth: now);
      final eeiBand = TariffRates.getEeiBand(kwhUsed);

      final daysElapsed = now.day;
      final dailyAvg = daysElapsed > 0 ? kwhUsed / daysElapsed : 0.0;

      final projectedKwh =
          dailyAvg * DateUtils.getDaysInMonth(now.year, now.month);
      final projectedBill = kwhUsed > 0
          ? TariffRates.calculate(projectedKwh, billingMonth: now)
          : null;
      final weeklyUsage = _buildWeeklyUsage(weeklyKwh, now);

      return DashboardPageState(
        monthLabel: monthLabel,
        kwhUsed: kwhUsed,
        estimatedBill: bill,
        currentEeiBand: eeiBand,
        dailyAvg: dailyAvg,
        daysLeft: daysLeft,
        percentageVsLastMonth: percentVsLast,
        projectedBill: projectedBill,
        projectedKwh: projectedBill == null ? null : projectedKwh,
        weeklyUsage: weeklyUsage,
        readingCount: readings.length,
      );
    } on FirebaseException catch (e, st) {
      logError('Failed to load usage data (Firebase)', e, st);
      return DashboardPageState(errorMessage: mapFirebaseError(e.code));
    } on Object catch (e, st) {
      logError('Failed to load usage data', e, st);
      return DashboardPageState(
        errorMessage: 'Failed to load usage data.',
      );
    }
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  List<DailyUsage> _buildWeeklyUsage(
    Map<String, double> kwhByDate,
    DateTime now,
  ) {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final result = <DailyUsage>[];

    for (var i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final label = i == 0 ? 'Today' : dayLabels[day.weekday - 1];
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}';
      final kwh = kwhByDate[key] ?? 0.0;

      result.add(DailyUsage(label: label, kwh: kwh, isToday: i == 0));
    }

    return result;
  }
}
