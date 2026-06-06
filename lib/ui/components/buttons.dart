import 'package:energy_tracker/theme/app_colors.dart';
import 'package:energy_tracker/theme/app_dimensions.dart';
import 'package:energy_tracker/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          boxShadow: AppColors.btnPrimaryShadow,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : Text(
                  label,
                  style: AppTextStyles.button,
                ),
        ),
      ),
    );
  }
}
