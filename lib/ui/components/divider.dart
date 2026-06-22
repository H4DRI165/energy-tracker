import 'package:energy_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Text(
              middleText!,
              style: TextStyle(
                fontSize: 12.sp,
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
