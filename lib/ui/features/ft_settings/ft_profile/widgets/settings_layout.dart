import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/features/ft_settings/ft_profile/notifier/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsProfileCard extends StatelessWidget {
  const SettingsProfileCard({
    required this.state,
    required this.onTap,
    super.key,
  });

  final SettingsPageState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x2600D4AA), Color(0x140099FF)],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.borderAccent),
        ),
        child: Row(
          children: [
            Container(
              width: 52.r,
              height: 52.r,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Center(
                child: Text(
                  state.initials,
                  style: AppTextStyles.titleMd.copyWith(color: Colors.black),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.fullName.isNotEmpty ? state.fullName : 'Loading...',
                    style: AppTextStyles.bodyLg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(state.email, style: AppTextStyles.bodySm),
                  SizedBox(height: 2.h),
                  Text(
                    'TNB: ${state.tnbAccountNo.isNotEmpty ? state.tnbAccountNo : '—'}',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.text3,
              size: 20.r,
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.label,
    super.key,
  });
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.text3,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }
}

class SettingsListTile extends StatelessWidget {
  const SettingsListTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.isLast = false,
    this.showChevron = true,
    super.key,
  });

  final String icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;
  final bool isLast;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14.w,
          vertical: 14.h,
        ),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28.w,
              child: Text(
                icon,
                style: TextStyle(fontSize: 18.sp),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyMd),
            ),
            if (trailing != null) ...[
              Text(
                trailing!,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.accent,
                ),
              ),
              SizedBox(width: 6.w),
            ],
            if (showChevron && onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.text3,
                size: 18.r,
              ),
          ],
        ),
      ),
    );
  }
}

class SettingsToggleTile extends StatelessWidget {
  const SettingsToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isLast = false,
    super.key,
  });

  final String icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border),
              ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28.w,
            child: Text(
              icon,
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(label, style: AppTextStyles.bodyMd),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: AppColors.surface3,
            inactiveThumbColor: Colors.white,
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class SettingsSignOutButton extends StatelessWidget {
  const SettingsSignOutButton({
    required this.isLoading,
    required this.onTap,
    super.key,
  });

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.15),
          ),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 18.r,
                  height: 18.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.danger,
                  ),
                )
              : Text(
                  'Sign Out',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
