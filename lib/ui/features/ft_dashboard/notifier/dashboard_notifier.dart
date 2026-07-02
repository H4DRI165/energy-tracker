import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:energy_tracker/services/notifiers/user_profile_notifier.dart';
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
    final user = _auth.currentUser;
    if (user == null) return const DashboardPageState();

    final tariffType = ref.watch(tariffTypeProvider);

    final results = await Future.wait([
      _loadUserProfile(user),
      _loadUsageData(user.uid, tariffType),
    ]);

    return results[0].merge(results[1]);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<DashboardPageState> _loadUserProfile(User user) async {
    try {
      final authName = user.displayName ?? '';
      final authFirstName = authName.split(' ').first;

      final doc = await _firestore.collection('users').doc(user.uid).get();
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

  Future<DashboardPageState> _loadUsageData(
    String uid,
    TariffType liveTariffType,
  ) async {
    try {
      final now = DateTime.now();
      final monthLabel = DateFormat('MMMM yyyy').format(now);
      final daysLeft = DateUtils.getDaysInMonth(now.year, now.month) - now.day;

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

      final startOfLastMonth = DateTime(now.year, now.month - 1);
      final lastMonthSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('readings')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfLastMonth),
          )
          .where('date', isLessThan: Timestamp.fromDate(startOfMonth))
          .orderBy('date', descending: false)
          .get();

      double kwhUsed = 0;
      for (final doc in readingsSnap.docs) {
        final kwh = (doc.data()['kwh'] as num?)?.toDouble() ?? 0;
        kwhUsed += kwh;
      }

      double lastMonthKwh = 0;
      for (final doc in lastMonthSnap.docs) {
        final kwh = (doc.data()['kwh'] as num?)?.toDouble() ?? 0;
        lastMonthKwh += kwh;
      }

      final percentVsLast = lastMonthKwh > 0
          ? ((kwhUsed - lastMonthKwh) / lastMonthKwh) * 100
          : 0.0;

      // Use whichever tariff the current month's readings were actually
      // recorded under. Falls back to the live profile tariff when there's
      // no data yet (new month, no readings saved).
      final tariffType = readingsSnap.docs.isEmpty
          ? liveTariffType
          : TariffTypeX.fromValue(
              readingsSnap.docs.last.data()['tariffType'] as String? ??
                  TariffType.domestic.value,
            );

      final bill = TariffRates.calculate(kwhUsed, tariffType);
      final eeiBand = tariffType == TariffType.domestic
          ? TariffRates.getEeiBand(kwhUsed)
          : EeiBand(
              number: TariffRates.getTier(kwhUsed, TariffType.commercial),
              kwhRange: TariffRates.getTierKwhRange(
                TariffRates.getTier(kwhUsed, TariffType.commercial),
                TariffType.commercial,
              ),
              rebateSenPerKwh: 0,
              color: TariffRates.getTierColor(
                TariffRates.getTier(kwhUsed, TariffType.commercial),
                TariffType.commercial,
              ),
              label: TariffRates.tierBadgeLabel(
                TariffRates.getTier(kwhUsed, TariffType.commercial),
                TariffType.commercial,
              ),
              description: TariffRates.tierBadgeLabel(
                TariffRates.getTier(kwhUsed, TariffType.commercial),
                TariffType.commercial,
              ),
            );

      final daysElapsed = now.day;
      final dailyAvg = daysElapsed > 0 ? kwhUsed / daysElapsed : 0.0;

      final projectedKwh =
          dailyAvg * DateUtils.getDaysInMonth(now.year, now.month);
      final projectedBill = TariffRates.calculate(projectedKwh, tariffType);

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
        currentEeiBand: eeiBand,
        tariffType: tariffType,
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
