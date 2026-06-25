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

    final breakdown = TariffRates.breakdownFor(kwh, tariffType);
    final total = TariffRates.calculate(kwh, tariffType);
    final minCharge = TariffRates.minChargeFor(tariffType);
    final currentTier = TariffRates.getTier(kwh, tariffType);
    final tierBadgeLabel = TariffRates.tierBadgeLabel(currentTier, tariffType);
    final tierBadgeColor = TariffRates.getTierColor(currentTier, tariffType);

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
                      'Tariff Breakdown (${tariffType.label})',
                      style: AppTextStyles.bodyMd
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 10.h),
                    for (final tier in breakdown) ...[
                      _TierRow(
                        tierLabel: tier.label,
                        rateLabel: '${tier.kwh.toStringAsFixed(0)} kWh × '
                            '${(tier.rate * 100).toStringAsFixed(1)} sen',
                        amount: tier.amount,
                        color: tier.color,
                        isActive: tier.kwh > 0,
                      ),
                      SizedBox(height: 8.h),
                    ],
                    _TotalCard(
                      total: total,
                      minCharge: minCharge,
                      tierBadgeLabel: tierBadgeLabel,
                      tierBadgeColor: tierBadgeColor,
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

class _TierRow extends StatelessWidget {
  const _TierRow({
    required this.tierLabel,
    required this.rateLabel,
    required this.amount,
    required this.color,
    required this.isActive,
  });

  final String tierLabel;
  final String rateLabel;
  final double amount;
  final Color color;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isActive ? 1.0 : 0.35,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3.w,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.radiusMd),
                  bottomLeft: Radius.circular(AppDimensions.radiusMd),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.r),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tierLabel,
                            style: AppTextStyles.bodySm.copyWith(
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(rateLabel, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Text(
                      'RM ${amount.toStringAsFixed(2)}',
                      style: AppTextStyles.statMd.copyWith(fontSize: 16.sp),
                    ),
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

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.total,
    required this.minCharge,
    required this.tierBadgeLabel,
    required this.tierBadgeColor,
  });

  final double total;
  final double minCharge;
  final String tierBadgeLabel;
  final Color tierBadgeColor;

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
              color: tierBadgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              tierBadgeLabel,
              style: AppTextStyles.tag.copyWith(color: tierBadgeColor),
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
    final tierCount = tariffType == TariffType.commercial ? 2 : 5;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 TNB ${tariffType.label} Tariff Rates',
            style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8.h),
          for (var tier = 1; tier <= tierCount; tier++)
            _RateRow(
              'Tier $tier',
              TariffRates.getTierKwhRange(tier, tariffType),
              '${TariffRates.getTierPrice(tier, tariffType)}/kWh',
            ),
          Divider(height: 16.h, color: AppColors.border),
          Text(
            'Minimum charge: RM '
            '${TariffRates.minChargeFor(tariffType).toStringAsFixed(2)}'
            '/month',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow(
    this.tier,
    this.range,
    this.rate,
  );
  final String tier;
  final String range;
  final String rate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          SizedBox(
            width: 44.w,
            child: Text(tier, style: AppTextStyles.caption),
          ),
          SizedBox(
            width: 90.w,
            child: Text(range, style: AppTextStyles.caption),
          ),
          Text(
            rate,
            style: AppTextStyles.caption.copyWith(color: AppColors.text),
          ),
        ],
      ),
    );
  }
}
