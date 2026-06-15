import 'dart:async';

import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/components/errors.dart';
import 'package:energy_tracker/ui/components/nav.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_notifier.dart';
import 'package:energy_tracker/ui/features/ft_settings/pg_settings/notifier/notifier.dart';
import 'package:energy_tracker/ui/features/ft_settings/pg_settings/widgets/widgets.dart';
import 'package:energy_tracker/ui/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: state.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (error, _) => ErrorView(
                  onRetry: () => ref.read(settingsProvider.notifier).refresh(),
                  message: 'Failed to load settings',
                ),
                data: (state) => _SettingsBody(
                  state: state,
                  onEditProfile: () async {
                    await context.push(AppRoutes.editProfile);
                  },
                  onToggleBudgetAlerts: (v) =>
                      notifier.toggleBudgetAlerts(value: v),
                  onToggleBillReminders: (v) =>
                      notifier.toggleBillReminders(value: v),
                  onToggleMonthlySummary: (v) =>
                      notifier.toggleMonthlySummary(value: v),
                  onSignOut: _handleSignOut,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Future<void> _handleSignOut() async {
    final confirmed = await _showSignOutDialog(context);
    if (confirmed == true) {
      await ref.read(settingsProvider.notifier).signOut();
    }
  }

  Future<bool?> _showSignOutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Sign Out', style: AppTextStyles.titleMd),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.text2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Sign Out',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.screenPaddingH,
        12.h,
        AppDimensions.screenPaddingH,
        16.h,
      ),
      child: Row(
        children: [
          Text('Settings', style: AppTextStyles.titleMd),
        ],
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({
    required this.state,
    required this.onEditProfile,
    required this.onToggleBudgetAlerts,
    required this.onToggleBillReminders,
    required this.onToggleMonthlySummary,
    required this.onSignOut,
  });

  final SettingsPageState state;
  final VoidCallback onEditProfile;
  final ValueChanged<bool> onToggleBudgetAlerts;
  final ValueChanged<bool> onToggleBillReminders;
  final ValueChanged<bool> onToggleMonthlySummary;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingH,
        vertical: 4.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserProfileCard(
            state: state,
            onTap: onEditProfile,
          ),
          SizedBox(height: 20.h),
          const SettingsSection(label: 'ACCOUNT'),
          SizedBox(height: 8.h),
          _SettingsGroup(
            children: [
              SettingsListTile(
                icon: '👤',
                label: 'Edit Profile',
                onTap: onEditProfile,
              ),
              SettingsListTile(
                icon: '🏠',
                label: 'Tariff Type',
                trailing: state.tariffLabel,
                onTap: () => _showTariffSheet(context, ref, state),
              ),
              SettingsListTile(
                icon: '🎯',
                label: 'Monthly Budget',
                trailing: state.formattedBudget,
                onTap: () => _showBudgetSheet(context, ref, state),
                isLast: true,
              ),
            ],
          ),
          SizedBox(height: 20.h),
          const SettingsSection(label: 'TOOLS'),
          SizedBox(height: 8.h),
          _SettingsGroup(
            children: [
              SettingsListTile(
                icon: '🧮',
                label: 'Tariff Calculator',
                onTap: () => context.push(AppRoutes.tariffCalculator),
                isLast: true,
              ),
            ],
          ),
          SizedBox(height: 20.h),
          const SettingsSection(label: 'NOTIFICATIONS'),
          SizedBox(height: 8.h),
          _SettingsGroup(
            children: [
              SettingsToggleTile(
                icon: '⚠️',
                label: 'Budget Alerts',
                value: state.budgetAlertsEnabled,
                onChanged: onToggleBudgetAlerts,
              ),
              SettingsToggleTile(
                icon: '📅',
                label: 'Bill Reminders',
                value: state.billRemindersEnabled,
                onChanged: onToggleBillReminders,
              ),
              SettingsToggleTile(
                icon: '📊',
                label: 'Monthly Summary',
                value: state.monthlySummaryEnabled,
                onChanged: onToggleMonthlySummary,
                isLast: true,
              ),
            ],
          ),
          SizedBox(height: 20.h),
          const SettingsSection(label: 'ABOUT'),
          SizedBox(height: 8.h),
          _SettingsGroup(
            children: [
              const SettingsListTile(
                icon: '📋',
                label: 'Version',
                trailing: '0.3.0+1',
                showChevron: false,
              ),
              SettingsListTile(
                icon: '📄',
                label: 'Terms of Service',
                onTap: () {},
              ),
              SettingsListTile(
                icon: '🔒',
                label: 'Privacy Policy',
                onTap: () {},
                isLast: true,
              ),
            ],
          ),
          SizedBox(height: 24.h),
          SettingsSignOutButton(
            isLoading: state.isSigningOut,
            onTap: onSignOut,
          ),
          if (state.errorMessage != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.danger,
                    size: 16.r,
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
                ],
              ),
            ),
          ],
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  void _showTariffSheet(
    BuildContext context,
    WidgetRef ref,
    SettingsPageState state,
  ) {
    unawaited(
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => TariffTypeSheet(
          selected: state.tariffType,
          onSelect: (value) async {
            final saved = await ref
                .read(settingsProvider.notifier)
                .updateTariffType(value);

            if (!context.mounted) return;

            if (!saved) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to update tariff type.')),
              );
              return;
            }

            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showBudgetSheet(
    BuildContext context,
    WidgetRef ref,
    SettingsPageState state,
  ) {
    unawaited(
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => BudgetSheet(
          current: state.monthlyBudget,
          onSave: (value) async {
            final saved = await ref
                .read(settingsProvider.notifier)
                .updateMonthlyBudget(value);

            if (!context.mounted) return;

            if (!saved) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to save budget.')),
              );
              return;
            }

            Navigator.pop(context);

            ref.invalidate(dashboardProvider);
            unawaited(ref.read(dashboardProvider.future));
          },
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}
