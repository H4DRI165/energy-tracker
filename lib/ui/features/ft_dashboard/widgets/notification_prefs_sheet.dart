import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/services/notification/providers/notification_prefs_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationPrefsSheet extends ConsumerWidget {
  const NotificationPrefsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);
    final notifier = ref.read(notificationPrefsProvider.notifier);

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: const Border(
          top: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: AppColors.text3.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),

          // Header with icon badge
          Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accent.withValues(alpha: 0.18),
                      AppColors.accent2.withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  size: 20.r,
                  color: AppColors.accent,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Budget Alerts', style: AppTextStyles.titleMd),
                    SizedBox(height: 2.h),
                    Text(
                      'Choose when you want to be notified',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          _PrefRow(
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.warn,
            title: '80% Budget Reached',
            subtitle: 'Early warning before you hit your limit',
            value: prefs.alert80Enabled,
            onChanged: (value) => notifier.setAlert80(value: value),
          ),
          SizedBox(height: 10.h),
          _PrefRow(
            icon: Icons.error_rounded,
            iconColor: AppColors.danger,
            title: '100% Budget Exceeded',
            subtitle: 'Alert when you go over your monthly target',
            value: prefs.alert100Enabled,
            onChanged: (value) => notifier.setAlert100(value: value),
          ),
        ],
      ),
    );
  }
}

class _PrefRow extends StatelessWidget {
  const _PrefRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: value ? iconColor.withValues(alpha: 0.06) : AppColors.surface3,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: value ? iconColor.withValues(alpha: 0.25) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: value ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Icon(
              icon,
              size: 18.r,
              color: value ? iconColor : AppColors.text3,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: value ? AppColors.text : AppColors.text2,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.text3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: iconColor,
            activeTrackColor: iconColor.withValues(alpha: 0.25),
            inactiveThumbColor: AppColors.text3,
            inactiveTrackColor: AppColors.surface3,
            trackOutlineColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.transparent;
              }
              return AppColors.text3.withValues(alpha: 0.4);
            }),
          ),
        ],
      ),
    );
  }
}
