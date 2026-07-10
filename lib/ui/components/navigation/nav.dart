import 'package:energy_tracker/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF20A0E1A),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppDimensions.bottomNavHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Usage',
                index: 1,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              const _NavFab(),
              _NavItem(
                icon: Icons.electrical_services_rounded,
                label: 'Devices',
                index: 2,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                index: 3,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: SizedBox(
          width: 56.w,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22.r,
                color: isActive ? AppColors.accent : AppColors.text3,
              ),
              SizedBox(height: 3.h),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: AppTextStyles.navLabel.copyWith(
                  color: isActive ? AppColors.accent : AppColors.text3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavFab extends StatelessWidget {
  const _NavFab();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.addReading),
      child: Container(
        width: AppDimensions.navFabSize,
        height: AppDimensions.navFabSize,
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: AppColors.navFabShadow,
        ),
        child: Center(
          child: Text(
            '⚡',
            style: TextStyle(fontSize: 22.sp),
          ),
        ),
      ),
    );
  }
}
