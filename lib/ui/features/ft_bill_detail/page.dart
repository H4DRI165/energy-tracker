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

    final isReady = state.bill != null && !state.isLoading;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: isReady
          ? null
          : AppBar(backgroundColor: AppColors.bg, elevation: 0),
      body: SafeArea(
        child: Column(
          children: [
            if (isReady) _Header(bill: state.bill!),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BillDetailPageState state) {
    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Text(
            state.errorMessage!,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.danger),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (state.bill == null || state.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingH,
        vertical: 8.h,
      ),
      child: _BodyContent(onEditReading: _handleEditReading),
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
        BillBreakdownCard(
          items: TariffRates.breakdownFor(
            bill.kwh,
            billingMonth: bill.date,
          ),
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
    final effectiveRate = bill.kwh > 0 ? bill.amount / bill.kwh : null;
    final band = TariffRates.getEeiBand(bill.kwh);
    final bandTitle = bill.kwh <= 0
        ? 'No usage'
        : band.number == 0
        ? 'No rebate'
        : 'Band ${band.number}';
    final bandDetail = bill.kwh <= 0
        ? '—'
        : band.number == 0
        ? 'No EEI rebate'
        : '${band.rebateSenPerKwh.toStringAsFixed(1)} sen rebate';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ESTIMATED BILL',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accent,
                    letterSpacing: 2,
                  ),
                ),
              ),
              if (bill.isEstimated) ...[
                SizedBox(width: 8.w),
                Tooltip(
                  message:
                      'This month includes usage estimated from a reading gap.',
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warn.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppColors.warn.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 10.r,
                          color: AppColors.warn,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          'Estimated',
                          style: AppTextStyles.tag.copyWith(
                            color: AppColors.warn,
                            fontSize: 9.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'RM ${bill.amount.toStringAsFixed(2)}',
            style: AppTextStyles.displayLg.copyWith(color: AppColors.text),
          ),
          SizedBox(height: 14.h),
          Container(
            height: 1,
            color: AppColors.border,
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _BillSummaryStat(
                  label: 'ENERGY USED',
                  value: '${bill.kwh.toStringAsFixed(0)} kWh',
                ),
              ),
              const _SummaryDivider(),
              Expanded(
                child: _BillSummaryStat(
                  label: 'EFFECTIVE RATE',
                  value: effectiveRate == null
                      ? '—'
                      : 'RM ${effectiveRate.toStringAsFixed(2)}',
                  detail: effectiveRate == null ? null : 'per kWh',
                ),
              ),
              const _SummaryDivider(),
              Expanded(
                child: _BillSummaryStat(
                  label: 'EEI BAND',
                  value: bandTitle,
                  detail: bandDetail,
                  valueColor: bill.kwh <= 0 ? null : band.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillSummaryStat extends StatelessWidget {
  const _BillSummaryStat({
    required this.label,
    required this.value,
    this.detail,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? detail;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.text3,
            fontSize: 9.sp,
            letterSpacing: 0.6,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMd.copyWith(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.text,
          ),
        ),
        if (detail != null) ...[
          SizedBox(height: 2.h),
          Text(
            detail!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.text3,
              fontSize: 9.sp,
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34.h,
      margin: EdgeInsets.symmetric(horizontal: 10.w),
      color: AppColors.border,
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
                  'Tap for details',
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
        if (state.hasMoreReadings) ...[
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 12.r,
                color: AppColors.text3,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'Showing the latest '
                  '${BillDetailNotifier.maxReadingsPerMonth} readings for '
                  'this month.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.text3,
                  ),
                ),
              ),
            ],
          ),
        ],
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
        confirmDismiss: (_) => _confirmDelete(context),
        onDismissed: (_) async {
          await _deleteReading(ref);
        },
        child: GestureDetector(
          onTap: () => _openReadingDetails(context, ref),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 12.h,
            ),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
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

  Future<void> _openReadingDetails(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final action = await showAppBottomSheet<_ReadingSheetAction>(
      context: context,
      builder: (_) => AppBottomSheet(
        child: _ReadingDetailsSheet(
          reading: reading,
          tierLabel: tierLabel,
        ),
      ),
    );

    if (!context.mounted || action == null) return;

    if (action == _ReadingSheetAction.edit) {
      await onEdit(reading);
      return;
    }

    final confirmed = await _confirmDelete(context);
    if (confirmed && context.mounted) {
      await _deleteReading(ref);
    }
  }

  Future<bool> _confirmDelete(BuildContext context) {
    return ConfirmDialog.show(
      context,
      title: 'Delete Reading?',
      message:
          'Delete the reading on '
          '${reading.formattedDate} (${reading.kwh.toStringAsFixed(1)} '
          'kWh)?',
      confirmLabel: 'Delete',
      confirmColor: AppColors.danger,
      warning: 'This will also remove the associated bill entry.',
    );
  }

  Future<void> _deleteReading(WidgetRef ref) async {
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
  }
}

enum _ReadingSheetAction { edit, delete }

class _ReadingDetailsSheet extends StatelessWidget {
  const _ReadingDetailsSheet({
    required this.reading,
    required this.tierLabel,
  });

  final ReadingRecord reading;
  final String tierLabel;

  @override
  Widget build(BuildContext context) {
    final periodStart = reading.periodStart;
    final intervalValue = reading.kwh > 0
        ? '+${reading.kwh.toStringAsFixed(1)} kWh'
        : 'Baseline reading';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Reading details',
                style: AppTextStyles.titleMd,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              tooltip: 'Close',
              icon: Icon(
                Icons.close_rounded,
                size: 20.r,
                color: AppColors.text2,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meter reading',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.text2,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '${reading.reading.toStringAsFixed(0)} kWh',
                style: AppTextStyles.statMd.copyWith(
                  color: AppColors.accent,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                reading.formattedDate,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.text3,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        _ReadingInfoRow(label: 'Interval usage', value: intervalValue),
        if (periodStart != null) ...[
          SizedBox(height: 8.h),
          _ReadingInfoRow(
            label: 'Since',
            value: periodStart.shortDayLabel,
          ),
        ],
        SizedBox(height: 8.h),
        _ReadingInfoRow(label: 'EEI rebate', value: tierLabel),
        if (reading.notes.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Text(
            'Notes',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.text3,
            ),
          ),
          SizedBox(height: 3.h),
          Text(reading.notes, style: AppTextStyles.bodySm),
        ],
        SizedBox(height: 20.h),
        GradientButton(
          label: 'Edit reading',
          isLoading: false,
          onTap: () => Navigator.pop(
            context,
            _ReadingSheetAction.edit,
          ),
        ),
        SizedBox(height: 2.h),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            _ReadingSheetAction.delete,
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.danger,
            minimumSize: Size.fromHeight(48.h),
          ),
          child: Text(
            'Delete reading',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          "Editing a reading can recalculate this month's bill.",
          style: AppTextStyles.caption.copyWith(
            color: AppColors.text3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ReadingInfoRow extends StatelessWidget {
  const _ReadingInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.text2),
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          value,
          style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}
