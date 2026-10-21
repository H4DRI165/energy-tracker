import 'dart:async';

import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/ui/features/ft_settings/pg_tariff_calculator/notifier/notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class TariffCalculatorPage extends ConsumerStatefulWidget {
  const TariffCalculatorPage({super.key});

  @override
  ConsumerState<TariffCalculatorPage> createState() =>
      _TariffCalculatorPageState();
}

class _TariffCalculatorPageState extends ConsumerState<TariffCalculatorPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initialKwh = ref.read(tariffCalculatorProvider).kwh;
    _controller = TextEditingController(text: initialKwh.toStringAsFixed(0));
    _controller.addListener(() {
      final value = double.tryParse(_controller.text) ?? 0;
      ref.read(tariffCalculatorProvider.notifier).setKwh(value);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tariffCalculatorProvider);
    final kwh = state.kwh;

    final total = TariffRates.calculate(kwh);

    final eeiBand = TariffRates.getEeiBand(kwh);
    // Band number 0 means "above 1,000 kWh / no rebate", not "no usage".
    final isNoUsage = kwh <= 0;
    final badgeLabel = isNoUsage ? 'No usage' : eeiBand.label;
    final badgeColor = isNoUsage ? AppColors.text3 : eeiBand.color;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              _Header(),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPaddingH,
                    vertical: 8.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _KwhInputCard(controller: _controller, kwh: kwh),
                      SizedBox(height: 14.h),
                      _TotalCard(
                        total: total,
                        kwh: kwh,
                        minCharge: TariffRates.minCharge,
                        badgeLabel: badgeLabel,
                        badgeColor: badgeColor,
                      ),
                      SizedBox(height: 16.h),
                      BillBreakdownCard(
                        items: TariffRates.breakdownFor(kwh),
                        emptyLabel: 'Enter usage above 0 kWh to see charges.',
                        title: 'Why this amount?',
                        subtitle: 'Tap any charge to learn what it means.',
                        collapsible: false,
                        initiallyExpanded: true,
                        padding: EdgeInsets.all(16.r),
                      ),
                      SizedBox(height: 16.h),
                      const _InfoCard(),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.screenPaddingH,
        12.h,
        AppDimensions.screenPaddingH,
        8.h,
      ),
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16.r,
                color: AppColors.text2,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Text('Tariff Calculator', style: AppTextStyles.titleMd),
        ],
      ),
    );
  }
}

class _KwhInputCard extends StatelessWidget {
  const _KwhInputCard({
    required this.controller,
    required this.kwh,
  });

  final TextEditingController controller;
  final double kwh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.borderAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 16.r,
                color: AppColors.accent,
              ),
              SizedBox(width: 6.w),
              Text(
                'Monthly usage',
                style: AppTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Tap to edit',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            textAlign: TextAlign.center,
            style: AppTextStyles.displayLg.copyWith(
              color: AppColors.accent,
              fontSize: 34.sp,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: AppTextStyles.displayLg.copyWith(
                color: AppColors.text3,
                fontSize: 34.sp,
              ),
              suffixText: 'kWh',
              suffixStyle: AppTextStyles.bodyMd.copyWith(
                color: AppColors.text2,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 14.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: BorderSide(
                  color: AppColors.accent,
                  width: 1.5,
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Enter the kWh from your TNB bill. This is not your meter reading.',
            style: AppTextStyles.caption.copyWith(color: AppColors.text3),
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.total,
    required this.kwh,
    required this.minCharge,
    required this.badgeLabel,
    required this.badgeColor,
  });

  final double total;
  final double kwh;
  final double minCharge;
  final String badgeLabel;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x1A00D4AA), Color(0x0F0099FF)],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.borderAccent),
      ),
      child: Column(
        children: [
          Text(
            'ESTIMATED BILL',
            style: AppTextStyles.caption.copyWith(letterSpacing: 1),
          ),
          SizedBox(height: 4.h),
          Text(
            'RM ${total.toStringAsFixed(2)}',
            style: AppTextStyles.displayLg.copyWith(color: AppColors.accent),
          ),
          SizedBox(height: 4.h),
          Text(
            'Calculated from ${kwh.toStringAsFixed(0)} kWh ? read-only',
            style: AppTextStyles.caption.copyWith(color: AppColors.text3),
          ),
          if (minCharge > 0) ...[
            SizedBox(height: 4.h),
            Text(
              '+ RM ${minCharge.toStringAsFixed(2)} min charge applied',
              style: AppTextStyles.bodySm,
            ),
          ],
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              badgeLabel,
              style: AppTextStyles.tag.copyWith(color: badgeColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _showTariffReference(context),
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Row(
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 18.r,
                color: AppColors.accent,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tariff reference',
                      style: AppTextStyles.bodySm.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Rates, EEI bands, levies and AFA',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.text3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18.r,
                color: AppColors.text3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showTariffReference(BuildContext context) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              Center(
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.text3.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 8.w, 4.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tariff reference',
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
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 28.h),
                  child: _DomesticInfo(),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DomesticInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final afaSen = TariffRates.afaSenPerKwhFor(now);
    final monthLabel = DateFormat('MMM yyyy').format(now);
    final effectiveLabel = DateFormat(
      'd MMM yyyy',
    ).format(TariffRates.tariff.effectiveFrom);
    final afaNote = afaSen == null
        ? 'AFA for $monthLabel has not been published yet, so it is excluded '
              'from the estimate.'
        : 'AFA of ${afaSen.toStringAsFixed(2)} sen/kWh applies only to usage '
              'above ${TariffRates.protectionThresholdLabel} in $monthLabel.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TNB Domestic Tariff',
          style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 3.h),
        Text(
          'Effective $effectiveLabel \u00b7 AFA $monthLabel',
          style: AppTextStyles.caption.copyWith(color: AppColors.text3),
        ),
        SizedBox(height: 12.h),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8.w,
          mainAxisSpacing: 8.h,
          childAspectRatio: 2.4,
          children: [
            _ComponentCard(
              label: 'Energy (≤1500 kWh)',
              value: TariffRates.generationLowLabel,
            ),
            _ComponentCard(
              label: 'Energy (above 1,500 kWh)',
              value: TariffRates.generationHighLabel,
            ),
            _ComponentCard(
              label: 'Capacity',
              value: TariffRates.capacityLabel,
            ),
            _ComponentCard(
              label: 'Network',
              value: TariffRates.networkLabel,
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Retail charge', style: AppTextStyles.caption),
                  SizedBox(height: 2.h),
                  Text(
                    'Applies only above '
                    '${TariffRates.protectionThresholdLabel}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.text3,
                    ),
                  ),
                  Text(
                    TariffRates.retailLabel,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'EEI rebate bands',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'rate applies to entire monthly kWh',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.text3,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.border),
              for (final group in TariffRates.eeiBandGroups)
                _EeiBandRow(
                  group.range,
                  group.rebateRange,
                  group.isHighUsage ? AppColors.danger : AppColors.accent,
                  isLast: group == TariffRates.eeiBandGroups.last,
                ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _LevyCard(
                title: 'KWTBB',
                rate: TariffRates.kwtbbLabel,
                description:
                    'On energy, capacity and network charges, minus EEI.\n'
                    'Not charged at or below 300 kWh.',
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _LevyCard(
                title: 'SST',
                rate: TariffRates.sstLabel,
                description:
                    'On the taxable portion only, above '
                    '${TariffRates.protectionThresholdLabel}.',
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 12.r,
              color: afaSen == null ? AppColors.warn : AppColors.text3,
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                afaNote,
                style: AppTextStyles.caption.copyWith(
                  color: afaSen == null ? AppColors.warn : AppColors.text3,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ComponentCard extends StatelessWidget {
  const _ComponentCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.text3),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _EeiBandRow extends StatelessWidget {
  const _EeiBandRow(
    this.range,
    this.rebate,
    this.color, {
    this.isLast = false,
  });

  final String range;
  final String rebate;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              child: Text(range, style: AppTextStyles.caption),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            child: Text(
              rebate,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevyCard extends StatelessWidget {
  const _LevyCard({
    required this.title,
    required this.rate,
    required this.description,
  });

  final String title;
  final String rate;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: AppColors.warn.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: AppColors.warn.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.warn,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            rate,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.warn,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            description,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.warn.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
