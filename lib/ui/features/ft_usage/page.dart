import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/ui/features/ft_usage/notifier/notifier.dart';
import 'package:energy_tracker/ui/features/ft_usage/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class UsagePage extends ConsumerWidget {
  const UsagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usageProvider);

    return ColoredBox(
      color: AppColors.bg,
      child: SafeArea(
        child: state.when(
          loading: () => const UsageSkeleton(),
          error: (e, _) => ErrorView(
            onRetry: () => ref.read(usageProvider.notifier).refresh(),
            message: 'Failed to load usage data',
          ),
          data: (state) => state.hasUsage
              ? const _BodyContent()
              : _EmptyUsageView(readingCount: state.readingCount),
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

    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

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
            monthProgressLabel: 'Day ${now.day} of $daysInMonth',
            status: _ReadingStatus(state: state),
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
                    subtitle: 'Tap any charge to learn what it means.',
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

class _ReadingStatus extends StatelessWidget {
  const _ReadingStatus({required this.state});

  final UsageState state;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lastReadingDate = state.lastReadingDate;
    final formattedDate = lastReadingDate == null
        ? null
        : DateFormat(
            lastReadingDate.year == now.year ? 'd MMM' : 'd MMM yyyy',
          ).format(lastReadingDate);
    final usageLabel = state.lastReadingKwh > 0
        ? '+${state.lastReadingKwh.toStringAsFixed(1)} kWh'
        : state.readingCount <= 1
        ? 'baseline'
        : 'no usage';
    final lastReadingLabel = formattedDate == null
        ? 'No readings saved yet'
        : 'Last reading $formattedDate · $usageLabel';

    return Row(
      children: [
        Icon(Icons.history_rounded, size: 13.r, color: AppColors.text3),
        SizedBox(width: 5.w),
        Expanded(
          child: Text(
            lastReadingLabel,
            style: AppTextStyles.caption.copyWith(color: AppColors.text2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EmptyUsageView extends StatelessWidget {
  const _EmptyUsageView({required this.readingCount});

  final int readingCount;

  @override
  Widget build(BuildContext context) {
    final isBaseline = readingCount == 1;
    final hasReadings = readingCount > 0;

    final title = isBaseline
        ? 'Baseline reading saved'
        : hasReadings
        ? 'No usage recorded yet'
        : 'No usage data yet';

    final message = isBaseline
        ? 'This is your starting point. Add your next reading to calculate '
              'the kWh you used and your estimated bill.'
        : hasReadings
        ? 'Your readings are saved, but the meter value has not increased '
              'between them yet. Add a newer reading to see usage.'
        : 'Add your first meter reading to start'
              '\ntracking your energy usage.';

    final ctaLabel = isBaseline
        ? 'Add Next Reading'
        : hasReadings
        ? 'Add New Reading'
        : 'Add First Reading';

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
                child: isBaseline
                    ? Icon(
                        Icons.check_rounded,
                        size: 36.r,
                        color: AppColors.accent,
                      )
                    : Text('📊', style: TextStyle(fontSize: 32.sp)),
              ),
            ),
            if (isBaseline) ...[
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 5.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.borderAccent),
                ),
                child: Text(
                  '1 OF 2 READINGS · BASELINE',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
            SizedBox(height: isBaseline ? 12.h : 20.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMd,
            ),
            SizedBox(height: 8.h),
            Text(
              message,
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
                  ctaLabel,
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
