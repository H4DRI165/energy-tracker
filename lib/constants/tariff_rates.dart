import 'package:energy_tracker/constants/tariff_types.dart';
import 'package:energy_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';

class TierBreakdown {
  const TierBreakdown({
    required this.label,
    required this.kwh,
    required this.rate,
    required this.amount,
    required this.color,
    required this.fillPercent,
  });

  final String label;
  final double kwh;
  final double rate;
  final double amount;
  final Color color;
  final double fillPercent;
}

class TariffRates {
  // Domestic (Tariff A) — tiered
  static const double domesticTier1 = 0.218; // 1–200 kWh
  static const double domesticTier2 = 0.334; // 201–300 kWh
  static const double domesticTier3 = 0.516; // 301–600 kWh
  static const double domesticTier4 = 0.546; // 601–900 kWh
  static const double domesticTier5 = 0.571; // 901+ kWh
  static const double domesticMinCharge = 3;

  // Commercial LV (Tariff B) — tiered
  static const double commercialTier1 = 0.435; // 1–200 kWh
  static const double commercialTier2 = 0.509; // 201+ kWh
  static const double commercialMinCharge = 7.20;

  static double calculate(double kwh, TariffType tariffType) {
    return switch (tariffType) {
      TariffType.commercial => calculateCommercial(kwh),
      TariffType.domestic => calculateDomestic(kwh),
    };
  }

  static List<TierBreakdown> breakdownFor(double kwh, TariffType tariffType) {
    return switch (tariffType) {
      TariffType.commercial => _commercialBreakdown(kwh),
      TariffType.domestic => _domesticBreakdown(kwh),
    };
  }

  static double calculateDomestic(double kwh) {
    if (kwh <= 0) return 0;
    double bill = 0;
    bill += kwh.clamp(0.0, 200.0) * domesticTier1;
    if (kwh > 200) bill += (kwh - 200).clamp(0.0, 100.0) * domesticTier2;
    if (kwh > 300) bill += (kwh - 300).clamp(0.0, 300.0) * domesticTier3;
    if (kwh > 600) bill += (kwh - 600).clamp(0.0, 300.0) * domesticTier4;
    if (kwh > 900) bill += (kwh - 900) * domesticTier5;
    return bill < domesticMinCharge ? domesticMinCharge : bill;
  }

  static double calculateCommercial(double kwh) {
    if (kwh <= 0) return 0;
    double bill = 0;
    bill += kwh.clamp(0.0, 200.0) * commercialTier1;
    if (kwh > 200) bill += (kwh - 200) * commercialTier2;
    return bill < commercialMinCharge ? commercialMinCharge : bill;
  }

  static int getTier(double kwh) {
    if (kwh <= 200) return 1;
    if (kwh <= 300) return 2;
    if (kwh <= 600) return 3;
    if (kwh <= 900) return 4;
    return 5;
  }

  static String getTierKwhRange(int tier) {
    switch (tier) {
      case 1:
        return '1–200 kWh';
      case 2:
        return '201–300 kWh';
      case 3:
        return '301–600 kWh';
      case 4:
        return '601–900 kWh';
      default:
        return '901+ kWh';
    }
  }

  static String getTierPrice(int tier) {
    switch (tier) {
      case 1:
        return '21.8 sen';
      case 2:
        return '33.4 sen';
      case 3:
        return '51.6 sen';
      case 4:
        return '54.6 sen';
      default:
        return '57.1 sen';
    }
  }

  static Color getTierColor(int tier) {
    switch (tier) {
      case 1:
        return AppColors.accent;
      case 2:
        return AppColors.warn;
      case 3:
        return AppColors.accent3;
      case 4:
        return AppColors.danger;
      default:
        return AppColors.danger;
    }
  }

  static String tierBadgeLabel(int tier) {
    switch (tier) {
      case 1:
        return 'Tier 1 — Low usage ✓';
      case 2:
        return 'Tier 2 — Moderate usage';
      case 3:
        return 'Tier 3 — High usage month';
      case 4:
        return 'Tier 4 — Very high usage';
      default:
        return 'Tier 5 — Extremely high usage';
    }
  }

  static String getTierRangePriceLabel(int tier) =>
      'Tier $tier · ${getTierKwhRange(tier)} · ${getTierPrice(tier)}';

  static String getTierPriceKwhLabel(int tier) =>
      'Tier $tier — ${getTierPrice(tier)}/kWh';

  static List<TierBreakdown> _domesticBreakdown(double kwh) {
    if (kwh <= 0) return [];

    final breakdowns = <TierBreakdown>[];

    void addTier(int tier, double tierKwh, double rate, double bandWidth) {
      breakdowns.add(
        TierBreakdown(
          label: getTierRangePriceLabel(tier),
          kwh: tierKwh,
          rate: rate,
          amount: tierKwh * rate,
          color: getTierColor(tier),
          fillPercent: (tierKwh / bandWidth).clamp(0.0, 1.0),
        ),
      );
    }

    addTier(1, kwh.clamp(0.0, 200.0), domesticTier1, 200);
    if (kwh > 200) {
      addTier(2, (kwh - 200).clamp(0.0, 100.0), domesticTier2, 100);
    }
    if (kwh > 300) {
      addTier(3, (kwh - 300).clamp(0.0, 300.0), domesticTier3, 300);
    }
    if (kwh > 600) {
      addTier(4, (kwh - 600).clamp(0.0, 300.0), domesticTier4, 300);
    }
    if (kwh > 900) addTier(5, kwh - 900, domesticTier5, 400);

    return breakdowns;
  }

  static List<TierBreakdown> _commercialBreakdown(double kwh) {
    if (kwh <= 0) return [];

    final breakdowns = <TierBreakdown>[
      TierBreakdown(
        label: 'Tier 1 · 1–200 kWh · ${getTierPrice(1)}/kWh',
        kwh: kwh.clamp(0.0, 200.0),
        rate: commercialTier1,
        amount: kwh.clamp(0.0, 200.0) * commercialTier1,
        color: getTierColor(1),
        fillPercent: (kwh.clamp(0.0, 200.0) / 200).clamp(0.0, 1.0),
      ),
    ];

    if (kwh > 200) {
      final t2 = kwh - 200;
      breakdowns.add(
        TierBreakdown(
          label: 'Tier 2 · 201+ kWh · ${getTierPrice(2)}/kWh',
          kwh: t2,
          rate: commercialTier2,
          amount: t2 * commercialTier2,
          color: getTierColor(2),
          fillPercent: (t2 / 300).clamp(0.0, 1.0),
        ),
      );
    }

    return breakdowns;
  }
}
