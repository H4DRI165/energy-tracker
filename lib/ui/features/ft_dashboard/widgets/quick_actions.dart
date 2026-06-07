import 'package:energy_tracker/theme/theme.dart';
import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({
    required this.onAddReading,
    required this.onScanBill,
    super.key,
  });

  final VoidCallback onAddReading;
  final VoidCallback onScanBill;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            icon: '📊',
            label: 'Add Reading',
            onTap: onAddReading,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionTile(
            icon: '📄',
            label: 'Scan Bill',
            onTap: onScanBill,
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: AppTextStyles.bodySm
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
