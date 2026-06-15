import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/components/buttons.dart';
import 'package:energy_tracker/ui/components/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BudgetSheet extends StatefulWidget {
  const BudgetSheet({
    required this.current,
    required this.onSave,
    super.key,
  });

  final double current;
  final ValueChanged<double> onSave;

  @override
  State<BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<BudgetSheet> {
  late double _budget;

  static const _presets = [50.0, 100.0, 150.0, 200.0, 250.0, 300.0];

  @override
  void initState() {
    super.initState();
    _budget = widget.current.clamp(50.0, 500.0);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusLg),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppDimensions.screenPaddingH,
          20.h,
          AppDimensions.screenPaddingH,
          32.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.text3,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text('Monthly Budget', style: AppTextStyles.titleMd),
            SizedBox(height: 6.h),
            Text(
              "We'll alert you before you overspend",
              style: AppTextStyles.bodySm,
            ),
            SizedBox(height: 24.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.1),
                    AppColors.accent2.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border:
                    Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    'Monthly Budget (RM)',
                    style: AppTextStyles.caption.copyWith(letterSpacing: 1),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'RM ${_budget.toStringAsFixed(0)}',
                    style: AppTextStyles.displayLg
                        .copyWith(color: AppColors.accent),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '≈ ${(_budget / 0.3).toStringAsFixed(0)}–'
                    '${(_budget / 0.25).toStringAsFixed(0)} kWh estimated',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.accent,
                inactiveTrackColor: AppColors.surface3,
                thumbColor: Colors.white,
                overlayColor: AppColors.accent.withValues(alpha: 0.1),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                trackHeight: 4,
              ),
              child: Slider(
                value: _budget,
                min: 50,
                max: 500,
                divisions: 90,
                onChanged: (v) => setState(() => _budget = v),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('RM 50', style: AppTextStyles.caption),
                Text('RM 500', style: AppTextStyles.caption),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              'Quick Select',
              style:
                  AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              children: _presets.map((preset) {
                final isSelected = _budget == preset;
                return FilterChip(
                  label: Text('RM ${preset.toInt()}'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _budget = preset),
                  selectedColor: AppColors.accent.withValues(alpha: 0.12),
                  checkmarkColor: AppColors.accent,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),
                  labelStyle: AppTextStyles.caption.copyWith(
                    color: isSelected ? AppColors.accent : AppColors.text2,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  backgroundColor: AppColors.surface2,
                  showCheckmark: false,
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                );
              }).toList(),
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.warn.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border:
                    Border.all(color: AppColors.warn.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 14.r,
                    color: AppColors.warn,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Average Malaysian household spends '
                      'RM 120–180/month on electricity',
                      style:
                          AppTextStyles.caption.copyWith(color: AppColors.warn),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            GradientButton(
              label: 'Save Budget',
              isLoading: false,
              onTap: () async {
                final confirmed = await ConfirmDialog.show(
                  context,
                  title: 'Update Budget?',
                  message:
                      'Set monthly budget to RM ${_budget.toStringAsFixed(0)}?',
                  confirmLabel: 'Save',
                );

                if (confirmed && context.mounted) widget.onSave(_budget);
              },
            ),
          ],
        ),
      ),
    );
  }
}
