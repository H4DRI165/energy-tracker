import 'package:energy_tracker/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BillBreakdownCard extends StatefulWidget {
  const BillBreakdownCard({
    required this.items,
    required this.emptyLabel,
    this.padding,
    super.key,
  });

  final List<ChargeLineItem> items;
  final String emptyLabel;
  final EdgeInsetsGeometry? padding;

  @override
  State<BillBreakdownCard> createState() => _BillBreakdownCardState();
}

class _BillBreakdownCardState extends State<BillBreakdownCard> {
  static const _animationDuration = Duration(milliseconds: 220);
  static const Cubic _animationCurve = Curves.easeOutCubic;

  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final padding =
        (widget.padding ?? EdgeInsets.all(AppDimensions.cardPaddingSm)).resolve(
          Directionality.of(context),
        );
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final duration = disableAnimations ? Duration.zero : _animationDuration;

    return Material(
      color: AppColors.surface2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            child: InkWell(
              onTap: _toggle,
              child: Padding(
                padding: padding,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Bill Breakdown',
                        style: AppTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: AppDimensions.s8),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: duration,
                      curve: _animationCurve,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18.r,
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: duration,
            curve: _animationCurve,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: EdgeInsets.only(
                      left: padding.left,
                      right: padding.right,
                      bottom: padding.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.items.isEmpty)
                          Text(
                            widget.emptyLabel,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.text2,
                            ),
                          )
                        else
                          ...widget.items.map(
                            (item) => ChargeLineItemRow(item: item),
                          ),
                        Divider(height: 16.h, color: AppColors.border),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 11.r,
                              color: AppColors.text3,
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                'AFA uses the rate published by TNB for '
                                'this billing month.',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.text3,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
