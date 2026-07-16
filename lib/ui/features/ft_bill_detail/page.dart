import 'dart:async';

import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/ui/features/ft_bill_detail/notifier/notifier.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_notifier.dart';
import 'package:energy_tracker/ui/features/ft_usage/notifier/usage_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class BillDetailPage extends ConsumerStatefulWidget {
  const BillDetailPage({
    required this.billId,
    super.key,
  });

  final String billId;

  @override
  ConsumerState<BillDetailPage> createState() => _BillDetailPageState();
}

class _BillDetailPageState extends ConsumerState<BillDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(billDetailProvider.notifier).init(widget.billId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billDetailProvider);

    ref.listen(billDetailProvider, (previous, next) {
      if (next.billDeleted && context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This month has no remaining readings.'),
          ),
        );
      }
    });

    if (state.bill == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(bill: state.bill!),
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    )
                  : state.errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.r),
                        child: Text(
                          state.errorMessage!,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.danger,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.screenPaddingH,
                        vertical: 8.h,
                      ),
                      child: _BodyContent(
                        onEditReading: _handleEditReading,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEditReading(ReadingRecord r) async {
    await context.push(AppRoutes.addReading, extra: r);
    if (!mounted) return;

    await ref.read(billDetailProvider.notifier).init(widget.billId);
    if (!mounted) return;

    await Future.wait([
      ref.read(usageProvider.notifier).refresh(),
      ref.read(dashboardProvider.notifier).refresh(),
    ]);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.bill});
  final BillRecord bill;

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
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16.r,
                color: AppColors.text2,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Text(bill.monthYear, style: AppTextStyles.titleMd),
        ],
      ),
    );
  }
}

class _BodyContent extends ConsumerWidget {
  const _BodyContent({
    required this.onEditReading,
  });

  final Future<void> Function(ReadingRecord) onEditReading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bill = ref.watch(billDetailProvider.select((s) => s.bill!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BillSummaryCard(bill: bill),
        SizedBox(height: 16.h),
        const _PaidToggleCard(),
        SizedBox(height: 16.h),
        BillBreakdownCard(
          items: TariffRates.breakdownFor(bill.kwh, bill.tariffType),
          emptyLabel: 'No data available.',
          padding: EdgeInsets.all(16.r),
        ),
        SizedBox(height: 16.h),
        _ReadingsSection(
          bill: bill,
          onEditReading: onEditReading,
        ),
        SizedBox(height: 24.h),
      ],
    );
  }
}

class _BillSummaryCard extends StatelessWidget {
  const _BillSummaryCard({required this.bill});
  final BillRecord bill;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2D24), Color(0xFF0A1E2E)],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ESTIMATED BILL',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.accent,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'RM ${bill.amount.toStringAsFixed(2)}',
            style: AppTextStyles.displayLg.copyWith(color: AppColors.text),
          ),
          SizedBox(height: 4.h),
          Text(
            '${bill.kwh.toStringAsFixed(0)} kWh · ${bill.monthYear}',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.text2),
          ),
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.surface3,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: AppColors.text3.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              bill.tariffType.label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.text2,
                fontSize: 10.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaidToggleCard extends ConsumerWidget {
  const _PaidToggleCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaid = ref.watch(billDetailProvider.select((s) => s.isPaid));
    final isUpdating = ref.watch(
      billDetailProvider.select((s) => s.isUpdatingPaid),
    );
    final bill = ref.watch(billDetailProvider.select((s) => s.bill!));

    final color = isPaid ? AppColors.accent : AppColors.warn;
    final bgColor = isPaid
        ? AppColors.accent.withValues(alpha: 0.06)
        : AppColors.warn.withValues(alpha: 0.06);
    final borderColor = isPaid
        ? AppColors.accent.withValues(alpha: 0.2)
        : AppColors.warn.withValues(alpha: 0.2);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              isPaid
                  ? Icons.check_circle_outline_rounded
                  : Icons.schedule_rounded,
              color: color,
              size: 20.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPaid ? 'Bill Paid' : 'Payment Pending',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  isPaid ? 'Tap to mark as unpaid' : 'Tap to mark as paid',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (isUpdating)
            SizedBox(
              width: 20.r,
              height: 20.r,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          else
            GestureDetector(
              onTap: () async {
                await ref.read(billDetailProvider.notifier).togglePaid(bill);
                await ref.read(usageProvider.notifier).refresh();
              },
              child: Container(
                width: 44.r,
                height: 24.r,
                decoration: BoxDecoration(
                  color: isPaid ? AppColors.accent : AppColors.surface3,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: isPaid
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.all(3.r),
                    width: 18.r,
                    height: 18.r,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReadingsSection extends ConsumerWidget {
  const _ReadingsSection({
    required this.bill,
    required this.onEditReading,
  });

  final BillRecord bill;
  final Future<void> Function(ReadingRecord) onEditReading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(billDetailProvider);
    final tierLabels = state.readings.cumulativeTierLabels();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Readings This Month',
              style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
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
                  'Swipe to delete history',
                  style: AppTextStyles.caption.copyWith(color: AppColors.text3),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 10.h),
        if (state.readings.isEmpty)
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                'No readings found for this month.',
                style: AppTextStyles.bodySm,
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: state.readings.asMap().entries.map((entry) {
                return _ReadingRow(
                  reading: entry.value,
                  tierLabel: tierLabels[entry.value.id]!,
                  bill: bill,
                  isFirst: entry.key == 0,
                  isLast: entry.key == state.readings.length - 1,
                  onEdit: onEditReading,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _ReadingRow extends ConsumerWidget {
  const _ReadingRow({
    required this.reading,
    required this.tierLabel,
    required this.bill,
    required this.isFirst,
    required this.isLast,
    required this.onEdit,
  });

  final ReadingRecord reading;
  final String tierLabel;
  final BillRecord bill;
  final bool isFirst;
  final bool isLast;
  final Future<void> Function(ReadingRecord) onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: isFirst ? Radius.circular(AppDimensions.radiusLg) : Radius.zero,
        bottom: isLast ? Radius.circular(AppDimensions.radiusLg) : Radius.zero,
      ),
      child: Dismissible(
        key: Key(reading.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.w),
          color: AppColors.danger.withValues(alpha: 0.15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
                size: 22.r,
              ),
              SizedBox(height: 4.h),
              Text(
                'Delete',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (_) => ConfirmDialog.show(
          context,
          title: 'Delete Reading?',
          message:
              'Delete the reading on '
              '${reading.formattedDate} (${reading.kwh.toStringAsFixed(1)} '
              'kWh)?',
          confirmLabel: 'Delete',
          confirmColor: AppColors.danger,
          warning: 'This will also remove the associated bill entry.',
        ),
        onDismissed: (_) async {
          final billDetailNotifier = ref.read(billDetailProvider.notifier);
          final usageNotifier = ref.read(usageProvider.notifier);
          final dashboardNotifier = ref.read(dashboardProvider.notifier);

          final success = await billDetailNotifier.deleteReading(reading, bill);

          if (success) {
            await Future.wait([
              usageNotifier.refresh(),
              dashboardNotifier.refresh(),
            ]);
          }
        },
        child: GestureDetector(
          onTap: () => onEdit(reading),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 12.h,
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
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    color: AppColors.accent,
                    size: 18.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reading.formattedDate,
                        style: AppTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${reading.kwh.toStringAsFixed(1)} kWh ',
                        style: AppTextStyles.caption,
                      ),
                      Text(
                        tierLabel,
                        style: AppTextStyles.caption,
                      ),
                      if (reading.notes.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          reading.notes,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.text3,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 1.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface3,
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: AppColors.text3.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Text(
                          reading.tariffType.label,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.text2,
                            fontSize: 9.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${reading.reading.toStringAsFixed(0)} kWh',
                      style: AppTextStyles.bodySm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text2,
                      ),
                    ),
                    Text(
                      'meter read',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10.sp,
                      ),
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
          ),
        ),
      ),
    );
  }
}
