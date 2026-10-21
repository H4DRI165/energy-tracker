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
      padding: EdgeInsets.all(2.r),
      decoration: BoxDecoration(
        color: AppColors.surface3,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        children: UsageFilter.values.map((filter) {
          final isSelected = filter == selected;
          final label = filter == UsageFilter.monthly ? '6M' : '12M';
          final semanticsLabel = filter == UsageFilter.monthly
              ? 'Last 6 months'
              : 'Last 12 months';
          return Expanded(
            child: Semantics(
              button: true,
              selected: isSelected,
              label: semanticsLabel,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(9.r),
                  onTap: () => onChanged(filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: 5.h),
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
                        color: isSelected
                            ? AppColors.onAccent
                            : AppColors.text2,
                      ),
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
