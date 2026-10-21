import 'dart:math' as math;

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
    // Register a dependency on Theme so the shell is rebuilt when the app
    // switches palette. The shell is preserved by GoRouter, so using only
    // static AppColors here would leave the nav on the old colour.
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navBackground = isDark
        ? AppPalette.dark.surface
        : AppPalette.light.surface;
    final navBorderColor = isDark
        ? AppColors.text3.withValues(alpha: 0.35)
        : AppColors.border;

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: BottomAppBar(
        color: navBackground.withValues(alpha: 0.98),
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        shape: const CircularNotchedRectangle(),
        notchMargin: 7,
        padding: EdgeInsets.zero,
        height: AppDimensions.bottomNavHeight,
        child: CustomPaint(
          painter: _NavBorderPainter(
            fabSize: AppDimensions.navFabSize,
            notchMargin: 7,
            color: navBorderColor,
          ),
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
              SizedBox(width: 72.w),
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

class _NavBorderPainter extends CustomPainter {
  const _NavBorderPainter({
    required this.fabSize,
    required this.notchMargin,
    required this.color,
  });

  final double fabSize;
  final double notchMargin;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final host = Rect.fromLTWH(0, 0.5, size.width, size.height - 0.5);
    final guestSize = fabSize + notchMargin * 2;
    final guest = Rect.fromCenter(
      center: Offset(size.width / 2, 0),
      width: guestSize,
      height: guestSize,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = color;

    if (!host.overlaps(guest)) {
      canvas.drawLine(
        Offset(host.left, host.top),
        Offset(host.right, host.top),
        paint,
      );
      return;
    }

    canvas.drawPath(_notchedTopEdge(host, guest), paint);
  }

  Path _notchedTopEdge(Rect host, Rect guest) {
    final r = guest.width / 2;
    const s1 = 15.0;
    const s2 = 1.0;
    final a = -r - s2;
    final b = host.top - guest.center.dy;
    final root = math.max(0, a * a + b * b - r * r);
    final n2 = math.sqrt(b * b * r * r * root);
    final denominator = a * a + b * b;
    final p2xA = (a * r * r - n2) / denominator;
    final p2xB = (a * r * r + n2) / denominator;
    final p2yA = math.sqrt(math.max(0.0, r * r - p2xA * p2xA));
    final p2yB = math.sqrt(math.max(0.0, r * r - p2xB * p2xB));

    final p0Local = Offset(a - s1, b);
    final p1Local = Offset(a, b);
    final p2Local = (b < 0 ? -1.0 : 1.0) * p2yA > (b < 0 ? -1.0 : 1.0) * p2yB
        ? Offset(p2xA, p2yA)
        : Offset(p2xB, p2yB);
    final p0 = p0Local + guest.center;
    final p1 = p1Local + guest.center;
    final p2 = p2Local + guest.center;
    final p3 = Offset(-p2Local.dx, p2Local.dy) + guest.center;
    final p4 = Offset(-p1Local.dx, p1Local.dy) + guest.center;
    final p5 = Offset(-p0Local.dx, p0Local.dy) + guest.center;

    return Path()
      ..moveTo(host.left, host.top)
      ..lineTo(p0.dx, p0.dy)
      ..quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy)
      ..arcToPoint(p3, radius: Radius.circular(r), clockwise: false)
      ..quadraticBezierTo(p4.dx, p4.dy, p5.dx, p5.dy)
      ..lineTo(host.right, host.top);
  }

  @override
  bool shouldRepaint(_NavBorderPainter oldDelegate) =>
      oldDelegate.fabSize != fabSize ||
      oldDelegate.notchMargin != notchMargin ||
      oldDelegate.color != color;
}

class AppAddReadingFab extends StatelessWidget {
  const AppAddReadingFab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = AppDimensions.navFabSize;

    return Theme(
      data: theme.copyWith(
        floatingActionButtonTheme: theme.floatingActionButtonTheme.copyWith(
          sizeConstraints: BoxConstraints.tightFor(
            width: size,
            height: size,
          ),
        ),
      ),
      child: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addReading),
        tooltip: 'Add meter reading',
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: AppColors.navFabShadow,
          ),
          child: Icon(
            Icons.add_rounded,
            size: 30.r,
            color: AppColors.onAccent,
          ),
        ),
      ),
    );
  }
}
