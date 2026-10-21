import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/notifier.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final notifier = ref.read(dashboardProvider.notifier);

    return ColoredBox(
      color: AppColors.bg,
      child: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface2,
          onRefresh: notifier.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              state.when(
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, _) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (state) => SliverToBoxAdapter(
                  child: _Header(
                    greeting: notifier.greeting,
                  ),
                ),
              ),
              state.when(
                loading: () => SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                ),
                error: (_, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.screenPaddingH,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 40.r,
                            color: AppColors.text3,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            "We couldn't load your dashboard. "
                            'Check your connection and try again.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.text2,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          FilledButton(
                            onPressed: () =>
                                ref.read(dashboardProvider.notifier).refresh(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                data: (state) => const _BodyContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.greeting,
  });

  final String greeting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider).value;

    if (state == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.screenPaddingH,
        12.sp,
        AppDimensions.screenPaddingH,
        16.sp,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.text2),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${state.userName} ${state.greetingEmoji}',
                  style: AppTextStyles.titleMd,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyContent extends ConsumerWidget {
  const _BodyContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider).value;
    final notifier = ref.read(dashboardProvider.notifier);

    if (state == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (state.readingCount == 0) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _DashboardEmptyState(),
      );
    }

    final isAlert = state.isNearBudget || state.isOverBudget;
    final showAlertBanner = state.isOverBudget;

    return SliverMainAxisGroup(
      slivers: [
        if (state.errorMessage != null)
          SliverToBoxAdapter(
            child: ErrorBanner(
              onRetry: notifier.refresh,
              message: '${state.errorMessage}',
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPaddingH,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                if (state.readingCount == 1) ...[
                  const _BaselineReadingBanner(),
                  SizedBox(height: 14.h),
                ],
                if (showAlertBanner) ...[
                  const BudgetAlertBanner(),
                  SizedBox(height: 14.h),
                ],
                const BillSummaryCard(),
                SizedBox(height: 14.h),
                const StatCardsRow(),
                SizedBox(height: 14.h),
                const WeeklyUsageChartCard(),
                SizedBox(height: 14.h),
                if (isAlert) ...[
                  const SavingTipsCard(),
                  SizedBox(height: 14.h),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.screenPaddingH),
        child: SizedBox(
          width: 300.w,
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
                child: Icon(
                  Icons.speed_rounded,
                  size: 34.r,
                  color: AppColors.accent,
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                'Start tracking your usage',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMd,
              ),
              SizedBox(height: 8.h),
              Text(
                'Add a baseline reading, then your next reading to see '
                'usage, budget progress and an estimated bill.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.text2),
              ),
              SizedBox(height: 24.h),
              GradientButton(
                label: 'Add first reading',
                isLoading: false,
                onTap: () => context.push(AppRoutes.addReading),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BaselineReadingBanner extends StatelessWidget {
  const _BaselineReadingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.borderAccent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 18.r,
            color: AppColors.accent,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Baseline reading saved',
                  style: AppTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Add your next reading to calculate usage and your bill.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.text2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingH,
        vertical: 8.h,
      ),
      child: Material(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.danger,
                size: 18.r,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
                ),
              ),
              GestureDetector(
                onTap: onRetry,
                child: Text(
                  'Retry',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
