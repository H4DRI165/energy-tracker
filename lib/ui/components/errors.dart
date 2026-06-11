import 'package:energy_tracker/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    required this.onRetry,
    this.message = 'Failed to load data',
    super.key,
  });

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⚠️', style: TextStyle(fontSize: 40.sp)),
          SizedBox(height: 12.h),
          Text(
            message,
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
