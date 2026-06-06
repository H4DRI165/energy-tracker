import 'package:energy_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.middleText,
  });

  final String? middleText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.text3,
                ),
              ),
            ),
            child: SizedBox(height: 1),
          ),
        ),
        if (middleText != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              middleText!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.text2,
                height: 1.3,
              ),
            ),
          ),
          const Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.text3,
                  ),
                ),
              ),
              child: SizedBox(height: 1),
            ),
          ),
        ],
      ],
    );
  }
}
