import 'dart:async';

import 'package:energy_tracker/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChargeLineItemRow extends StatelessWidget {
  const ChargeLineItemRow({
    required this.item,
    super.key,
  });

  final ChargeLineItem item;

  @override
  Widget build(BuildContext context) {
    final isRebate = item.isRebate;
    final isLevy = item.isLevy;

    final amountColor = isRebate
        ? AppColors.accent
        : isLevy
        ? AppColors.text2
        : AppColors.text;
    final info = _explanationFor(item.label);

    return Semantics(
      button: true,
      label: '${item.label}. Tap for an explanation.',
      child: InkWell(
        onTap: () => _showChargeInfo(context, item, info),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: AppTextStyles.bodySm.copyWith(
                        color: isLevy ? AppColors.text2 : AppColors.text,
                        fontWeight: isLevy ? FontWeight.w400 : FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      item.rateLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.text3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '${isRebate ? '−' : ''}RM '
                '${item.amount.abs().toStringAsFixed(2)}',
                style: AppTextStyles.bodySm.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.info_outline_rounded,
                size: 14.r,
                color: AppColors.text3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChargeExplanation {
  const _ChargeExplanation(this.title, this.description);

  final String title;
  final String description;
}

_ChargeExplanation _explanationFor(String label) {
  if (label.startsWith('Forecast Automatic Fuel Adjustment')) {
    return const _ChargeExplanation(
      'AFA (fuel adjustment)',
      'A monthly adjustment based on fuel prices. This month’s AFA is '
          'charged only above the protection threshold. The next month’s '
          'forecast is shown for reference and is not added to this month’s '
          'total.',
    );
  }

  switch (label) {
    case 'Energy':
      return const _ChargeExplanation(
        'Energy charge',
        'This is the cost of the electricity you used. Usage above '
            '1,500 kWh is charged at a higher energy rate.',
      );
    case 'AFA':
      return const _ChargeExplanation(
        'AFA (fuel adjustment)',
        'A monthly adjustment based on fuel prices. For domestic users it '
            'applies only to usage above the protection threshold.',
      );
    case 'Capacity':
      return const _ChargeExplanation(
        'Capacity charge',
        'TNB charges this to maintain the equipment and capacity needed to '
            'supply electricity to your home, even when usage is low.',
      );
    case 'Network':
      return const _ChargeExplanation(
        'Network charge',
        'This is the cost of delivering electricity through TNB’s network '
            'to your home.',
      );
    case 'Retail':
      return const _ChargeExplanation(
        'Retail charge',
        'A fixed monthly customer charge. Domestic users pay it only when '
            'usage is above the protection threshold.',
      );
    case 'Energy Efficiency Incentive':
      return const _ChargeExplanation(
        'EEI rebate',
        'A reward for using less electricity. The rebate rate is based on '
            'your whole month’s kWh, so higher usage can reduce it.',
      );
    case 'KWTBB (1.6%)':
      return const _ChargeExplanation(
        'KWTBB levy',
        'A small levy for the renewable energy fund. It is not charged when '
            'monthly usage is 300 kWh or below.',
      );
    case 'Service Tax (ST) (8%)':
      return const _ChargeExplanation(
        'Service tax (ST)',
        'Service tax on the taxable portion of the bill. Domestic users are '
            'protected up to the usage threshold.',
      );
    default:
      return const _ChargeExplanation(
        'About this charge',
        'This is one of the charges that makes up your estimated TNB bill.',
      );
  }
}

void _showChargeInfo(
  BuildContext context,
  ChargeLineItem item,
  _ChargeExplanation info,
) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 28.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(color: AppColors.border),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.text3.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      info.title,
                      style: AppTextStyles.titleMd,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20.r,
                      color: AppColors.text2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                info.description,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.text2),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _InfoRow(label: 'Rate', value: item.rateLabel),
                    SizedBox(height: 8.h),
                    _InfoRow(
                      label: 'Amount',
                      value:
                          '${item.isRebate ? '−' : ''}RM '
                          '${item.amount.abs().toStringAsFixed(2)}',
                      valueColor: item.isRebate ? AppColors.accent : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.caption),
        Text(
          value,
          style: AppTextStyles.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
