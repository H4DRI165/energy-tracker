import 'package:energy_tracker/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    required this.onRetry,
    super.key,
  });
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⚠️', style: TextStyle(fontSize: 40.sp)),
          SizedBox(height: 12.h),
          Text(
            'Failed to load usage data',
            style: AppTextStyles.bodyMd,
          ),
          SizedBox(height: 8.h),
          Text(
            'Check your connection and try again',
            style: AppTextStyles.bodySm,
          ),
          SizedBox(height: 20.h),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
