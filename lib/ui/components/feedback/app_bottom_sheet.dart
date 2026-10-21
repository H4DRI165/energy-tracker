import 'package:energy_tracker/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useRootNavigator = true,
  Color? barrierColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 340),
      reverseDuration: Duration(milliseconds: 220),
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInCubic,
    ),
    builder: builder,
  );
}

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    required this.child,
    this.header,
    this.padding,
    this.maxHeightFactor = 0.9,
    this.showHandle = true,
    super.key,
  });

  final Widget child;
  final Widget? header;
  final EdgeInsetsGeometry? padding;
  final double maxHeightFactor;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final contentPadding =
        padding ?? EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: media.size.height * maxHeightFactor,
        ),
        child: Material(
          color: AppColors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24.r),
            ),
            side: BorderSide(color: AppColors.border),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showHandle)
                  Padding(
                    padding: EdgeInsets.only(top: 10.h, bottom: 4.h),
                    child: Center(
                      child: Container(
                        width: 36.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: AppColors.text3.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                  ),
                if (header != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
                    child: header,
                  ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: contentPadding,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
