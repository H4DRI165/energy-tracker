import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/components/display/content_width.dart';
import 'package:energy_tracker/ui/components/display/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DevicesSkeleton extends StatelessWidget {
  const DevicesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cardRadius = BorderRadius.circular(AppDimensions.radiusLg);

    return Skeleton(
      semanticsLabel: 'Loading appliances',
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppContentWidth.horizontalPadding(context),
          20.h,
          AppContentWidth.horizontalPadding(context),
          24.h,
        ),
        children: [
          SkeletonBox(height: 118.h, borderRadius: cardRadius),
          SizedBox(height: 12.h),
          SkeletonBox(height: 62.h, borderRadius: cardRadius),
          SizedBox(height: 16.h),
          SkeletonBox(
            height: 48.h,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                SkeletonBox(
                  width: 68.w,
                  height: 30.h,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                if (i < 3) SizedBox(width: 8.w),
              ],
            ],
          ),
          SizedBox(height: 18.h),
          SkeletonLine(width: 120.w, height: 12.h),
          SizedBox(height: 10.h),
          for (var i = 0; i < 5; i++) ...[
            SkeletonBox(
              height: 64.h,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            SizedBox(height: 8.h),
          ],
        ],
      ),
    );
  }
}
