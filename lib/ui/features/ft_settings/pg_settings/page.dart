import 'dart:async';

import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/services/notifier/user_profile_notifier.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_notifier.dart';
import 'package:energy_tracker/ui/features/ft_settings/pg_settings/notifier/notifier.dart';
import 'package:energy_tracker/ui/features/ft_settings/pg_settings/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

enum _Status { loading, error, data }

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      settingsProvider.select((async) {
        if (async.isLoading && !async.hasValue) return _Status.loading;
        if (async.hasError) return _Status.error;
        return _Status.data;
      }),
    );
    final notifier = ref.read(settingsProvider.notifier);

    return ColoredBox(
      color: AppColors.bg,
      child: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: switch (status) {
                _Status.loading => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                _Status.error => ErrorView(
                  onRetry: notifier.refresh,
                  message: 'Failed to load settings',
                ),
                _Status.data => _SettingsBody(
                  onEditProfile: () async {
                    await context.push(AppRoutes.editProfile);
                  },
                  onToggleBudgetAlerts: (v) =>
                      notifier.toggleBudgetAlerts(value: v),
                  onToggleBillReminders: (v) =>
                      notifier.toggleBillReminders(value: v),
                  onToggleMonthlySummary: (v) =>
                      notifier.toggleMonthlySummary(value: v),
                  onSignOut: () async {
                    final confirmed = await ConfirmDialog.show(
                      context,
                      title: 'Sign Out?',
                      message: 'Are you sure you want to sign out?',
                      confirmLabel: 'Sign Out',
                      confirmColor: AppColors.danger,
                    );
                    if (!confirmed) return;

                    final success = await notifier.signOut();
                    if (!success) return;
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

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
    required this.onEditProfile,
    required this.onToggleBudgetAlerts,
    required this.onToggleBillReminders,
    required this.onToggleMonthlySummary,
    required this.onSignOut,
  });

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
              const _TariffAndBudgetTiles(),
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

          // TODO(dev): implement notifications settings in future
          // const SettingsSection(label: 'NOTIFICATIONS'),
          // SizedBox(height: 8.h),
          // _SettingsGroup(
          //   children: [
          //     SettingsToggleTile(
          //       icon: '⚠️',
          //       label: 'Budget Alerts',
          //       fieldSelector: (s) => s.budgetAlertsEnabled,
          //       onChanged: onToggleBudgetAlerts,
          //     ),
          //     SettingsToggleTile(
          //       icon: '📅',
          //       label: 'Bill Reminders',
          //       fieldSelector: (s) => s.billRemindersEnabled,
          //       onChanged: onToggleBillReminders,
          //     ),
          //     SettingsToggleTile(
          //       icon: '📊',
          //       label: 'Monthly Summary',
          //       fieldSelector: (s) => s.monthlySummaryEnabled,
          //       onChanged: onToggleMonthlySummary,
          //       isLast: true,
          //     ),
          //   ],
          // ),
          // SizedBox(height: 20.h),
          const SettingsSection(label: 'ABOUT'),
          SizedBox(height: 8.h),
          const _AboutGroup(),
          SizedBox(height: 24.h),
          _SignOutSection(onSignOut: onSignOut),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}

class _TariffAndBudgetTiles extends ConsumerWidget {
  const _TariffAndBudgetTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (tariffLabel, formattedBudget) = ref.watch(
      settingsProvider.select((async) {
        final s = async.maybeWhen(data: (value) => value, orElse: () => null);
        return (s?.tariffLabel ?? '', s?.formattedBudget ?? '');
      }),
    );

    return Column(
      children: [
        SettingsListTile(
          icon: '🏠',
          label: 'Tariff Type',
          trailing: tariffLabel,
          onTap: () => _showTariffSheet(context, ref),
        ),
        SettingsListTile(
          icon: '🎯',
          label: 'Monthly Budget',
          trailing: formattedBudget,
          onTap: () => _showBudgetSheet(context, ref),
          isLast: true,
        ),
      ],
    );
  }

  void _showTariffSheet(BuildContext context, WidgetRef ref) {
    final state = ref
        .read(settingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    if (state == null) return;

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

  void _showBudgetSheet(BuildContext context, WidgetRef ref) {
    final state = ref
        .read(settingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    if (state == null) return;

    unawaited(
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => BudgetSheet(
          tariffType: ref.read(tariffTypeProvider),
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

            await ref.read(dashboardProvider.notifier).refresh();
          },
        ),
      ),
    );
  }
}

class _AboutGroup extends ConsumerWidget {
  const _AboutGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(appVersionProvider);

    return _SettingsGroup(
      children: [
        SettingsListTile(
          icon: '📋',
          label: 'Version',
          trailing: versionAsync.when(
            data: (v) => v,
            loading: () => '...',
            error: (_, _) => 'unknown',
          ),
          showChevron: false,
        ),

        // TODO(dev): implement  in future
        // SettingsListTile(icon: '📄', label: 'Terms of Service', onTap: () {}),
        // SettingsListTile(
        //   icon: '🔒',
        //   label: 'Privacy Policy',
        //   onTap: () {},
        //   isLast: true,
        // ),
      ],
    );
  }
}

class _SignOutSection extends ConsumerWidget {
  const _SignOutSection({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (isSigningOut, errorMessage) = ref.watch(
      settingsProvider.select((async) {
        final s = async.maybeWhen(data: (value) => value, orElse: () => null);
        return (s?.isSigningOut ?? false, s?.errorMessage);
      }),
    );

    return Column(
      children: [
        SettingsSignOutButton(isLoading: isSigningOut, onTap: onSignOut),
        if (errorMessage != null) ...[
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
                    errorMessage,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
