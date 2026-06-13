import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/features/ft_settings/pg_tariff_calculator/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TariffCalculatorPage extends StatefulWidget {
  const TariffCalculatorPage({super.key});

  @override
  State<TariffCalculatorPage> createState() => _TariffCalculatorPageState();
}

class _TariffCalculatorPageState extends State<TariffCalculatorPage> {
  final _controller = TextEditingController(text: '350');
  TariffCalculatorState _state = const TariffCalculatorState();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final value = double.tryParse(_controller.text) ?? 0;
      if (value != _state.kwh) {
        setState(() {
          _state = _state.copyWith(kwh: value);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    _KwhInputCard(controller: _controller, kwh: _state.kwh),
                    SizedBox(height: 20.h),
                    Text(
                      'Tariff Breakdown (Domestic)',
                      style: AppTextStyles.bodyMd
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 10.h),
                    _TierRow(
                      tierLabel: 'Tier 1 · ${TariffRates.getTierKwhRange(1)}',
                      rateLabel: '${_state.tier1Kwh.toStringAsFixed(0)} '
                          'kWh × ${TariffRates.getTierPrice(1)}',
                      amount: _state.tier1,
                      color: AppColors.accent,
                      isActive: _state.kwh > 0,
                    ),
                    SizedBox(height: 8.h),
                    _TierRow(
                      tierLabel: 'Tier 2 · ${TariffRates.getTierKwhRange(2)}',
                      rateLabel: '${_state.tier2Kwh.toStringAsFixed(0)} '
                          'kWh × ${TariffRates.getTierPrice(2)}',
                      amount: _state.tier2,
                      color: AppColors.warn,
                      isActive: _state.kwh > 200,
                    ),
                    SizedBox(height: 8.h),
                    _TierRow(
                      tierLabel: 'Tier 3 · ${TariffRates.getTierKwhRange(3)}',
                      rateLabel: '${_state.tier3Kwh.toStringAsFixed(0)} '
                          'kWh × ${TariffRates.getTierPrice(3)}',
                      amount: _state.tier3,
                      color: AppColors.danger,
                      isActive: _state.kwh > 300,
                    ),
                    if (_state.hasTier4) ...[
                      SizedBox(height: 8.h),
                      _TierRow(
                        tierLabel: 'Tier 4 · ${TariffRates.getTierKwhRange(4)}',
                        rateLabel: '${_state.tier4Kwh.toStringAsFixed(0)} '
                            'kWh × ${TariffRates.getTierPrice(4)}',
                        amount: _state.tier4,
                        color: AppColors.danger,
                        isActive: true,
                      ),
                    ],
                    if (_state.hasTier5) ...[
                      SizedBox(height: 8.h),
                      _TierRow(
                        tierLabel: 'Tier 5 · ${TariffRates.getTierKwhRange(5)}',
                        rateLabel: '${_state.tier5Kwh.toStringAsFixed(0)} '
                            'kWh × ${TariffRates.getTierPrice(5)}',
                        amount: _state.tier4,
                        color: AppColors.danger,
                        isActive: true,
                      ),
                    ],
                    SizedBox(height: 16.h),
                    _TotalCard(
                      total: _state.total,
                      minCharge: _state.minCharge,
                      tierBadgeLabel: _state.tierBadgeLabel,
                      tierBadgeColor: _state.tierBadgeColor,
                    ),
                    SizedBox(height: 16.h),
                    _InfoCard(),
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
              width: 3,
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
  @override
  Widget build(BuildContext context) {
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
            '💡 TNB Domestic Tariff Rates',
            style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8.h),
          _RateRow(
            'Tier 1',
            TariffRates.getTierKwhRange(1),
            '${TariffRates.getTierPrice(1)}/kWh',
          ),
          _RateRow(
            'Tier 2',
            TariffRates.getTierKwhRange(2),
            '${TariffRates.getTierPrice(2)}/kWh',
          ),
          _RateRow(
            'Tier 3',
            TariffRates.getTierKwhRange(3),
            '${TariffRates.getTierPrice(3)}/kWh',
          ),
          _RateRow(
            'Tier 4',
            TariffRates.getTierKwhRange(4),
            '${TariffRates.getTierPrice(4)}/kWh',
          ),
          _RateRow(
            'Tier 5',
            TariffRates.getTierKwhRange(5),
            '${TariffRates.getTierPrice(5)}/kWh',
          ),
          Divider(height: 16.h, color: AppColors.border),
          Text(
            'Minimum charge: RM 3.00/month',
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
