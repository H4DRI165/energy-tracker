import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:flutter/material.dart';

class TariffCalculatorState {
  const TariffCalculatorState({this.kwh = 350});

  final double kwh;

  double get tier1Kwh => kwh.clamp(0.0, 200.0);
  double get tier1 => tier1Kwh * TariffRates.domesticTier1;

  double get tier2Kwh => kwh > 200 ? (kwh - 200).clamp(0.0, 100.0) : 0;
  double get tier2 => tier2Kwh * TariffRates.domesticTier2;

  double get tier3Kwh => kwh > 300 ? (kwh - 300).clamp(0.0, 300.0) : 0;
  double get tier3 => tier3Kwh * TariffRates.domesticTier3;

  double get tier4Kwh => kwh > 600 ? (kwh - 600).clamp(0.0, 300.0) : 0;
  double get tier4 => tier4Kwh * TariffRates.domesticTier4;

  double get tier5Kwh => kwh > 900 ? kwh - 900 : 0;
  double get tier5 => tier5Kwh * TariffRates.domesticTier5;

  double get subtotal => tier1 + tier2 + tier3 + tier4 + tier5;
  double get minCharge => kwh <= 0
      ? 0
      : (subtotal < TariffRates.domesticMinCharge
          ? TariffRates.domesticMinCharge - subtotal
          : 0);
  double get total => kwh <= 0
      ? 0
      : (subtotal < TariffRates.domesticMinCharge
          ? TariffRates.domesticMinCharge
          : subtotal);

  bool get hasTier4 => kwh > 600;
  bool get hasTier5 => kwh > 900;

  int get currentTier => TariffRates.getTier(kwh);

  String get tierBadgeLabel => TariffRates.tierBadgeLabel(currentTier);

  Color get tierBadgeColor => TariffRates.getTierColor(currentTier);

  TariffCalculatorState copyWith({double? kwh}) {
    return TariffCalculatorState(kwh: kwh ?? this.kwh);
  }
}
