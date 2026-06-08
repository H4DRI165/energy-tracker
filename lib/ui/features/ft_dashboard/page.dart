import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/components/nav.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_notifier.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_state.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/widgets/widgets.dart';
import 'package:energy_tracker/ui/routes/routes.dart';
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
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => ref.invalidate(dashboardProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                data: (state) => state.errorMessage != null
                    ? SliverFillRemaining(
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
                                  state.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMd.copyWith(
                                    color: AppColors.text2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: notifier.refresh,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : _BodyContent(state: state),
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
                const SizedBox(height: 2),
                Text(
                  '${state.userName} ${state.greetingEmoji}',
                  style: AppTextStyles.titleMd,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
                child: const Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: AppColors.text2,
                ),
              ),
              if (state.hasUnreadNotifications)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
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
  const _BodyContent({
    required this.state,
  });

  final DashboardPageState state;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingH,
      ),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            if (state.isNearBudget || state.isOverBudget) ...[
              BudgetAlertBanner(state: state),
              const SizedBox(height: 14),
            ],
            BillSummaryCard(state: state),
            const SizedBox(height: 14),
            StatCardsRow(state: state),
            const SizedBox(height: 14),
            if (!state.isNearBudget && !state.isOverBudget) ...[
              WeeklyChart(weeklyUsage: state.weeklyUsage),
              const SizedBox(height: 14),
            ],
            if (state.isNearBudget || state.isOverBudget) ...[
              const SavingTipsCard(),
              const SizedBox(height: 14),
              StatCardsRow(state: state, compact: true),
              const SizedBox(height: 14),
            ],
            QuickActions(
              onAddReading: () => context.push(AppRoutes.addReading),
              onScanBill: () => context.push(AppRoutes.scanBill),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
