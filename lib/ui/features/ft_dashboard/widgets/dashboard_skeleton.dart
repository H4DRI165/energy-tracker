import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/components/display/content_width.dart';
import 'package:energy_tracker/ui/components/display/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cardRadius = BorderRadius.circular(AppDimensions.radiusLg);

    return Skeleton(
      semanticsLabel: 'Loading dashboard',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppContentWidth.horizontalPadding(context),
          20.h,
          AppContentWidth.horizontalPadding(context),
          24.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkeletonBox(height: 140.h, borderRadius: cardRadius),
            SizedBox(height: 14.h),
            SkeletonBox(height: 86.h, borderRadius: cardRadius),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: SkeletonBox(height: 82.h, borderRadius: cardRadius),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: SkeletonBox(height: 82.h, borderRadius: cardRadius),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            SkeletonBox(height: 190.h, borderRadius: cardRadius),
          ],
        ),
      ),
    );
  }
}
