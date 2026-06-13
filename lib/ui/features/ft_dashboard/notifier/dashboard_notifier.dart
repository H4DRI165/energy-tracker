import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardPageState>(
  DashboardNotifier.new,
);

class DashboardNotifier extends AsyncNotifier<DashboardPageState> {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  Future<DashboardPageState> build() async {
    final results = await Future.wait([_loadUserProfile(), _loadUsageData()]);
    return results[0].merge(results[1]);
  }

  Future<DashboardPageState> _loadUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return const DashboardPageState();

      final uid = user.uid;

      // Fallback to auth display name if Firestore is slow
      final authName = user.displayName ?? '';
      final authFirstName = authName.split(' ').first;

      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return DashboardPageState(userName: authFirstName);

      final data = doc.data()!;
      final rawName = data['fullName'];
      final fullName = rawName is String ? rawName : authName;
      final firstName =
          fullName.isNotEmpty ? fullName.split(' ').first : authFirstName;
      final rawBudget = data['monthlyBudget'];
      final budget = rawBudget is num ? rawBudget.toDouble() : 150.0;

      return DashboardPageState(userName: firstName, monthlyBudget: budget);
    } on FirebaseException catch (e) {
      return DashboardPageState(
        errorMessage: 'Failed to load profile: ${e.message}',
      );
    } on Object catch (_) {
      return const DashboardPageState(
        errorMessage: 'Failed to load profile.',
      );
    }
  }

  Future<DashboardPageState> _loadUsageData() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return const DashboardPageState();

      final now = DateTime.now();
      final monthLabel = DateFormat('MMMM yyyy').format(now);
      final daysLeft = DateUtils.getDaysInMonth(now.year, now.month) - now.day;

      // Fetch meter readings for current month
      final startOfMonth = DateTime(now.year, now.month);
      final readingsSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('readings')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .orderBy('date', descending: false)
          .get();

      // Fetch last month readings for comparison
      final startOfLastMonth = DateTime(now.year, now.month - 1);
      final lastMonthSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('readings')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfLastMonth),
          )
          .where(
            'date',
            isLessThan: Timestamp.fromDate(startOfMonth),
          )
          .orderBy('date', descending: false)
          .get();

      // Calculate kWh used this month
      double kwhUsed = 0;
      if (readingsSnap.docs.length >= 2) {
        final first =
            (readingsSnap.docs.first.data()['reading'] as num).toDouble();
        final last =
            (readingsSnap.docs.last.data()['reading'] as num).toDouble();
        kwhUsed = (last - first).clamp(0, double.infinity).toDouble();
      } else if (readingsSnap.docs.isNotEmpty) {
        kwhUsed =
            (readingsSnap.docs.last.data()['kwh'] as num?)?.toDouble() ?? 0;
      }

      // Calculate last month kWh
      double lastMonthKwh = 0;
      if (lastMonthSnap.docs.length >= 2) {
        final first =
            (lastMonthSnap.docs.first.data()['reading'] as num).toDouble();
        final last =
            (lastMonthSnap.docs.last.data()['reading'] as num).toDouble();
        lastMonthKwh = (last - first).clamp(0, double.infinity).toDouble();
      }

      final percentVsLast = lastMonthKwh > 0
          ? ((kwhUsed - lastMonthKwh) / lastMonthKwh) * 100
          : 0.0;

      // Estimated bill (TNB domestic tariff)
      final bill = TariffRates.calculateDomestic(kwhUsed);
      final tier = TariffRates.getTier(kwhUsed);

      // Daily average
      final daysElapsed = now.day;
      final dailyAvg = daysElapsed > 0 ? kwhUsed / daysElapsed : 0.0;

      // Projected bill
      final projectedKwh =
          dailyAvg * DateUtils.getDaysInMonth(now.year, now.month);
      final projectedBill = TariffRates.calculateDomestic(projectedKwh);

      // 7-day usage — fetch last 7 readings
      final startOf7DayWindow = DateTime(now.year, now.month, now.day - 6);
      final weekSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('readings')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOf7DayWindow),
          )
          .orderBy('date', descending: true)
          .get();

      final weeklyUsage = _buildWeeklyUsage(weekSnap.docs, now);

      return DashboardPageState(
        monthLabel: monthLabel,
        kwhUsed: kwhUsed,
        estimatedBill: bill,
        currentTier: tier,
        dailyAvg: dailyAvg,
        daysLeft: daysLeft,
        percentageVsLastMonth: percentVsLast,
        projectedBill: projectedBill,
        weeklyUsage: weeklyUsage,
      );
    } on FirebaseException catch (e) {
      return DashboardPageState(
        errorMessage: 'Failed to load usage data: ${e.message}',
      );
    } on Exception catch (_) {
      return const DashboardPageState(
        errorMessage: 'Failed to load usage data.',
      );
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  List<DailyUsage> _buildWeeklyUsage(
    List<QueryDocumentSnapshot> docs,
    DateTime now,
  ) {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Fill last 7 days with whatever data we have, zeroing missing days
    final result = <DailyUsage>[];

    for (var i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final label = i == 0 ? 'Today' : dayLabels[day.weekday - 1];

      // Find matching reading if exists
      final match = docs.where((d) {
        final ts = d.data()! as Map<String, dynamic>;
        final date = (ts['date'] as Timestamp).toDate();
        return date.year == day.year &&
            date.month == day.month &&
            date.day == day.day;
      }).firstOrNull;

      final kwh = match != null
          ? ((match.data()! as Map<String, dynamic>)['kwh'] as num?)
                  ?.toDouble() ??
              0.0
          : 0.0;

      result.add(DailyUsage(label: label, kwh: kwh, isToday: i == 0));
    }

    return result;
  }
}
