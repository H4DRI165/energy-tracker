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
                error: (e, _) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (state) => SliverToBoxAdapter(
                  child: _Header(
                    greeting: notifier.greeting,
                  ),
                ),
              ),
              state.when(
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                ),
                error: (e, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.screenPaddingH,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            e.toString(),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.text2,
                            ),
                          ),
                          SizedBox(height: 12.h),
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

    final isAlert = state.isNearBudget || state.isOverBudget;

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
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => const NotificationPrefsSheet(),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: AppDimensions.iconBtnSize,
                  height: AppDimensions.iconBtnSize,
                  decoration: BoxDecoration(
                    color: isAlert
                        ? AppColors.danger.withValues(alpha: 0.10)
                        : AppColors.surface2,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: isAlert
                        ? Border.all(
                            color: AppColors.danger.withValues(alpha: 0.20),
                          )
                        : Border.all(color: AppColors.border),
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    size: 20.r,
                    color: AppColors.text2,
                  ),
                ),
                if (state.hasUnreadNotifications)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8.r,
                      height: 8.r,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
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

    final isAlert = state.isNearBudget || state.isOverBudget;

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
                if (isAlert) ...[
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
                QuickActions(
                  onAddReading: () => context.push(AppRoutes.addReading),
                  onScanBill: () => context.push(AppRoutes.scanBill),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ],
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
