import 'package:energy_tracker/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PaidBadge extends StatelessWidget {
  const PaidBadge({
    required this.isPaid,
    super.key,
  });
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    final color = isPaid ? AppColors.accent : AppColors.warn;
    final bg = isPaid
        ? AppColors.accent.withValues(alpha: 0.12)
        : AppColors.warn.withValues(alpha: 0.12);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        isPaid ? 'Paid' : 'Pending',
        style: AppTextStyles.tag.copyWith(
          fontSize: 10.sp,
          color: color,
        ),
      ),
    );
  }
}
