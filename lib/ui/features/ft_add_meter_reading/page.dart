import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/services/notifier/user_profile_notifier.dart';
import 'package:energy_tracker/ui/features/ft_add_meter_reading/notifier/notifier.dart';
import 'package:energy_tracker/ui/features/ft_dashboard/notifier/dashboard_notifier.dart';
import 'package:energy_tracker/ui/features/ft_usage/notifier/usage_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AddReadingPage extends StatelessWidget {
  const AddReadingPage({
    this.reading,
    super.key,
  });

  final ReadingRecord? reading;
  bool get _isEdit => reading != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              _Header(
                isEdit: _isEdit,
              ),
              _BodyContent(
                reading: reading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isEdit,
  });

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
          Expanded(
            child: Text(
              isEdit ? 'Edit Meter Reading' : 'Add Meter Reading',
              style: AppTextStyles.titleMd,
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyContent extends ConsumerStatefulWidget {
  const _BodyContent({
    this.reading,
  });

  final ReadingRecord? reading;

  @override
  ConsumerState<_BodyContent> createState() => _BodyContentState();
}

class _BodyContentState extends ConsumerState<_BodyContent> {
  late final TextEditingController _readingController;
  late final TextEditingController _notesController;

  bool get _isEdit => widget.reading != null;

  @override
  void initState() {
    super.initState();
    _readingController = TextEditingController();
    _notesController = TextEditingController();

    if (_isEdit) {
      final r = widget.reading!;
      _readingController.text = r.reading.toStringAsFixed(0);
      _notesController.text = r.notes;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(addReadingProvider.notifier).initForEdit(r);
      });
    }

    _readingController.addListener(
      () => ref
          .read(addReadingProvider.notifier)
          .setReading(
            _readingController.text,
          ),
    );
    _notesController.addListener(
      () => ref
          .read(addReadingProvider.notifier)
          .setNotes(
            _notesController.text,
          ),
    );
  }

  @override
  void dispose() {
    _readingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  TariffType get _effectiveTariffType {
    if (_isEdit) return widget.reading!.tariffType;
    return ref.watch(tariffTypeProvider);
  }

  @override
  Widget build(BuildContext context) {
    final tariffType = _effectiveTariffType;

    return Expanded(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPaddingH,
          vertical: 8.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _LastReadingCard(),
            SizedBox(height: 20.h),
            Text('Reading Date', style: AppTextStyles.label),
            SizedBox(height: 6.h),
            _DatePickerField(
              isEdit: _isEdit,
              onPick: () => _pickDate(context),
            ),
            SizedBox(height: 16.h),
            Text('Meter Reading (kWh)', style: AppTextStyles.label),
            SizedBox(height: 6.h),
            _MeterReadingField(
              controller: _readingController,
            ),
            SizedBox(height: 10.h),
            _TariffTypeNote(tariffType: tariffType, isEdit: _isEdit),
            SizedBox(height: 16.h),
            _AutoCalcCard(
              tariffType: tariffType,
            ),
            Text('Notes (optional)', style: AppTextStyles.label),
            SizedBox(height: 6.h),
            _NotesField(controller: _notesController),

            const _ErrorBanner(),
            SizedBox(height: 28.h),
            _SaveButton(
              isEdit: _isEdit,
              onTap: _handleSave,
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final pageState = ref.read(addReadingProvider);
    final selected = pageState.selectedDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.accent,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: AppColors.text,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(addReadingProvider.notifier).setDate(picked);
    }
  }

  Future<void> _handleSave() async {
    final notifier = ref.read(addReadingProvider.notifier);
    final success = _isEdit
        ? await notifier.updateReading(widget.reading!)
        : await notifier.saveReading();

    if (success && mounted) {
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
                _isEdit ? 'Reading updated' : 'Reading saved successfully',
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

      if (context.mounted) {
        await Future.wait([
          ref.read(usageProvider.notifier).refresh(),
          ref.read(dashboardProvider.notifier).refresh(),
        ]);
        
        if (mounted) {
          context.pop();
        }
      }
    }
  }
}

final _cardDecoration = BoxDecoration(
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D2D24), Color(0xFF0A1E2E)],
  ),
  borderRadius: BorderRadius.all(
    Radius.circular(AppDimensions.radiusLg),
  ),
  border: const Border.fromBorderSide(
    BorderSide(color: AppColors.borderAccent),
  ),
);

class _LastReadingCard extends ConsumerWidget {
  const _LastReadingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      addReadingProvider.select((s) => s.isLoadingLastReading),
    );

    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: _cardDecoration,
        child: Center(
          child: SizedBox(
            height: 60.h,
            child: const CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: _cardDecoration,
      child: const _LastReadingCardContent(),
    );
  }
}

class _LastReadingCardContent extends ConsumerWidget {
  const _LastReadingCardContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(
      addReadingProvider.select(
        (s) => (
          lastReading: s.lastReading,
          lastReadingDate: s.formattedLastReadingDate,
          nextReading: s.nextReading,
          nextReadingDate: s.formattedNextReadingDate,
        ),
      ),
    );

    return Column(
      children: [
        Text(
          'PREVIOUS READING',
          style: AppTextStyles.overline.copyWith(letterSpacing: 2),
        ),
        SizedBox(height: 8.h),
        Text(
          data.lastReading > 0
              ? data.lastReading.toStringAsFixed(0).padLeft(5, '0')
              : '00000',
          style: AppTextStyles.meterXl,
        ),
        SizedBox(height: 4.h),
        Text(
          data.lastReading > 0
              ? 'kWh · Last read: ${data.lastReadingDate}'
              : 'kWh · No previous reading',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.text2),
        ),
        if (data.nextReading != null) ...[
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.warn.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.warn.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 12.r,
                  color: AppColors.warn,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Must be below ${data.nextReading!.toStringAsFixed(0)} '
                  'kWh (${data.nextReadingDate})',
                  style: AppTextStyles.caption.copyWith(color: AppColors.warn),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DatePickerField extends ConsumerWidget {
  const _DatePickerField({
    required this.isEdit,
    required this.onPick,
  });

  final bool isEdit;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(
      addReadingProvider.select((s) => s.selectedDate),
    );

    return GestureDetector(
      onTap: isEdit ? null : onPick,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isEdit
              ? AppColors.surface3.withValues(alpha: 0.5)
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18.r,
              color: isEdit ? AppColors.text3 : AppColors.text2,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                DateFormat(
                  'MMMM d, yyyy',
                ).format(selectedDate ?? DateTime.now()),
                style: AppTextStyles.bodyLg.copyWith(
                  color: isEdit ? AppColors.text3 : AppColors.text,
                ),
              ),
            ),
            if (!isEdit)
              Icon(
                Icons.chevron_right_rounded,
                size: 18.r,
                color: AppColors.text3,
              ),
          ],
        ),
      ),
    );
  }
}

class _MeterReadingField extends ConsumerWidget {
  const _MeterReadingField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorText = ref.watch(
      addReadingProvider.select((s) => s.readingError),
    );
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: hasError ? AppColors.danger : AppColors.borderAccent,
              width: hasError ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: AppTextStyles.meterXl.copyWith(
              fontSize: 36.sp,
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '00000',
              hintStyle: AppTextStyles.meterXl.copyWith(
                fontSize: 36.sp,
                letterSpacing: 4,
                color: AppColors.text3,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8.h),
              suffixText: 'kWh',
              suffixStyle: AppTextStyles.bodyMd.copyWith(
                color: AppColors.text2,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 12.r,
                color: AppColors.danger,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  errorText,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.danger,
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

class _TariffTypeNote extends StatelessWidget {
  const _TariffTypeNote({
    required this.tariffType,
    required this.isEdit,
  });

  final TariffType tariffType;
  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.receipt_long_rounded, size: 13.r, color: AppColors.text3),
        SizedBox(width: 6.w),
        Text(
          isEdit
              ? 'Billed under ${tariffType.label}'
              : 'Calculating under ${tariffType.label} rates',
          style: AppTextStyles.caption.copyWith(color: AppColors.text3),
        ),
      ],
    );
  }
}

class _AutoCalcCard extends ConsumerWidget {
  const _AutoCalcCard({
    required this.tariffType,
  });

  final TariffType tariffType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUsage = ref.watch(addReadingProvider.select((s) => s.hasUsage));
    if (!hasUsage) return const SizedBox.shrink();

    final usageKwh = ref.watch(
      addReadingProvider.select((s) => s.usageKwh),
    );
    final estimatedBill = TariffRates.calculate(usageKwh, tariffType);
    final eeiBand = TariffRates.getEeiBand(usageKwh);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.borderAccent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚡ Auto Calculated',
                style: AppTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
              SizedBox(height: 10.h),
              _CalcRow(
                label: 'Usage since last reading',
                value: '${usageKwh.toStringAsFixed(0)} kWh',
                valueColor: AppColors.text,
              ),
              SizedBox(height: 8.h),
              _CalcRow(
                label: 'Estimated bill',
                value: 'RM ${estimatedBill.toStringAsFixed(2)}',
                valueColor: AppColors.accent,
              ),
              SizedBox(height: 10.h),
              const Divider(color: AppColors.border, height: 1),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tariffType == TariffType.domestic
                        ? 'EEI band'
                        : 'EEI rebate',
                    style: AppTextStyles.caption,
                  ),
                  _BandBadge(
                    tariffType: tariffType,
                    usageKwh: usageKwh,
                  ),
                ],
              ),
              if (tariffType == TariffType.domestic && usageKwh > 0) ...[
                SizedBox(height: 6.h),
                Text(
                  eeiBand.description,
                  style: AppTextStyles.caption.copyWith(color: AppColors.text3),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
}

class _BandBadge extends StatelessWidget {
  const _BandBadge({
    required this.tariffType,
    required this.usageKwh,
  });

  final TariffType tariffType;
  final double usageKwh;

  @override
  Widget build(BuildContext context) {
    if (tariffType == TariffType.domestic) {
      final band = TariffRates.getEeiBand(usageKwh);
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: band.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          band.label,
          style: AppTextStyles.tag.copyWith(color: band.color),
        ),
      );
    }

    final tier = TariffRates.getTier(usageKwh, TariffType.commercial);
    final color = TariffRates.getTierColor(tier, TariffType.commercial);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        TariffRates.tierBadgeLabel(tier, TariffType.commercial),
        style: AppTextStyles.tag.copyWith(color: color),
      ),
    );
  }
}

class _CalcRow extends StatelessWidget {
  const _CalcRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.text2),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMd.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      style: AppTextStyles.bodyMd,
      decoration: InputDecoration(
        hintText: 'e.g. Raya holiday, high AC usage...',
        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.text3),
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: EdgeInsets.all(14.r),
      ),
    );
  }
}

class _ErrorBanner extends ConsumerWidget {
  const _ErrorBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(
      addReadingProvider.select((s) => s.errorMessage),
    );

    if (message == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 16.r,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends ConsumerWidget {
  const _SaveButton({required this.isEdit, required this.onTap});

  final bool isEdit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaving = ref.watch(addReadingProvider.select((s) => s.isSaving));
    final canSave = ref.watch(addReadingProvider.select((s) => s.canSave));

    return GradientButton(
      label: isEdit ? 'Save Changes' : 'Save Reading',
      isLoading: isSaving,
      isEnabled: canSave,
      onTap: onTap,
    );
  }
}
