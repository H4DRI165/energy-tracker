import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/ui/features/ft_usage/notifier/notifier.dart';
import 'package:energy_tracker/ui/features/ft_usage/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class UsagePage extends ConsumerWidget {
  const UsagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usageProvider);

    return ColoredBox(
      color: AppColors.bg,
      child: SafeArea(
        child: state.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
          error: (e, _) => ErrorView(
            onRetry: () => ref.read(usageProvider.notifier).refresh(),
            message: 'Failed to load usage data',
          ),
          data: (state) =>
              state.monthlyData.every((m) => m.kwh == 0) &&
                  state.billHistory.isEmpty
              ? _EmptyUsageView()
              : const _BodyContent(),
        ),
      ),
    );
  }
}

class _BodyContent extends ConsumerWidget {
  const _BodyContent();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usageProvider).value;
    final notifier = ref.read(usageProvider.notifier);

    if (state == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.screenPaddingH,
            12.h,
            AppDimensions.screenPaddingH,
            0,
          ),
          child: UsageSummaryRow(
            kwh: state.currentKwh,
            bill: state.currentBill,
            monthLabel: state.currentMonthLabel,
          ),
        ),
        SizedBox(height: 10.h),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surface2,
            onRefresh: notifier.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppDimensions.screenPaddingH,
                0,
                AppDimensions.screenPaddingH,
                24.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BillBreakdownCard(
                    items: state.chargeBreakdown,
                    emptyLabel: 'No usage data for ${state.currentMonthLabel}',
                  ),
                  SizedBox(height: 14.h),
                  const MonthlyUsageChartCard(),
                  SizedBox(height: 14.h),
                  BillHistoryList(bills: state.billHistory),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyUsageView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.screenPaddingH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.r,
              height: 72.r,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: AppColors.borderAccent),
              ),
              child: Center(
                child: Text('📊', style: TextStyle(fontSize: 32.sp)),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'No usage data yet',
              style: AppTextStyles.titleMd,
            ),
            SizedBox(height: 8.h),
            Text(
              'Add your first meter reading to start'
              '\ntracking your energy usage.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.text2),
            ),
            SizedBox(height: 28.h),
            GestureDetector(
              onTap: () => context.push(AppRoutes.addReading),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 14.h,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  boxShadow: AppColors.btnPrimaryShadow,
                ),
                child: Text(
                  'Add First Reading',
                  style: AppTextStyles.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
