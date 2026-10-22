import 'package:energy_tracker/theme/theme.dart';
import 'package:energy_tracker/ui/components/display/content_width.dart';
import 'package:energy_tracker/ui/components/display/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UsageSkeleton extends StatelessWidget {
  const UsageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cardRadius = BorderRadius.circular(AppDimensions.radiusLg);

    return Skeleton(
      semanticsLabel: 'Loading usage',
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppContentWidth.horizontalPadding(context),
          20.h,
          AppContentWidth.horizontalPadding(context),
          24.h,
        ),
        children: [
          Row(
            children: [
              SkeletonLine(width: 96.w, height: 9.h),
              const Spacer(),
              SkeletonLine(width: 64.w, height: 9.h),
            ],
          ),
          SizedBox(height: 9.h),
          Row(
            children: [
              Expanded(
                child: SkeletonBox(height: 96.h, borderRadius: cardRadius),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: SkeletonBox(height: 96.h, borderRadius: cardRadius),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          SkeletonLine(width: 210.w, height: 9.h),
          SizedBox(height: 14.h),
          SkeletonBox(height: 280.h, borderRadius: cardRadius),
          SizedBox(height: 14.h),
          SkeletonBox(height: 190.h, borderRadius: cardRadius),
          SizedBox(height: 14.h),
          for (var i = 0; i < 3; i++) ...[
            SkeletonBox(height: 64.h, borderRadius: cardRadius),
            SizedBox(height: 10.h),
          ],
        ],
      ),
    );
  }
}
