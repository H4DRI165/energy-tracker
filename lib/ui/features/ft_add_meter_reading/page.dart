import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/features/ft_add_meter_reading/notifier/add_meter_reading_notifier.dart';
import 'package:energy_tracker/ui/features/ft_add_meter_reading/notifier/add_meter_reading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AddReadingPage extends ConsumerStatefulWidget {
  const AddReadingPage({super.key});

  @override
  ConsumerState<AddReadingPage> createState() => _AddReadingPageState();
}

class _AddReadingPageState extends ConsumerState<AddReadingPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addReadingProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              canSave: state.canSave,
              isSaving: state.isSaving,
            ),
            _BodyContent(state: state),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.canSave,
    required this.isSaving,
  });

  final bool canSave;
  final bool isSaving;

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
            child: Text('Add Meter Reading', style: AppTextStyles.titleMd),
          ),
        ],
      ),
    );
  }
}

class _BodyContent extends ConsumerStatefulWidget {
  const _BodyContent({
    required this.state,
  });

  final AddReadingPageState state;

  @override
  ConsumerState<_BodyContent> createState() => _BodyContentState();
}

class _BodyContentState extends ConsumerState<_BodyContent> {
  late final TextEditingController _readingController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _readingController = TextEditingController();
    _notesController = TextEditingController();

    _readingController.addListener(
      () => ref.read(addReadingProvider.notifier).setReading(
            _readingController.text,
          ),
    );
    _notesController.addListener(
      () => ref.read(addReadingProvider.notifier).setNotes(
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

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPaddingH,
          vertical: 8.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LastReadingCard(state: widget.state),
            SizedBox(height: 20.h),
            Text('Reading Date', style: AppTextStyles.label),
            SizedBox(height: 6.h),
            _DatePickerField(
              selectedDate: widget.state.selectedDate ?? DateTime.now(),
              onTap: () => _pickDate(context),
            ),
            SizedBox(height: 16.h),
            Text('Meter Reading (kWh)', style: AppTextStyles.label),
            SizedBox(height: 6.h),
            _MeterReadingField(
              controller: _readingController,
              errorText: widget.state.readingError,
            ),
            SizedBox(height: 16.h),
            if (widget.state.hasUsage) ...[
              _AutoCalcCard(state: widget.state),
              SizedBox(height: 16.h),
            ],
            Text('Notes (optional)', style: AppTextStyles.label),
            SizedBox(height: 6.h),
            _NotesField(controller: _notesController),
            if (widget.state.errorMessage != null) ...[
              SizedBox(height: 16.h),
              _ErrorBanner(message: widget.state.errorMessage!),
            ],
            SizedBox(height: 28.h),
            _SaveButton(
              canSave: widget.state.canSave,
              isSaving: widget.state.isSaving,
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
    final minDate =
        pageState.lastReadingDate ?? DateTime(now.year - 1, now.month, now.day);
    final selected = pageState.selectedDate ?? now;
    final initialDate = selected.isBefore(minDate) ? minDate : selected;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
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
    final success = await ref.read(addReadingProvider.notifier).saveReading();
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
              Text('Reading saved successfully', style: AppTextStyles.bodyMd),
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

class _LastReadingCard extends StatelessWidget {
  const _LastReadingCard({required this.state});
  final AddReadingPageState state;

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
        border: Border.all(color: AppColors.borderAccent),
      ),
      child: state.isLoadingLastReading
          ? Center(
              child: SizedBox(
                height: 60.h,
                child: const CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 2,
                ),
              ),
            )
          : Column(
              children: [
                Text(
                  'PREVIOUS READING',
                  style: AppTextStyles.overline.copyWith(letterSpacing: 2),
                ),
                SizedBox(height: 8.h),
                Text(
                  state.lastReading > 0
                      ? state.lastReading.toStringAsFixed(0).padLeft(5, '0')
                      : '00000',
                  style: AppTextStyles.meterXl,
                ),
                SizedBox(height: 4.h),
                Text(
                  state.lastReading > 0
                      ? 'kWh · Last read: ${state.formattedLastReadingDate}'
                      : 'kWh · No previous reading',
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.text2),
                ),
              ],
            ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.selectedDate,
    required this.onTap,
  });

  final DateTime selectedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18.r,
              color: AppColors.text2,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                DateFormat('MMMM d, yyyy').format(selectedDate),
                style: AppTextStyles.bodyLg,
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
    );
  }
}

class _MeterReadingField extends StatelessWidget {
  const _MeterReadingField({
    required this.controller,
    this.errorText,
  });

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
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
            autofocus: true,
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
                  errorText!,
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

class _AutoCalcCard extends StatelessWidget {
  const _AutoCalcCard({required this.state});
  final AddReadingPageState state;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            label: 'Usage this month',
            value: '${state.usageKwh.toStringAsFixed(0)} kWh',
            valueColor: AppColors.text,
          ),
          SizedBox(height: 8.h),
          _CalcRow(
            label: 'Estimated bill',
            value: 'RM ${state.estimatedBill.toStringAsFixed(2)}',
            valueColor: AppColors.accent,
          ),
          SizedBox(height: 10.h),
          const Divider(color: AppColors.border, height: 1),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current tier',
                style: AppTextStyles.caption,
              ),
              _TierBadge(tierLabel: state.tierLabel, tier: state.currentTier),
            ],
          ),
        ],
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

class _TierBadge extends StatelessWidget {
  const _TierBadge({
    required this.tierLabel,
    required this.tier,
  });

  final String tierLabel;
  final int tier;

  Color get _color {
    switch (tier) {
      case 1:
        return AppColors.accent;
      case 2:
        return AppColors.warn;
      default:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        tierLabel,
        style: AppTextStyles.tag.copyWith(color: _color),
      ),
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

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.canSave,
    required this.isSaving,
    required this.onTap,
  });

  final bool canSave;
  final bool isSaving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (canSave && !isSaving) ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52.h,
        decoration: BoxDecoration(
          gradient: canSave ? AppColors.primaryGradient : null,
          color: canSave ? null : AppColors.surface2,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          boxShadow: canSave ? AppColors.btnPrimaryShadow : null,
          border: canSave ? null : Border.all(color: AppColors.border),
        ),
        child: Center(
          child: isSaving
              ? SizedBox(
                  width: 20.r,
                  height: 20.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: canSave ? Colors.black : AppColors.text3,
                  ),
                )
              : Text(
                  'Save Reading',
                  style: AppTextStyles.button.copyWith(
                    color: canSave ? Colors.black : AppColors.text3,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
