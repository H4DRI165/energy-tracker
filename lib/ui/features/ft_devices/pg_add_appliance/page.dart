import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/services/notifiers/user_profile_notifier.dart';
import 'package:energy_tracker/ui/features/ft_devices/pg_add_appliance/notifier/notifier.dart';
import 'package:energy_tracker/ui/features/ft_devices/pg_devices/notifier/devices_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AddAppliancePage extends ConsumerStatefulWidget {
  const AddAppliancePage({
    this.appliance,
    super.key,
  });

  final Appliance? appliance;

  @override
  ConsumerState<AddAppliancePage> createState() => _AddAppliancePageState();
}

class _AddAppliancePageState extends ConsumerState<AddAppliancePage> {
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.appliance != null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              _Header(isEdit: isEdit),
              _BodyContent(
                isEdit: isEdit,
                appliance: widget.appliance,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.isEdit = false});

  final bool isEdit;

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
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: IconButton(
              onPressed: () => context.pop(),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16.r,
                color: AppColors.text2,
              ),
              tooltip: 'Back',
              padding: EdgeInsets.zero,
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            isEdit ? 'Edit Appliance' : 'Add Appliance',
            style: AppTextStyles.titleMd,
          ),
        ],
      ),
    );
  }
}

class _BodyContent extends ConsumerStatefulWidget {
  const _BodyContent({
    required this.appliance,
    this.isEdit = false,
  });

  final Appliance? appliance;
  final bool isEdit;

  @override
  ConsumerState<_BodyContent> createState() => _BodyContentState();
}

class _BodyContentState extends ConsumerState<_BodyContent> {
  late final TextEditingController _nameController;
  late final TextEditingController _wattageController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _wattageController = TextEditingController();

    if (widget.appliance != null) {
      final appliance = widget.appliance!;

      _nameController.text = appliance.name;
      _wattageController.text = appliance.wattage.toStringAsFixed(0);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(addApplianceProvider.notifier).initForEdit(appliance);
      });
    }

    _nameController.addListener(
      () =>
          ref.read(addApplianceProvider.notifier).setName(_nameController.text),
    );

    _wattageController.addListener(
      () => ref
          .read(addApplianceProvider.notifier)
          .setWattage(_wattageController.text),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wattageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tariffType = ref.watch(tariffTypeProvider);
    final category = ref.watch(
      addApplianceProvider.select((state) => state.category),
    );
    final nameError = ref.watch(
      addApplianceProvider.select((state) => state.nameError),
    );
    final wattageError = ref.watch(
      addApplianceProvider.select((state) => state.wattageError),
    );
    final dailyHours = ref.watch(
      addApplianceProvider.select((state) => state.dailyHours),
    );
    final errorMessage = ref.watch(
      addApplianceProvider.select((state) => state.errorMessage),
    );
    final isSaving = ref.watch(
      addApplianceProvider.select((state) => state.isSaving),
    );
    final canSave = ref.watch(
      addApplianceProvider.select((state) => state.canSave),
    );

    return Expanded(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPaddingH,
          vertical: 4.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category', style: AppTextStyles.label),
            SizedBox(height: 8.h),
            _CategoryGrid(
              selected: category,
              onSelect: (c) =>
                  ref.read(addApplianceProvider.notifier).setCategory(c),
            ),
            SizedBox(height: 16.h),
            AppTextField(
              label: 'Appliance Name',
              controller: _nameController,
              hintText: 'e.g. Air Conditioner (Bedroom)',
              prefixIcon: Icons.electrical_services_rounded,
              textCapitalization: TextCapitalization.words,
              errorText: nameError,
            ),
            SizedBox(height: 16.h),
            AppTextField(
              label: 'Wattage (W)',
              controller: _wattageController,
              hintText: '0',
              prefixIcon: Icons.bolt_rounded,
              keyboardType: TextInputType.number,
              errorText: wattageError,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            SizedBox(height: 16.h),
            Text('Daily Usage (hours)', style: AppTextStyles.label),
            SizedBox(height: 8.h),
            _HoursStepper(
              hours: dailyHours,
              onIncrement: () =>
                  ref.read(addApplianceProvider.notifier).incrementHours(),
              onDecrement: () =>
                  ref.read(addApplianceProvider.notifier).decrementHours(),
            ),
            SizedBox(height: 16.h),
            _MonthlyEstimateCard(
              tariffType: tariffType,
            ),
            SizedBox(height: 24.h),
            if (errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  errorMessage,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
                ),
              ),
              SizedBox(height: 16.h),
            ],
            GradientButton(
              label: widget.isEdit ? 'Save Changes' : 'Add Appliance',
              isLoading: isSaving,
              isEnabled: canSave,
              onTap: _handleSave,
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final success = await ref.read(addApplianceProvider.notifier).save();
    if (success && mounted) {
      ref.invalidate(devicesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.accent,
                size: 18,
              ),
              SizedBox(width: 10.w),
              Text(
                widget.appliance != null
                    ? 'Appliance updated'
                    : 'Appliance added',
                style: AppTextStyles.bodyMd,
              ),
            ],
          ),
          backgroundColor: AppColors.surface2,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
      );
      if (context.mounted) context.pop();
    }
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.selected,
    required this.onSelect,
  });

  final String selected;
  final ValueChanged<String> onSelect;

  static const _items = [
    ('Cooling', '❄️'),
    ('Lighting', '💡'),
    ('Kitchen', '🍳'),
    ('Entertainment', '🖥️'),
    ('Washing', '🫧'),
    ('Heating', '🌡️'),
    ('Other', '🔌'),
  ];

  String get _hint {
    switch (selected) {
      case 'Cooling':
        return 'Typical AC: 900–2000W';
      case 'Lighting':
        return 'Typical LED bulb: 5–15W';
      case 'Kitchen':
        return 'Typical fridge: 100–400W';
      case 'Heating':
        return 'Typical water heater: 2000–3500W';
      case 'Entertainment':
        return 'Typical TV: 50–200W';
      case 'Washing':
        return 'Typical washing machine: 500–1000W';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hint = _hint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8.w,
          mainAxisSpacing: 8.h,
          children: _items.map((item) {
            final isSelected = selected == item.$1;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelect(item.$1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent2.withValues(alpha: 0.1)
                        : AppColors.surface2,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent2.withValues(alpha: 0.3)
                          : AppColors.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.$2, style: TextStyle(fontSize: 20.sp)),
                      SizedBox(height: 4.h),
                      Text(
                        item.$1,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 9.sp,
                          color: isSelected
                              ? AppColors.accent2
                              : AppColors.text3,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (hint.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 12.r,
                color: AppColors.accent2,
              ),
              SizedBox(width: 6.w),
              Text(
                hint,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.accent2,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HoursStepper extends StatelessWidget {
  const _HoursStepper({
    required this.hours,
    required this.onIncrement,
    required this.onDecrement,
  });

  final double hours;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onDecrement,
            child: Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                Icons.remove_rounded,
                size: 20.r,
                color: AppColors.text2,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 44.h,
            margin: EdgeInsets.symmetric(horizontal: 8.w),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                hours % 1 == 0 ? '${hours.toInt()}h' : '${hours}h',
                style: AppTextStyles.titleMd,
              ),
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onIncrement,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            child: Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(Icons.add_rounded, size: 20.r, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthlyEstimateCard extends ConsumerWidget {
  const _MonthlyEstimateCard({
    required this.tariffType,
  });

  final TariffType tariffType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyKwh = ref.watch(
      addApplianceProvider.select((state) => state.monthlyKwh),
    );
    final monthlyCost = ref.watch(
      addApplianceProvider.select((state) => state.monthlyCost(tariffType)),
    );
    final dailyKwh = ref.watch(
      addApplianceProvider.select((state) => state.dailyKwh),
    );
    final dailyCost = ref.watch(
      addApplianceProvider.select((state) => state.dailyCost(tariffType)),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent2.withValues(alpha: 0.08),
            AppColors.accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.accent2.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MONTHLY ESTIMATE',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.accent2,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _EstimateStat(
                  label: 'Energy/month',
                  value: '${monthlyKwh.toStringAsFixed(1)} kWh',
                ),
              ),
              Expanded(
                child: _EstimateStat(
                  label: 'Cost/month',
                  value: 'RM ${monthlyCost.toStringAsFixed(2)}',
                  valueColor: AppColors.accent,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _EstimateStat(
                  label: 'Energy/day',
                  value: '${dailyKwh.toStringAsFixed(3)} kWh',
                ),
              ),
              Expanded(
                child: _EstimateStat(
                  label: 'Cost/day',
                  value: 'RM ${dailyCost.toStringAsFixed(3)}',
                  valueColor: AppColors.accent,
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
                size: 11.r,
                color: AppColors.text3,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  'Based on flat energy, capacity & network rates '
                  '(${(TariffRates.marginalRatePerKwh(tariffType) * 100).toStringAsFixed(2)} sen/kWh). '
                  '${tariffType == TariffType.domestic ? 'Excludes EEI rebate, '
                            'KWTBB & SST' : 'Excludes KWTBB & SST'} — these depend '
                  'on your total ${tariffType == TariffType.domestic ? 'household' : 'business'} usage.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.text3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EstimateStat extends StatelessWidget {
  const _EstimateStat({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        SizedBox(height: 4.h),
        Text(
          value,
          style: AppTextStyles.titleMd.copyWith(
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
