import 'dart:async';

import 'package:energy_tracker/app.dart';
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
          IconButton(
            onPressed: () => context.pop(),
            tooltip: 'Back',
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16.r,
            ),
            style: IconButton.styleFrom(
              minimumSize: Size(44.r, 44.r),
              maximumSize: Size(44.r, 44.r),
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.surface2,
              foregroundColor: AppColors.text2,
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
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

  @override
  Widget build(BuildContext context) {
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
            if (_isEdit) ...[
              SizedBox(height: 6.h),
              Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 12.r,
                    color: AppColors.text3,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      'Date is fixed while editing. Delete and re-add to '
                      'change it.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.text3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 16.h),
            Row(
              children: [
                Text('Meter Reading (kWh)', style: AppTextStyles.label),
                const Spacer(),
                Text(
                  'Full reading, not usage',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.text3,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            _MeterReadingField(
              controller: _readingController,
            ),
            SizedBox(height: 10.h),
            _AutoCalcCard(isEdit: _isEdit),
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
              onPrimary: AppColors.onAccent,
              surface: AppColors.surface,
              onSurface: AppColors.text,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: AppColors.surface,
              shape: const RoundedRectangleBorder(
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
    FocusScope.of(context).unfocus();
    final readingState = ref.read(addReadingProvider);

    if (_isEdit) {
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'Save Changes?',
        message: 'Update this meter reading?',
        confirmLabel: 'Save Changes',
        warning:
            "The kWh used, this month's bill and the next reading's usage "
            'will be recalculated.',
      );

      if (!confirmed || !mounted) return;
    } else if (readingState.isLongGap) {
      final days = readingState.intervalDays ?? 0;
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'Long gap between readings',
        message:
            'This reading covers $days days. Usage will be split across '
            'the months it covers.',
        confirmLabel: 'Split & Save',
        warning:
            'Months without a reading will be marked as estimated. '
            'Add the missing monthly readings later for an exact bill.',
      );

      if (!confirmed || !mounted) return;
    }

    final notifier = ref.read(addReadingProvider.notifier);
    final isFirstReading = !_isEdit && readingState.lastReadingDate == null;
    final success = _isEdit
        ? await notifier.updateReading(widget.reading!)
        : await notifier.saveReading();

    if (success && mounted) {
      final successMessage = _isEdit
          ? 'Reading updated'
          : isFirstReading
          ? 'Baseline saved — add your next reading to see usage'
          : 'Reading saved successfully';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.accent,
                size: 18,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  successMessage,
                  style: AppTextStyles.bodyMd,
                ),
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

      final refresh = Future.wait([
        ref.read(usageProvider.notifier).refresh(),
        ref.read(dashboardProvider.notifier).refresh(),
      ]);

      if (mounted) context.pop();

      unawaited(
        refresh.then<void>(
          (_) {},
          onError: (Object _, StackTrace _) {},
        ),
      );
    }
  }
}

final _cardDecoration = BoxDecoration(
  gradient: AppColors.heroGradient,
  borderRadius: BorderRadius.all(
    Radius.circular(AppDimensions.radiusLg),
  ),
  border: Border.fromBorderSide(
    BorderSide(color: AppColors.borderAccent),
  ),
);

class _LastReadingCard extends ConsumerWidget {
  const _LastReadingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(
      addReadingProvider.select(
        (s) => (
          isLoading: s.isLoadingLastReading,
          loadError: s.loadError,
        ),
      ),
    );

    if (data.isLoading) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: _cardDecoration,
        child: Center(
          child: SizedBox(
            height: 60.h,
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (data.loadError != null) {
      return _ReadingLoadErrorCard(message: data.loadError!);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: _cardDecoration,
      child: const _LastReadingCardContent(),
    );
  }
}

class _ReadingLoadErrorCard extends ConsumerWidget {
  const _ReadingLoadErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 22.r,
            color: AppColors.danger,
          ),
          SizedBox(height: 8.h),
          Text(
            'Could not check your readings',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.text3,
              height: 1.4,
            ),
          ),
          SizedBox(height: 6.h),
          TextButton.icon(
            onPressed: () => ref
                .read(addReadingProvider.notifier)
                .retryLoadingSurroundingReadings(),
            icon: Icon(Icons.refresh_rounded, size: 16.r),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
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
                Flexible(
                  child: Text(
                    'Must be below ${data.nextReading!.toStringAsFixed(0)} '
                    'kWh (${data.nextReadingDate})',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.warn,
                    ),
                  ),
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

class _AutoCalcCard extends ConsumerWidget {
  const _AutoCalcCard({required this.isEdit});

  final bool isEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(
      addReadingProvider.select(
        (s) => (
          hasUsage: s.hasUsage,
          lastReadingDate: s.lastReadingDate,
          isLoading: s.isLoadingLastReading,
          loadError: s.loadError,
          isSameAsLastReading: s.isSameAsLastReading,
        ),
      ),
    );

    if (data.isLoading || data.loadError != null) {
      return const SizedBox.shrink();
    }

    if (!data.hasUsage) {
      if (!isEdit && data.lastReadingDate == null) {
        return const _BaselineHintCard();
      }
      if (data.isSameAsLastReading) {
        return const _NoUsageHintCard();
      }
      return const SizedBox.shrink();
    }

    final usageKwh = ref.watch(addReadingProvider.select((s) => s.usageKwh));
    final cumulativeKwh = ref.watch(
      addReadingProvider.select((s) => s.cumulativeKwh),
    );
    final incrementalCost = ref.watch(
      addReadingProvider.select((s) => s.incrementalCost()),
    );
    final eeiBand = TariffRates.getEeiBand(cumulativeKwh);

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
              Row(
                children: [
                  Icon(
                    Icons.calculate_outlined,
                    size: 15.r,
                    color: AppColors.accent,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Estimated impact',
                    style: AppTextStyles.bodySm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              _CalcRow(
                label: 'Usage since last reading',
                value: '${usageKwh.toStringAsFixed(0)} kWh',
                valueColor: AppColors.text,
              ),
              SizedBox(height: 8.h),
              _CalcRow(
                label: 'Month-to-date usage',
                value: '${cumulativeKwh.toStringAsFixed(0)} kWh',
                valueColor: AppColors.text,
              ),
              SizedBox(height: 8.h),
              _CalcRow(
                label: 'Estimated cost added',
                value: '~RM ${incrementalCost.toStringAsFixed(2)}',
                valueColor: AppColors.text,
                onInfoTap: () => _showEstimatedCostInfo(context),
              ),
              SizedBox(height: 10.h),
              Divider(color: AppColors.border, height: 1),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('EEI band', style: AppTextStyles.caption),
                  _BandBadge(cumulativeKwh: cumulativeKwh),
                ],
              ),
              if (cumulativeKwh > 0) ...[
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

void _showEstimatedCostInfo(BuildContext context) {
  unawaited(
    showAppBottomSheet<void>(
      context: context,
      builder: (_) => AppBottomSheet(
        header: Text(
          'Estimated cost added',
          style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w700),
        ),
        child: Text(
          'This is the estimated change to this month’s TNB bill after adding '
          'this reading. It includes the domestic tariff, EEI rebate and '
          'applicable taxes.\n\nIt is not a separate charge, and your actual '
          'TNB bill may differ.',
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.text2,
            height: 1.5,
          ),
        ),
      ),
    ),
  );
}

class _NoUsageHintCard extends StatelessWidget {
  const _NoUsageHintCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18.r,
                color: AppColors.text3,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No usage since the last reading',
                      style: AppTextStyles.bodySm.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Check the number if your meter should have moved.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.text3,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
      ],
    );
  }
}

class _BaselineHintCard extends StatelessWidget {
  const _BaselineHintCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.borderAccent),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.flag_outlined,
                size: 18.r,
                color: AppColors.accent,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This is your starting point',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Your first reading will be saved as the baseline. Add a '
                      'second reading later to calculate usage and your '
                      'estimated bill.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.text2,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 10.h,
        ),
      ],
    );
  }
}

class _BandBadge extends StatelessWidget {
  const _BandBadge({required this.cumulativeKwh});

  final double cumulativeKwh;

  @override
  Widget build(BuildContext context) {
    final band = TariffRates.getEeiBand(cumulativeKwh);
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
}

class _CalcRow extends StatelessWidget {
  const _CalcRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.onInfoTap,
  });

  final String label;
  final String value;
  final Color valueColor;
  final VoidCallback? onInfoTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.text2,
                  ),
                ),
              ),
              if (onInfoTap != null) ...[
                SizedBox(width: 4.w),
                SizedBox(
                  width: 24.r,
                  height: 24.r,
                  child: IconButton(
                    onPressed: onInfoTap,
                    tooltip: 'About estimated cost',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(
                      width: 24.r,
                      height: 24.r,
                    ),
                    iconSize: 14.r,
                    color: AppColors.text3,
                    icon: const Icon(Icons.info_outline_rounded),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: 12.w),
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
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
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
    final isLoadingLastReading = ref.watch(
      addReadingProvider.select((s) => s.isLoadingLastReading),
    );
    final readingError = ref.watch(
      addReadingProvider.select((s) => s.readingError),
    );
    final loadError = ref.watch(
      addReadingProvider.select((s) => s.loadError),
    );
    final hasReading = ref.watch(
      addReadingProvider.select((s) => s.currentReading > 0),
    );

    final String? disabledReason;
    if (isLoadingLastReading) {
      disabledReason = 'Checking your previous reading…';
    } else if (loadError != null) {
      disabledReason = 'Retry the reading lookup above to save';
    } else if (readingError == null && !hasReading) {
      disabledReason = 'Enter a reading above 0 to save';
    } else {
      disabledReason = null;
    }

    return Column(
      children: [
        GradientButton(
          label: isEdit ? 'Save Changes' : 'Save Reading',
          isLoading: isSaving,
          isEnabled: canSave,
          onTap: onTap,
        ),
        if (!isSaving && disabledReason != null) ...[
          SizedBox(height: 8.h),
          Text(
            disabledReason,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: AppColors.text2),
          ),
        ],
      ],
    );
  }
}
