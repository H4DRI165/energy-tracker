import 'dart:async';

import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/components/nav.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_notifier.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_state.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/widgets/widgets.dart';
import 'package:energy_tracker/ui/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = DashboardNotifier()..addListener(_onChanged);
    unawaited(_notifier.init());
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _notifier
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _notifier.state;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface2,
          onRefresh: _notifier.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  state: state,
                  greeting: _notifier.greeting,
                ),
              ),
              if (state.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              else
                _BodyContent(state: state),
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
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPaddingH,
        12,
        AppDimensions.screenPaddingH,
        16,
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
      padding: const EdgeInsets.symmetric(
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
