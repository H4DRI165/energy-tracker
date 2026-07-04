import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/ui/features/ft_settings/pg_tariff_calculator/notifier/notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    final tariffType = state.tariffType;
    final kwh = state.kwh;

    final total = TariffRates.calculate(kwh, tariffType);

    // Badge — EEI band for domestic, old tier for commercial.
    final eeiBand =
        tariffType == TariffType.domestic ? TariffRates.getEeiBand(kwh) : null;
    final commercialTier = tariffType == TariffType.commercial
        ? TariffRates.getTier(kwh, TariffType.commercial)
        : 0;
    final badgeLabel = tariffType == TariffType.domestic
        ? (eeiBand!.number == 0 ? 'No usage' : eeiBand.label)
        : TariffRates.tierBadgeLabel(commercialTier, TariffType.commercial);
    final badgeColor = tariffType == TariffType.domestic
        ? (eeiBand!.number == 0 ? AppColors.text3 : eeiBand.color)
        : TariffRates.getTierColor(commercialTier, TariffType.commercial);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPaddingH,
                  vertical: 8.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TariffTypeSwitch(selected: tariffType),
                    SizedBox(height: 16.h),
                    _KwhInputCard(controller: _controller, kwh: kwh),
                    SizedBox(height: 20.h),
                    Text(
                      'Bill Breakdown (${tariffType.shortLabel})',
                      style: AppTextStyles.bodyMd
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 10.h),
                    _BreakdownSection(
                      items: TariffRates.breakdownFor(kwh, tariffType),
                      kwh: kwh,
                      tariffType: tariffType,
                    ),
                    SizedBox(height: 8.h),
                    _TotalCard(
                      total: total,
                      minCharge: tariffType == TariffType.commercial
                          ? TariffRates.minChargeFor(TariffType.commercial)
                          : 0,
                      badgeLabel: badgeLabel,
                      badgeColor: badgeColor,
                    ),
                    SizedBox(height: 16.h),
                    _InfoCard(tariffType: tariffType),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
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

class _TariffTypeSwitch extends ConsumerWidget {
  const _TariffTypeSwitch({required this.selected});

  final TariffType selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: TariffType.values.map((type) {
        final isSelected = type == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: type == TariffType.values.first ? 8.w : 0,
            ),
            child: GestureDetector(
              onTap: () => ref
                  .read(tariffCalculatorProvider.notifier)
                  .setTariffType(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withValues(alpha: 0.08)
                      : AppColors.surface2,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(type.icon, style: TextStyle(fontSize: 16.sp)),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        type.shortLabel,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: AppTextStyles.bodySm.copyWith(
                          fontWeight: FontWeight.w700,
                          color:
                              isSelected ? AppColors.accent : AppColors.text2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x2600D4AA), Color(0x140099FF)],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.borderAccent),
      ),
      child: Column(
        children: [
          Text(
            'ENTER KWH',
            style: AppTextStyles.caption.copyWith(letterSpacing: 1),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            textAlign: TextAlign.center,
            style: AppTextStyles.displayLg.copyWith(
              color: AppColors.accent,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          Text(
            'kWh this month',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.text2),
          ),
        ],
      ),
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({
    required this.items,
    required this.kwh,
    required this.tariffType,
  });

  final List<ChargeLineItem> items;
  final double kwh;
  final TariffType tariffType;

  bool get _showAfaDisclaimer {
    if (tariffType == TariffType.commercial) return true;
    return kwh > 600;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      padding: EdgeInsets.all(12.r),
      child: Column(
        children: [
          ...items.map((item) => ChargeLineItemRow(item: item)),
          if (_showAfaDisclaimer) ...[
            Divider(height: 12.h, color: AppColors.border),
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
                    tariffType == TariffType.commercial
                        ? 'Excludes AFA — a monthly fuel adjustment '
                            'published by TNB. Applies to all commercial '
                            'usage.'
                        : 'Excludes AFA — a monthly fuel adjustment '
                            'published by TNB. Applies only above 600 kWh '
                            'for domestic.',
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

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.total,
    required this.minCharge,
    required this.badgeLabel,
    required this.badgeColor,
  });

  final double total;
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
  const _InfoCard({required this.tariffType});

  final TariffType tariffType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: tariffType == TariffType.domestic
          ? _DomesticInfo()
          : _CommercialInfo(),
    );
  }
}

class _DomesticInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '💡 TNB Domestic Tariff',
              style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(width: 6.w),
            Text(
              'post-Jul 2025',
              style: AppTextStyles.caption.copyWith(color: AppColors.text3),
            ),
          ],
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
              label: 'Energy (>1500 kWh)',
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
                    'Applies only above 600 kWh',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.text3),
                  ),
                  Text(
                    TariffRates.retailLabel,
                    style: AppTextStyles.bodyMd
                        .copyWith(fontWeight: FontWeight.w600),
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
                      style: AppTextStyles.caption
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'rate applies to entire monthly kWh',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.text3, fontSize: 10.sp),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
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
                    'On Energy + Cap + Net − EEI.\nApplies above 300 kWh.',
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _LevyCard(
                title: 'SST',
                rate: TariffRates.sstLabel,
                description:
                    'On net charge for the portion above 600 kWh only.',
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
              color: AppColors.text3,
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                'AFA excluded — a monthly fuel adjustment published '
                'by TNB. Applies only above 600 kWh.',
                style: AppTextStyles.caption.copyWith(color: AppColors.text3),
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
            : const Border(bottom: BorderSide(color: AppColors.border)),
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
            style: AppTextStyles.caption
                .copyWith(color: AppColors.warn, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          Text(
            rate,
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.warn, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4.h),
          Text(
            description,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.warn.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

class _CommercialInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '💡 TNB Non-Domestic LV Tariff',
              style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(width: 6.w),
            Text(
              'post-Jul 2025',
              style: AppTextStyles.caption.copyWith(color: AppColors.text3),
            ),
          ],
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
              label: 'Energy (flat rate)',
              value: TariffRates.generationLowLabel,
            ),
            _ComponentCard(
              label: 'Capacity',
              value: TariffRates.commercialCapacityLabel,
            ),
            _ComponentCard(
              label: 'Network',
              value: TariffRates.commercialNetworkLabel,
            ),
            _ComponentCard(
              label: 'Retail',
              value: TariffRates.commercialRetailLabel,
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
                  Text('EEI Rebate', style: AppTextStyles.caption),
                  SizedBox(height: 2.h),
                  Text(
                    'Applies only for ≤200 kWh',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.text3),
                  ),
                ],
              ),
              Text(
                '11.0 sen/kWh',
                style:
                    AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _LevyCard(
                title: 'KWTBB',
                rate: TariffRates.kwtbbLabel,
                description:
                    'On Energy + Cap + Net − EEI.\nNo exemption threshold.',
              ),
            ),
            SizedBox(width: 8.w),
            const Expanded(
              child: _LevyCard(
                title: 'SST',
                rate: 'N/A',
                description: 'Not applicable for Non-Domestic LV General.',
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
              color: AppColors.text3,
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                'AFA excluded — published monthly by TNB. '
                'No generation rate crossover at 1500 kWh '
                '(unlike domestic).',
                style: AppTextStyles.caption.copyWith(color: AppColors.text3),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
