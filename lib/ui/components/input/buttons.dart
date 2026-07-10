import 'package:energy_tracker/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
    this.isEnabled = true,
    super.key,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (isEnabled && !isLoading) ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52.h,
        decoration: BoxDecoration(
          gradient: isEnabled ? AppColors.primaryGradient : null,
          color: isEnabled ? null : AppColors.surface2,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          boxShadow: isEnabled ? AppColors.btnPrimaryShadow : null,
          border: isEnabled ? null : Border.all(color: AppColors.border),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20.r,
                  height: 20.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isEnabled ? Colors.black : AppColors.text3,
                  ),
                )
              : Text(
                  label,
                  style: AppTextStyles.button.copyWith(
                    color: isEnabled ? Colors.black : AppColors.text3,
                  ),
                ),
        ),
      ),
    );
  }
}
