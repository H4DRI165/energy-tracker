import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/components/display/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsSkeleton extends StatelessWidget {
  const SettingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cardRadius = BorderRadius.circular(AppDimensions.radiusLg);

    return Skeleton(
      semanticsLabel: 'Loading settings',
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppDimensions.screenPaddingH,
          4.h,
          AppDimensions.screenPaddingH,
          32.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 84.h, borderRadius: cardRadius),
            SizedBox(height: 20.h),
            SkeletonLine(width: 88.w, height: 9.h),
            SizedBox(height: 8.h),
            SkeletonBox(height: 168.h, borderRadius: cardRadius),
            SizedBox(height: 20.h),
            SkeletonLine(width: 58.w, height: 9.h),
            SizedBox(height: 8.h),
            SkeletonBox(height: 56.h, borderRadius: cardRadius),
            SizedBox(height: 20.h),
            SkeletonLine(width: 62.w, height: 9.h),
            SizedBox(height: 8.h),
            SkeletonBox(height: 56.h, borderRadius: cardRadius),
            SizedBox(height: 24.h),
            SkeletonBox(height: 52.h, borderRadius: cardRadius),
          ],
        ),
      ),
    );
  }
}
