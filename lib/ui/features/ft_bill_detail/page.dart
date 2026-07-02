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
    required this.bill,
    super.key,
  });

  final BillRecord bill;

  @override
  ConsumerState<BillDetailPage> createState() => _BillDetailPageState();
}

class _BillDetailPageState extends ConsumerState<BillDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(billDetailProvider.notifier).init(widget.bill));
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
                              style: AppTextStyles.bodyMd
                                  .copyWith(color: AppColors.danger),
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
                            bill: state.bill!,
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

    await ref.read(billDetailProvider.notifier).init(widget.bill);
    if (!mounted) return;

    ref
      ..invalidate(usageProvider)
      ..invalidate(dashboardProvider);
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

class _BodyContent extends ConsumerStatefulWidget {
  const _BodyContent({
    required this.bill,
    required this.onEditReading,
  });

  final BillRecord bill;
  final Future<void> Function(ReadingRecord) onEditReading;

  @override
  ConsumerState<_BodyContent> createState() => _BodyContentState();
}

class _BodyContentState extends ConsumerState<_BodyContent> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billDetailProvider);
    final bill = state.bill!;
    final domesticItems = bill.tariffType == TariffType.domestic
        ? TariffRates.domesticBreakdown(bill.kwh)
        : null;
    final commercialTiers = bill.tariffType == TariffType.commercial
        ? TariffRates.breakdownFor(bill.kwh, TariffType.commercial)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BillSummaryCard(bill: bill),
        SizedBox(height: 16.h),
        _PaidToggleCard(
          isPaid: state.isPaid,
          isUpdating: state.isUpdatingPaid,
          onToggle: () async {
            await ref.read(billDetailProvider.notifier).togglePaid(state.bill!);
            ref.invalidate(usageProvider);
          },
        ),
        SizedBox(height: 16.h),
        _BillChargeBreakdown(
          domesticItems: domesticItems,
          commercialTiers: commercialTiers,
          tariffType: bill.tariffType,
          totalKwh: bill.kwh,
        ),
        SizedBox(height: 16.h),
        _ReadingsSection(
          readings: state.readings,
          bill: bill,
          onEditReading: widget.onEditReading,
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

class _PaidToggleCard extends StatelessWidget {
  const _PaidToggleCard({
    required this.isPaid,
    required this.isUpdating,
    required this.onToggle,
  });

  final bool isPaid;
  final bool isUpdating;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
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
              onTap: onToggle,
              child: Container(
                width: 44.r,
                height: 24.r,
                decoration: BoxDecoration(
                  color: isPaid ? AppColors.accent : AppColors.surface3,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment:
                      isPaid ? Alignment.centerRight : Alignment.centerLeft,
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

class _BillChargeBreakdown extends StatelessWidget {
  const _BillChargeBreakdown({
    required this.tariffType,
    required this.totalKwh,
    this.domesticItems,
    this.commercialTiers,
  });

  final TariffType tariffType;
  final double totalKwh;
  final List<ChargeLineItem>? domesticItems;
  final List<TierBreakdown>? commercialTiers;

  bool get isEmpty => tariffType == TariffType.domestic
      ? (domesticItems?.isEmpty ?? true)
      : (commercialTiers?.isEmpty ?? true);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bill Breakdown',
            style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 14.h),
          if (isEmpty)
            Text('No data available.', style: AppTextStyles.bodySm)
          else if (tariffType == TariffType.domestic)
            ...domesticItems!.map((item) => DomesticLineItem(item: item))
          else
            ...commercialTiers!.map(
              (tier) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tier.label, style: AppTextStyles.caption),
                        Text(
                          'RM ${tier.amount.toStringAsFixed(2)}',
                          style: AppTextStyles.bodySm.copyWith(
                            fontWeight: FontWeight.w700,
                            color: tier.color,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3.r),
                      child: LinearProgressIndicator(
                        value: tier.fillPercent,
                        minHeight: 6.h,
                        backgroundColor: AppColors.surface3,
                        valueColor: AlwaysStoppedAnimation<Color>(tier.color),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (tariffType == TariffType.domestic && !isEmpty) ...[
            Divider(height: 16.h, color: AppColors.border),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 11.r,
                  color: AppColors.text3,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    'Excludes AFA — a monthly fuel adjustment published '
                    'by TNB. Currently 0–2.59 sen/kWh depending on usage.',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.text3),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadingsSection extends ConsumerWidget {
  const _ReadingsSection({
    required this.readings,
    required this.bill,
    required this.onEditReading,
  });

  final List<ReadingRecord> readings;
  final BillRecord bill;
  final Future<void> Function(ReadingRecord) onEditReading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        if (readings.isEmpty)
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
              children: readings.asMap().entries.map((entry) {
                final r = entry.value;
                final isLast = entry.key == readings.length - 1;

                return ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: entry.key == 0
                        ? Radius.circular(AppDimensions.radiusLg)
                        : Radius.zero,
                    bottom: isLast
                        ? Radius.circular(AppDimensions.radiusLg)
                        : Radius.zero,
                  ),
                  child: Dismissible(
                    key: Key(r.id),
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
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                    confirmDismiss: (_) => ConfirmDialog.show(
                      context,
                      title: 'Delete Reading?',
                      message: 'Delete the reading on '
                          '${r.formattedDate} (${r.kwh.toStringAsFixed(1)} '
                          'kWh)?',
                      confirmLabel: 'Delete',
                      confirmColor: AppColors.danger,
                      warning:
                          'This will also remove the associated bill entry.',
                    ),
                    onDismissed: (_) async {
                      final success = await ref
                          .read(billDetailProvider.notifier)
                          .deleteReading(r, bill);

                      if (success) {
                        ref
                          ..invalidate(usageProvider)
                          ..invalidate(dashboardProvider);
                        await ref.read(usageProvider.future);
                      }
                    },
                    child: GestureDetector(
                      onTap: () => onEditReading(r),
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
                                    r.formattedDate,
                                    style: AppTextStyles.bodyMd.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${r.kwh.toStringAsFixed(1)} kWh '
                                    '· ${r.tierLabel}',
                                    style: AppTextStyles.caption,
                                  ),
                                  if (r.notes.isNotEmpty) ...[
                                    SizedBox(height: 2.h),
                                    Text(
                                      r.notes,
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
                                        color: AppColors.text3
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      r.tariffType.label,
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
                                  '${r.reading.toStringAsFixed(0)} kWh',
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
              }).toList(),
            ),
          ),
      ],
    );
  }
}
