import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:energy_tracker/services/auth/providers/current_uid_provider.dart';
import 'package:energy_tracker/services/notifier/user_profile_notifier.dart';
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
    final uid = ref.watch(currentUidProvider).value;
    if (uid == null) return const DashboardPageState();

    final authName = _auth.currentUser?.displayName ?? '';
    final tariffType = ref.watch(tariffTypeProvider);

    final results = await Future.wait([
      _loadUserProfile(uid, authName),
      _loadUsageData(uid, tariffType),
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
    } on FirebaseException catch (e) {
      return DashboardPageState(
        errorMessage: 'Failed to load profile: ${e.message}',
      );
    } on Object catch (_) {
      return const DashboardPageState(errorMessage: 'Failed to load profile.');
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
      final startOf7DayWindow = DateTime(now.year, now.month, now.day - 6);
      final earliestNeeded = startOf7DayWindow.isBefore(startOfMonth)
          ? startOf7DayWindow
          : startOfMonth;

      final startOfLastMonth = DateTime(now.year, now.month - 1);

      final results = await Future.wait([
        _firestore
            .collection('users')
            .doc(uid)
            .collection('readings')
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(earliestNeeded),
            )
            .orderBy('date', descending: false)
            .get(),
        _firestore
            .collection('users')
            .doc(uid)
            .collection('readings')
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfLastMonth),
            )
            .where('date', isLessThan: Timestamp.fromDate(startOfMonth))
            .orderBy('date', descending: false)
            .get(),
      ]);

      final combinedSnap = results[0];
      final lastMonthSnap = results[1];

      // Filter for current-month-only (kwhUsed & tariffType detection)
      final currentMonthDocs = combinedSnap.docs.where((d) {
        final date = (d.data()['date'] as Timestamp).toDate();
        return !date.isBefore(startOfMonth);
      }).toList();

      double kwhUsed = 0;
      for (final doc in currentMonthDocs) {
        kwhUsed += (doc.data()['kwh'] as num?)?.toDouble() ?? 0;
      }

      double lastMonthKwh = 0;
      for (final doc in lastMonthSnap.docs) {
        lastMonthKwh += (doc.data()['kwh'] as num?)?.toDouble() ?? 0;
      }

      final percentVsLast = lastMonthKwh > 0
          ? ((kwhUsed - lastMonthKwh) / lastMonthKwh) * 100
          : 0.0;

      final tariffType = currentMonthDocs.isEmpty
          ? liveTariffType
          : TariffTypeX.fromValue(
              currentMonthDocs.last.data()['tariffType'] as String? ??
                  TariffType.domestic.value,
            );

      final bill = TariffRates.calculate(kwhUsed, tariffType);
      final eeiBand = tariffType == TariffType.domestic
          ? TariffRates.getEeiBand(kwhUsed)
          : (() {
              final tier = TariffRates.getTier(kwhUsed, TariffType.commercial);
              return EeiBand(
                number: tier,
                kwhRange: TariffRates.getTierKwhRange(
                  tier,
                  TariffType.commercial,
                ),
                rebateSenPerKwh: 0,
                color: TariffRates.getTierColor(tier, TariffType.commercial),
                label: TariffRates.tierBadgeLabel(tier, TariffType.commercial),
                description: TariffRates.tierBadgeLabel(
                  tier,
                  TariffType.commercial,
                ),
              );
            })();

      final daysElapsed = now.day;
      final dailyAvg = daysElapsed > 0 ? kwhUsed / daysElapsed : 0.0;

      final projectedKwh =
          dailyAvg * DateUtils.getDaysInMonth(now.year, now.month);
      final projectedBill = TariffRates.calculate(projectedKwh, tariffType);
      final weeklyUsage = _buildWeeklyUsage(combinedSnap.docs, now);

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

    // Index once: key = "yyyy-MM-dd", value = kwh
    final kwhByDate = <String, double>{};
    for (final doc in docs) {
      final data = doc.data()! as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final key = '${date.year}-${date.month}-${date.day}';
      final kwh = (data['kwh'] as num?)?.toDouble() ?? 0.0;
      kwhByDate[key] = (kwhByDate[key] ?? 0) + kwh; // sum if > 1 reading/day
    }

    final result = <DailyUsage>[];
    for (var i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final label = i == 0 ? 'Today' : dayLabels[day.weekday - 1];
      final key = '${day.year}-${day.month}-${day.day}';
      final kwh = kwhByDate[key] ?? 0.0;

      result.add(DailyUsage(label: label, kwh: kwh, isToday: i == 0));
    }

    return result;
  }
}
