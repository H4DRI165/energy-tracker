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
    final asyncState = ref.watch(dashboardProvider);
    final notifier = ref.read(dashboardProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface2,
          onRefresh: notifier.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              asyncState.when(
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (e, _) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (state) => SliverToBoxAdapter(
                  child: _Header(
                    state: state,
                    greeting: notifier.greeting,
                  ),
                ),
              ),
              asyncState.when(
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
                            onPressed: () => ref.invalidate(dashboardProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                data: (state) => _BodyContent(state: state, notifier: notifier),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.state,
    required this.greeting,
  });

  final DashboardPageState state;
  final String greeting;

  @override
  Widget build(BuildContext context) {
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
          Stack(
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
          SizedBox(width: 8.w),
          Container(
            width: AppDimensions.avatarSize,
            height: AppDimensions.avatarSize,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                state.userName.isNotEmpty
                    ? state.userName[0].toUpperCase()
                    : '?',
                style: AppTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyContent extends StatelessWidget {
  const _BodyContent({required this.state, required this.notifier});

  final DashboardPageState state;
  final DashboardNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        if (state.errorMessage != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPaddingH,
                vertical: 8.h,
              ),
              child: Material(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
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
                          state.errorMessage!,
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: notifier.refresh,
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
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPaddingH,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                if (state.isNearBudget || state.isOverBudget) ...[
                  BudgetAlertBanner(state: state),
                  SizedBox(height: 14.h),
                ],
                BillSummaryCard(state: state),
                SizedBox(height: 14.h),
                StatCardsRow(state: state),
                SizedBox(height: 14.h),
                UsageBarChartCard(
                  title: '7-Day Usage',
                  subtitle: 'kWh/day',
                  chartHeight: 80, // compact for dashboard
                  entries: state.weeklyUsage
                      .map(
                        (day) => BarChartEntry(
                          label: day.label,
                          kwh: day.kwh,
                          isHighlighted: day.isToday,
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: 14.h),
                if (state.isNearBudget || state.isOverBudget) ...[
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
