import 'dart:async';

import 'package:energy_tracker/models/bill_record.dart';
import 'package:energy_tracker/models/reading_record.dart';
import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/features/ft_bill_detail/notifier/bill_detail_notifier.dart';
import 'package:energy_tracker/ui/features/ft_bill_detail/notifier/bill_detail_state.dart';
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(bill: widget.bill),
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
                          child: _BodyContent(state: state, bill: widget.bill),
                        ),
            ),
          ],
        ),
      ),
    );
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
    required this.state,
    required this.bill,
  });

  final BillDetailPageState state;
  final BillRecord bill;

  @override
  ConsumerState<_BodyContent> createState() => _BodyContentState();
}

class _BodyContentState extends ConsumerState<_BodyContent> {
  @override
  Widget build(BuildContext context) {
    final tierBreakdown = _tierBreakdown(widget.bill.kwh);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BillSummaryCard(bill: widget.bill),
        SizedBox(height: 16.h),
        _PaidToggleCard(
          isPaid: widget.state.isPaid,
          isUpdating: widget.state.isUpdatingPaid,
          onToggle: () async {
            await ref.read(billDetailProvider.notifier).togglePaid(widget.bill);
            ref.invalidate(usageProvider);
          },
        ),
        SizedBox(height: 16.h),
        _TierBreakdownCard(
          tiers: tierBreakdown,
          totalKwh: widget.bill.kwh,
        ),
        SizedBox(height: 16.h),
        _ReadingsSection(readings: widget.state.readings),
        SizedBox(height: 24.h),
      ],
    );
  }

  List<_TierRow> _tierBreakdown(double kwh) {
    final rows = <_TierRow>[];
    if (kwh <= 0) return rows;

    final t1 = kwh.clamp(0.0, 200.0);
    rows.add(
      _TierRow(
        label: 'Tier 1 · 1–200 kWh · 21.8 sen',
        kwh: t1,
        amount: t1 * 0.218,
        color: AppColors.accent,
        fraction: t1 / kwh,
      ),
    );

    if (kwh > 200) {
      final t2 = (kwh - 200).clamp(0.0, 100.0);
      rows.add(
        _TierRow(
          label: 'Tier 2 · 201–300 kWh · 33.4 sen',
          kwh: t2,
          amount: t2 * 0.334,
          color: AppColors.warn,
          fraction: t2 / kwh,
        ),
      );
    }
    if (kwh > 300) {
      final t3 = (kwh - 300).clamp(0.0, 300.0);
      rows.add(
        _TierRow(
          label: 'Tier 3 · 301–600 kWh · 51.6 sen',
          kwh: t3,
          amount: t3 * 0.516,
          color: AppColors.danger,
          fraction: t3 / kwh,
        ),
      );
    }
    if (kwh > 600) {
      final t4 = kwh - 600;
      rows.add(
        _TierRow(
          label: 'Tier 4 · 601+ kWh · 54.6 sen',
          kwh: t4,
          amount: t4 * 0.546,
          color: AppColors.accent3,
          fraction: t4 / kwh,
        ),
      );
    }
    return rows;
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

class _TierRow {
  const _TierRow({
    required this.label,
    required this.kwh,
    required this.amount,
    required this.color,
    required this.fraction,
  });
  final String label;
  final double kwh;
  final double amount;
  final Color color;
  final double fraction;
}

class _TierBreakdownCard extends StatelessWidget {
  const _TierBreakdownCard({
    required this.tiers,
    required this.totalKwh,
  });

  final List<_TierRow> tiers;
  final double totalKwh;

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
            'Tariff Tier Breakdown',
            style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 14.h),
          ...tiers.map(
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
                      value: tier.fraction,
                      minHeight: 6.h,
                      backgroundColor: AppColors.surface3,
                      valueColor: AlwaysStoppedAnimation<Color>(tier.color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingsSection extends StatelessWidget {
  const _ReadingsSection({required this.readings});
  final List<ReadingRecord> readings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Readings This Month',
          style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
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

                return Container(
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
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
