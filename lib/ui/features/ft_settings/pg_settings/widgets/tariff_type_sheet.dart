import 'package:energy_tracker/constants/tariff_types.dart';
import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/components/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TariffTypeSheet extends StatelessWidget {
  const TariffTypeSheet({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text('Select Tariff Type', style: AppTextStyles.titleMd),
          SizedBox(height: 6.h),
          Text(
            'Choose your TNB account category',
            style: AppTextStyles.bodySm,
          ),
          SizedBox(height: 20.h),
          ...TariffType.values.map((tariff) {
            final isSelected = selected == tariff.value;

            return Semantics(
              button: true,
              selected: isSelected,
              label: tariff.label,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isSelected
                      ? null
                      : () async {
                          final confirmed = await ConfirmDialog.show(
                            context,
                            title: 'Switch Tariff Type?',
                            message: 'Switch to ${tariff.label}?',
                            confirmLabel: 'Switch',
                            warning: 'This will affect how your bill is '
                                'calculated going forward.',
                          );

                          if (confirmed && context.mounted) {
                            onSelect(tariff.value);
                          }
                        },
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 10.h),
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withValues(alpha: 0.06)
                          : AppColors.surface2,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.3)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(tariff.icon, style: TextStyle(fontSize: 20.sp)),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tariff.label,
                                style: AppTextStyles.bodyMd.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                tariff.subtitle,
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 20.r,
                            height: 20.r,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 12.r,
                              color: Colors.black,
                            ),
                          )
                        else
                          Container(
                            width: 20.r,
                            height: 20.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
