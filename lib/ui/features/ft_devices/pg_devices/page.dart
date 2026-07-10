import 'dart:math' as math;

import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/services/notifier/user_profile_notifier.dart';
import 'package:energy_tracker/ui/features/ft_devices/pg_devices/notifier/notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      devicesProvider.select((value) => value.isLoading),
    );
    final errorMessage = ref.watch(
      devicesProvider.select((value) => value.errorMessage),
    );
    final isEmpty = ref.watch(
      devicesProvider.select((value) => value.appliances.isEmpty),
    );

    return ColoredBox(
      color: AppColors.bg,
      child: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    )
                  : errorMessage != null
                  ? ErrorView(
                      message: errorMessage,
                      onRetry: () =>
                          ref.read(devicesProvider.notifier).refresh(),
                    )
                  : isEmpty
                  ? const _EmptyDevicesView()
                  : const _BodyContent(),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('My Appliances', style: AppTextStyles.titleMd),
          GestureDetector(
            onTap: () => context.push(AppRoutes.addAppliance),
            child: Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(Icons.add_rounded, size: 20.r, color: Colors.black),
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
    final tariffType = ref.watch(tariffTypeProvider);
    final appliances = ref.watch(devicesProvider.select((s) => s.appliances));
    final totalKwh = ref.watch(
      devicesProvider.select((s) => s.totalMonthlyKwh),
    );

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surface2,
      onRefresh: () => ref.read(devicesProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPaddingH,
          vertical: 4.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryCard(tariffType: tariffType),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Appliances',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.swipe_left_rounded,
                      size: 14.r,
                      color: AppColors.text3,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Swipe to delete appliance',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.text3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10.h),
            ...appliances.map(
              (appliance) => Padding(
                key: ValueKey(appliance.id),
                padding: EdgeInsets.only(bottom: 10.h),
                child: _ApplianceCard(
                  appliance: appliance,
                  totalKwh: totalKwh,
                  tariffType: tariffType,
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

class _EmptyDevicesView extends StatelessWidget {
  const _EmptyDevicesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.r,
              height: 72.r,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Icon(
                Icons.power_outlined,
                size: 32.r,
                color: AppColors.accent,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'No appliances yet',
              style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.h),
            Text(
              'Add your appliances to track\nhow much each one costs monthly.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm,
            ),
            SizedBox(height: 24.h),
            GestureDetector(
              onTap: () => context.push(AppRoutes.addAppliance),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.accent2],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(
                  'Add First Appliance',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({
    required this.tariffType,
  });

  final TariffType tariffType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalKwh = ref.watch(
      devicesProvider.select((s) => s.totalMonthlyKwh),
    );
    final applianceCount = ref.watch(
      devicesProvider.select((s) => s.appliances.length),
    );
    final totalCost = ref.watch(
      devicesProvider.select((s) => s.totalMonthlyCost(tariffType)),
    );
    final kwhRef = TariffRates.ringReferenceKwh(tariffType);

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.12),
            AppColors.accent2.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80.r,
            height: 80.r,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(80.r, 80.r),
                  painter: _RingPainter(
                    fraction: (totalKwh / kwhRef).clamp(0.0, 1.0),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        totalKwh.toStringAsFixed(0),
                        style: AppTextStyles.bodySm.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                      Text(
                        'kWh',
                        style: AppTextStyles.caption.copyWith(fontSize: 9.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Monthly Cost', style: AppTextStyles.caption),
                SizedBox(height: 4.h),
                Text(
                  'RM ${totalCost.toStringAsFixed(2)}',
                  style: AppTextStyles.titleMd,
                ),
                SizedBox(height: 4.h),
                Text(
                  '$applianceCount '
                  'appliance${applianceCount == 1 ? '' : 's'} tracked',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.fraction});

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 8.0;
    const startAngle = -math.pi / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      startAngle,
      fraction * 2 * math.pi,
      false,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.accent, AppColors.accent2],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}

class _ApplianceCard extends ConsumerWidget {
  const _ApplianceCard({
    required this.appliance,
    required this.totalKwh,
    required this.tariffType,
  });

  final Appliance appliance;
  final double totalKwh;
  final TariffType tariffType;

  Color get _accentColor {
    switch (appliance.category) {
      case 'Cooling':
        return AppColors.accent2;
      case 'Lighting':
        return AppColors.warn;
      case 'Kitchen':
        return AppColors.accent3;
      case 'Heating':
        return AppColors.warn;
      case 'Entertainment':
        return AppColors.accent;
      case 'Washing':
        return AppColors.accent2;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fraction = totalKwh > 0
        ? (appliance.monthlyKwh / totalKwh).clamp(0.0, 1.0)
        : 0.0;

    return Dismissible(
      key: Key(appliance.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: AppColors.danger,
              size: 24.r,
            ),
            SizedBox(height: 4.h),
            Text(
              'Delete',
              style: AppTextStyles.caption.copyWith(color: AppColors.danger),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        final confirmed = await _confirmDelete(context) ?? false;
        if (!confirmed) return false;
        return ref.read(devicesProvider.notifier).deleteAppliance(appliance.id);
      },
      onDismissed: (_) {},
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.editAppliance, extra: appliance),
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: Text(
                        appliance.categoryEmoji,
                        style: TextStyle(fontSize: 18.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appliance.name,
                          style: AppTextStyles.bodyMd.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${appliance.wattage.toStringAsFixed(0)}W · '
                          '${appliance.dailyHours}h/day',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'RM ${appliance.monthlyCost(tariffType).toStringAsFixed(2)}',
                        style: AppTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _accentColor,
                        ),
                      ),
                      Text(
                        '${appliance.monthlyKwh.toStringAsFixed(0)} kWh',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.chevron_left_rounded,
                    size: 16.r,
                    color: AppColors.text3,
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3.r),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6.h,
                      backgroundColor: AppColors.surface3,
                      valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(fraction * 100).toStringAsFixed(0)}'
                        '% of total usage',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10.sp,
                          color: AppColors.text3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        title: Text(
          'Delete Appliance',
          style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Delete "${appliance.name}" from your list?',
          style: AppTextStyles.bodySm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.text2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
