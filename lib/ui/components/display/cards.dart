import 'package:energy_tracker/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BillBreakdownCard extends StatefulWidget {
  const BillBreakdownCard({
    required this.items,
    required this.emptyLabel,
    this.title = 'Bill Breakdown',
    this.subtitle,
    this.collapsible = true,
    this.initiallyExpanded = false,
    this.padding,
    super.key,
  });

  final List<ChargeLineItem> items;
  final String emptyLabel;
  final String title;
  final String? subtitle;
  final bool collapsible;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry? padding;

  @override
  State<BillBreakdownCard> createState() => _BillBreakdownCardState();
}

class _BillBreakdownCardState extends State<BillBreakdownCard> {
  static const _animationDuration = Duration(milliseconds: 220);
  static const Cubic _animationCurve = Curves.easeOutCubic;

  late bool _expanded = widget.initiallyExpanded || !widget.collapsible;

  void _toggle() {
    if (!widget.collapsible) return;
    setState(() => _expanded = !_expanded);
  }

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
        side: BorderSide(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: widget.collapsible,
            expanded: widget.collapsible ? _expanded : null,
            child: InkWell(
              onTap: widget.collapsible ? _toggle : null,
              child: Padding(
                padding: padding,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: AppTextStyles.bodyMd.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            SizedBox(height: 2.h),
                            Text(
                              widget.subtitle!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.text3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.collapsible) ...[
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
                  ],
                ),
              ),
            ),
          ),
          if (!widget.collapsible)
            _buildContent(padding)
          else
            AnimatedSize(
              duration: duration,
              curve: _animationCurve,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? _buildContent(padding)
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(EdgeInsets padding) {
    return Padding(
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
                  'AFA uses the rate published by TNB. The next-month '
                  'forecast is shown for reference and is not included in '
                  'this total.',
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
    );
  }
}
