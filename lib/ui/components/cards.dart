import 'package:energy_tracker/theme/app_colors.dart';
import 'package:energy_tracker/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.readonly = true,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final bool? readonly;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: readonly == false ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: readonly == false && isSelected
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.surface2,
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLg
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.text2,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (readonly == false && isSelected)
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.black,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class AppCardWithIcon extends StatelessWidget {
  const AppCardWithIcon({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.readonly = true,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool? readonly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        border: Border.all(
          color:  AppColors.border,
          width: 1,        
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.done_outline_sharp,
            size: 30,
            color: AppColors.accent,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLg
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.text2,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
