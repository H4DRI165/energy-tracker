import 'package:energy_tracker/theme/theme.dart';
import 'package:flutter/material.dart';

class TariffCalculatorState {
  const TariffCalculatorState({this.kwh = 350});

  final double kwh;

  double get tier1Kwh => kwh.clamp(0, 200);
  double get tier1 => tier1Kwh * 0.218;

  double get tier2Kwh => kwh > 200 ? (kwh - 200).clamp(0, 100) : 0;
  double get tier2 => tier2Kwh * 0.334;

  double get tier3Kwh => kwh > 300 ? (kwh - 300).clamp(0, 300) : 0;
  double get tier3 => tier3Kwh * 0.516;

  double get tier4Kwh => kwh > 600 ? kwh - 600 : 0;
  double get tier4 => tier4Kwh * 0.546;

  double get subtotal => tier1 + tier2 + tier3 + tier4;
  double get minCharge => kwh <= 0 ? 0 : (subtotal < 3.0 ? 3.0 - subtotal : 0);
  double get total => kwh <= 0 ? 0 : (subtotal < 3.0 ? 3.0 : subtotal);

  bool get hasTier4 => kwh > 600;

  int get currentTier {
    if (kwh <= 200) return 1;
    if (kwh <= 300) return 2;
    if (kwh <= 600) return 3;
    return 4;
  }

  String get tierBadgeLabel {
    switch (currentTier) {
      case 1:
        return 'Tier 1 — Low usage ✓';
      case 2:
        return 'Tier 2 — Moderate usage';
      case 3:
        return 'Tier 3 — High usage month';
      default:
        return 'Tier 4 — Very high usage';
    }
  }

  Color get tierBadgeColor {
    switch (currentTier) {
      case 1:
        return AppColors.accent;
      case 2:
        return AppColors.warn;
      default:
        return AppColors.danger;
    }
  }

  TariffCalculatorState copyWith({double? kwh}) {
    return TariffCalculatorState(kwh: kwh ?? this.kwh);
  }
}
