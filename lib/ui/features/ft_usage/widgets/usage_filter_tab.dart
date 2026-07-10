import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/features/ft_usage/notifier/usage_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UsageFilterTabs extends StatelessWidget {
  const UsageFilterTabs({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final UsageFilter selected;
  final ValueChanged<UsageFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        children: UsageFilter.values.map((filter) {
          final isSelected = filter == selected;
          final label = filter == UsageFilter.monthly ? 'Monthly' : 'Yearly';
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(9.r),
                onTap: () => onChanged(filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySm.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.black : AppColors.text2,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
