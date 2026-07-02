import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:energy_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// A single itemised charge line, mirroring TNB's own e-bill layout.
/// Used for the domestic tariff breakdown display (Direction A screens:
/// bill detail, usage screen).
class ChargeLineItem {
  const ChargeLineItem({
    required this.label,
    required this.rateLabel,
    required this.amount,
    this.isRebate = false,
    this.isLevy = false,
  });

  final String label;
  final String rateLabel;
  final double amount; // negative for rebates (EEI)
  final bool isRebate; // true for EEI — render with green / "−" style
  final bool isLevy; // true for KWTBB/SST — render muted
}

/// Metadata for an EEI rebate band — the new "tier" concept for Direction C
/// (badge/summary displays). Replaces getTierColor/getTierKwhRange/
/// tierBadgeLabel for domestic. Commercial still uses the old int-based
/// helpers.
class EeiBand {
  const EeiBand({
    required this.number,
    required this.kwhRange,
    required this.rebateSenPerKwh,
    required this.color,
    required this.label,
    required this.description,
  });

  final int number; // 1–17; 0 means above 1000kWh (no rebate)
  final String kwhRange; // e.g. "451–500 kWh"
  final double rebateSenPerKwh;
  final Color color; // green → amber → red as rebate shrinks
  final String label; // e.g. "Band 5 · 12.0 sen rebate"
  final String description; // e.g. "Moderate usage — good rebate"
}

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
  // =========================================================================
  // Domestic — post-1 July 2025 TNB restructuring
  // =========================================================================
  //
  // Formula verified against 5 real TNB e-bills at 300/600/900/1100/1600 kWh.
  // Every charge line and final total reproduced exactly.
  //
  // Charges split into two columns on TNB's bill (≤600 kWh "non-SST" slice
  // and >600 kWh "SST-applicable" slice), but underlying per-kWh rates are
  // flat across the whole month — the split is a display/SST-computation
  // device only.

  // --- Generation (Energy) -------------------------------------------------
  /// Applied to ALL kWh when total ≤1500 kWh. CONFIRMED.
  static const double domesticGenerationLow = 0.2703;

  /// Applied to ALL kWh (not just excess) when total >1500 kWh. CONFIRMED.
  static const double domesticGenerationHigh = 0.3703;

  // --- Other flat components -----------------------------------------------
  static const double domesticCapacityRate = 0.0455; // CONFIRMED
  static const double domesticNetworkRate = 0.1285; // CONFIRMED
  static const double domesticRetailCharge = 10; // RM flat; CONFIRMED

  // --- AFA -----------------------------------------------------------------
  /// AFA (Automatic Fuel Adjustment) is published by TNB monthly and is NOT
  /// a fixed tariff constant. Exempt when total ≤600 kWh.
  /// Bill-confirmed June 2026 values: 0 sen (≤600 kWh), 2.59 sen (>600 kWh).
  /// Default is 0 — callers should pass the current published rate when
  /// available. The app displays a disclaimer wherever AFA is excluded.
  static const double domesticAfaDefault = 0;

  // --- Levies --------------------------------------------------------------
  /// KWTBB: 1.6% of (Energy + Capacity + Network − EEI).
  /// Excludes AFA and Retail from its base. CONFIRMED.
  /// Exempt when total ≤300 kWh.
  static const double domesticKwtbbRate = 0.016;

  /// SST: 8% of the net subtotal attributable to kWh above 600.
  /// Computed proportionally: (kWh_above_600 / total_kWh) × net_subtotal.
  /// CONFIRMED.
  static const double domesticSstRate = 0.08;

  // --- EEI lookup table ----------------------------------------------------
  // ignore: comment_references
  /// Each band covers usage up to [maxKwh] (inclusive). The rebate rate is
  /// applied to the ENTIRE month's kWh, not just the incremental portion —
  /// confirmed from real bill cross-checks.
  ///
  /// Bands marked CONFIRMED were reverse-engineered from real TNB e-bills.
  /// Bands marked SOURCED come from a secondary source (malaysia4u.com) and
  /// have not been independently verified. Spot-check against a real bill
  /// at that usage level if billing precision is critical.
  static const List<({int maxKwh, double rebateSen})> _eeiBands = [
    (maxKwh: 200, rebateSen: 25.0), // CONFIRMED
    (maxKwh: 250, rebateSen: 24.5), // SOURCED
    (maxKwh: 300, rebateSen: 22.5), // CONFIRMED
    (maxKwh: 350, rebateSen: 20.0), // SOURCED
    (maxKwh: 400, rebateSen: 17.5), // SOURCED
    (maxKwh: 450, rebateSen: 15.0), // SOURCED
    (maxKwh: 500, rebateSen: 12.0), // CONFIRMED
    (maxKwh: 550, rebateSen: 9.5), // SOURCED
    (maxKwh: 600, rebateSen: 7.5), // SOURCED
    (maxKwh: 650, rebateSen: 6.5), // SOURCED
    (maxKwh: 700, rebateSen: 5.5), // SOURCED
    (maxKwh: 750, rebateSen: 4.5), // CONFIRMED
    (maxKwh: 800, rebateSen: 3.5), // SOURCED
    (maxKwh: 850, rebateSen: 2.5), // SOURCED
    (maxKwh: 900, rebateSen: 1.0), // CONFIRMED
    (maxKwh: 950, rebateSen: 0.5), // SOURCED
    (maxKwh: 1000, rebateSen: 0.25), // SOURCED
    // Above 1000 kWh: EEI = 0. CONFIRMED (1100 kWh and 1600 kWh bills).
  ];

  static double _eeiSenPerKwh(double kwh) {
    if (kwh > 1000) return 0;
    for (final band in _eeiBands) {
      if (kwh <= band.maxKwh) return band.rebateSen;
    }
    return 0;
  }

  // =========================================================================
  // Domestic — public API
  // =========================================================================

  /// Full domestic bill total. [afaSenPerKwh] defaults to 0 (exempt ≤600
  /// kWh; pass the current published rate for >600 kWh for accuracy).
  /// Displays a disclaimer wherever this is called without a real AFA rate.
  static double calculateDomestic(
    double kwh, {
    double afaSenPerKwh = domesticAfaDefault,
  }) {
    if (kwh <= 0) return 0;

    final gen = kwh > 1500 ? domesticGenerationHigh : domesticGenerationLow;
    final energy = kwh * gen;
    final afa = kwh > 600 ? kwh * (afaSenPerKwh / 100) : 0.0;
    final capacity = kwh * domesticCapacityRate;
    final network = kwh * domesticNetworkRate;
    final retail = kwh > 600 ? domesticRetailCharge : 0.0;
    final eei = kwh * (_eeiSenPerKwh(kwh) / 100);

    final net = energy + afa + capacity + network + retail - eei;

    final kwtbb = kwh > 300
        ? (energy + capacity + network - eei) * domesticKwtbbRate
        : 0.0;

    final sst = kwh > 600 ? (net * ((kwh - 600) / kwh)) * domesticSstRate : 0.0;

    return net + kwtbb + sst;
  }

  /// Itemised breakdown matching TNB's own e-bill line items.
  /// Used by bill detail and usage screens (Direction A).
  static List<ChargeLineItem> domesticBreakdown(
    double kwh, {
    double afaSenPerKwh = domesticAfaDefault,
  }) {
    if (kwh <= 0) return [];

    final gen = kwh > 1500 ? domesticGenerationHigh : domesticGenerationLow;
    final energy = kwh * gen;
    final afa = kwh > 600 ? kwh * (afaSenPerKwh / 100) : 0.0;
    final capacity = kwh * domesticCapacityRate;
    final network = kwh * domesticNetworkRate;
    final retail = kwh > 600 ? domesticRetailCharge : 0.0;
    final eei = kwh * (_eeiSenPerKwh(kwh) / 100);
    final net = energy + afa + capacity + network + retail - eei;
    final kwtbb = kwh > 300
        ? (energy + capacity + network - eei) * domesticKwtbbRate
        : 0.0;
    final sst = kwh > 600 ? (net * ((kwh - 600) / kwh)) * domesticSstRate : 0.0;

    return [
      ChargeLineItem(
        label: 'Energy',
        rateLabel: '${(gen * 100).toStringAsFixed(2)} sen/kWh',
        amount: energy,
      ),
      if (kwh > 600)
        ChargeLineItem(
          label: 'AFA',
          rateLabel: afaSenPerKwh == 0
              ? '0 sen/kWh (Jun 2026)'
              : '${afaSenPerKwh.toStringAsFixed(2)} sen/kWh',
          amount: afa,
        ),
      ChargeLineItem(
        label: 'Capacity',
        rateLabel: '${(domesticCapacityRate * 100).toStringAsFixed(2)} sen/kWh',
        amount: capacity,
      ),
      ChargeLineItem(
        label: 'Network',
        rateLabel: '${(domesticNetworkRate * 100).toStringAsFixed(2)} sen/kWh',
        amount: network,
      ),
      if (kwh > 600)
        ChargeLineItem(
          label: 'Retail',
          rateLabel: 'RM10/month',
          amount: retail,
        ),
      if (eei > 0)
        ChargeLineItem(
          label: 'Energy Efficiency Incentive',
          rateLabel: '-${_eeiSenPerKwh(kwh).toStringAsFixed(2)} sen/kWh',
          amount: -eei,
          isRebate: true,
        ),
      if (kwtbb > 0)
        ChargeLineItem(
          label: 'KWTBB',
          rateLabel: '1.6%',
          amount: kwtbb,
          isLevy: true,
        ),
      if (sst > 0)
        ChargeLineItem(
          label: 'Service Tax (SST)',
          rateLabel: '8% on usage above 600 kWh',
          amount: sst,
          isLevy: true,
        ),
    ];
  }

  /// EEI band for the given kWh — the new "tier" equivalent for domestic,
  /// used by badge/summary displays (Direction C).
  static EeiBand getEeiBand(double kwh) {
    if (kwh <= 0) {
      return const EeiBand(
        number: 0,
        kwhRange: '0 kWh',
        rebateSenPerKwh: 0,
        color: AppColors.accent,
        label: 'No usage',
        description: 'No usage recorded',
      );
    }

    if (kwh > 1000) {
      return const EeiBand(
        number: 0,
        kwhRange: '1001+ kWh',
        rebateSenPerKwh: 0,
        color: AppColors.danger,
        label: 'No rebate',
        description: 'Very high usage — no EEI rebate',
      );
    }

    final ranges = [
      '1–200 kWh',
      '201–250 kWh',
      '251–300 kWh',
      '301–350 kWh',
      '351–400 kWh',
      '401–450 kWh',
      '451–500 kWh',
      '501–550 kWh',
      '551–600 kWh',
      '601–650 kWh',
      '651–700 kWh',
      '701–750 kWh',
      '751–800 kWh',
      '801–850 kWh',
      '851–900 kWh',
      '901–950 kWh',
      '951–1000 kWh',
    ];

    final descriptions = [
      'Very low usage — maximum rebate ✓',
      'Low usage — excellent rebate ✓',
      'Low usage — strong rebate ✓',
      'Moderate usage — good rebate',
      'Moderate usage — good rebate',
      'Moderate usage — fair rebate',
      'Moderate usage — fair rebate',
      'High usage — small rebate',
      'High usage — small rebate',
      'High usage — minimal rebate',
      'High usage — minimal rebate',
      'Very high usage — low rebate',
      'Very high usage — low rebate',
      'Very high usage — low rebate',
      'Very high usage — minimal rebate',
      'Near threshold — very low rebate',
      'Near threshold — very low rebate',
    ];

    final colors = [
      AppColors.accent, // 1–200
      AppColors.accent, // 201–250
      AppColors.accent, // 251–300
      AppColors.accent2, // 301–350
      AppColors.accent2, // 351–400
      AppColors.accent2, // 401–450
      AppColors.warn, // 451–500
      AppColors.warn, // 501–550
      AppColors.warn, // 551–600
      AppColors.warn, // 601–650
      AppColors.accent3, // 651–700
      AppColors.accent3, // 701–750
      AppColors.danger, // 751–800
      AppColors.danger, // 801–850
      AppColors.danger, // 851–900
      AppColors.danger, // 901–950
      AppColors.danger, // 951–1000
    ];

    for (var i = 0; i < _eeiBands.length; i++) {
      if (kwh <= _eeiBands[i].maxKwh) {
        final sen = _eeiBands[i].rebateSen;
        return EeiBand(
          number: i + 1,
          kwhRange: ranges[i],
          rebateSenPerKwh: sen,
          color: colors[i],
          label: 'Band ${i + 1} · ${sen.toStringAsFixed(1)} sen rebate',
          description: descriptions[i],
        );
      }
    }

    // Should not reach here given the >1000 guard above
    return const EeiBand(
      number: 0,
      kwhRange: '1001+ kWh',
      rebateSenPerKwh: 0,
      color: AppColors.danger,
      label: 'No rebate',
      description: 'Very high usage — no EEI rebate',
    );
  }

  // =========================================================================
  // Shared dispatch
  // =========================================================================

  static double calculate(double kwh, TariffType tariffType) {
    return switch (tariffType) {
      TariffType.domestic => calculateDomestic(kwh),
      TariffType.commercial => calculateCommercial(kwh),
    };
  }

  static double minChargeFor(TariffType tariffType) => switch (tariffType) {
        TariffType.domestic => 0, // no flat minimum in the new structure
        TariffType.commercial => commercialMinCharge,
      };

  // =========================================================================
  // Commercial LV (Tariff B) — UNCHANGED, old 2-tier structure
  // =========================================================================
  //
  // Not yet researched against TNB's current non-domestic tariff schedule.
  // Likely restructured post-July 2025 (voltage-based rather than the old
  // Tariff B block model) — separate research item.

  static const double commercialTier1 = 0.435;
  static const double commercialTier2 = 0.509;
  static const double commercialMinCharge = 7.20;

  static double calculateCommercial(double kwh) {
    if (kwh <= 0) return 0;
    var bill = kwh.clamp(0.0, 200.0) * commercialTier1;
    if (kwh > 200) bill += (kwh - 200) * commercialTier2;
    return bill < commercialMinCharge ? commercialMinCharge : bill;
  }

  // Commercial still uses the old tier helpers since that tariff is unchanged.
  static int getTier(double kwh, TariffType tariffType) {
    if (tariffType == TariffType.commercial) {
      return kwh <= 200 ? 1 : 2;
    }
    // For domestic, return EEI band number as the "tier" proxy.
    return getEeiBand(kwh).number;
  }

  static Color getTierColor(int tier, TariffType tariffType) {
    if (tariffType == TariffType.commercial) {
      return tier == 1 ? AppColors.accent : AppColors.danger;
    }
    // Domestic: color comes from EeiBand, not an int tier.
    // This overload is kept for backwards-compat during migration —
    // prefer getEeiBand(kwh).color directly in new code.
    switch (tier) {
      case 0:
        return AppColors.danger;
      case 1:
      case 2:
      case 3:
        return AppColors.accent;
      case 4:
      case 5:
      case 6:
        return AppColors.accent2;
      case 7:
      case 8:
      case 9:
      case 10:
        return AppColors.warn;
      case 11:
      case 12:
        return AppColors.accent3;
      default:
        return AppColors.danger;
    }
  }

  static String getTierKwhRange(int tier, TariffType tariffType) {
    if (tariffType == TariffType.commercial) {
      return tier == 1 ? '1–200 kWh' : '201+ kWh';
    }
    // Domestic: prefer getEeiBand(kwh).kwhRange in new code.
    if (tier == 0) return '1001+ kWh';
    if (tier < 1 || tier > _eeiBands.length) return '';
    final maxKwh = _eeiBands[tier - 1].maxKwh;
    final minKwh = tier == 1 ? 1 : _eeiBands[tier - 2].maxKwh + 1;
    return '$minKwh–$maxKwh kWh';
  }

  static String getTierPrice(int tier, TariffType tariffType) {
    if (tariffType == TariffType.commercial) {
      return tier == 1
          ? '${(commercialTier1 * 100).toStringAsFixed(1)} sen'
          : '${(commercialTier2 * 100).toStringAsFixed(1)} sen';
    }
    if (tier == 0 || tier > _eeiBands.length) return '0 sen';
    return '${_eeiBands[tier - 1].rebateSen.toStringAsFixed(1)} sen rebate';
  }

  static String tierBadgeLabel(int tier, TariffType tariffType) {
    if (tariffType == TariffType.commercial) {
      return tier == 1 ? 'Tier 1 — Low usage ✓' : 'Tier 2 — High usage';
    }
    // Domestic: prefer getEeiBand(kwh).label in new code.
    if (tier == 0) return 'No rebate — very high usage';
    if (tier <= 3) return 'Band $tier — Low usage ✓';
    if (tier <= 6) return 'Band $tier — Moderate usage';
    if (tier <= 10) return 'Band $tier — High usage';
    return 'Band $tier — Very high usage';
  }

  static String getTierRangePriceLabel(int tier, TariffType tariffType) =>
      'Band $tier · ${getTierKwhRange(tier, tariffType)} · '
      '${getTierPrice(tier, tariffType)}';

  static String getTierPriceKwhLabel(int tier, TariffType tariffType) =>
      'Band $tier — ${getTierPrice(tier, tariffType)}/kWh';

  // Commercial breakdown — unchanged.
  static List<TierBreakdown> breakdownFor(double kwh, TariffType tariffType) {
    if (tariffType == TariffType.domestic) {
      // Domestic no longer uses TierBreakdown — use domesticBreakdown()
      // for ChargeLineItem list, or getEeiBand() for the band badge.
      // This path should not be reached in migrated code.
      assert(
        false,
        'breakdownFor() called for domestic — use domesticBreakdown() instead',
      );
      return [];
    }
    return _commercialBreakdown(kwh);
  }

  static List<TierBreakdown> _commercialBreakdown(double kwh) {
    if (kwh <= 0) return [];
    return [
      TierBreakdown(
        label: getTierRangePriceLabel(1, TariffType.commercial),
        kwh: kwh.clamp(0.0, 200.0),
        rate: commercialTier1,
        amount: kwh.clamp(0.0, 200.0) * commercialTier1,
        color: getTierColor(1, TariffType.commercial),
        fillPercent: (kwh.clamp(0.0, 200.0) / 200).clamp(0.0, 1.0),
      ),
      if (kwh > 200)
        TierBreakdown(
          label: getTierRangePriceLabel(2, TariffType.commercial),
          kwh: kwh - 200,
          rate: commercialTier2,
          amount: (kwh - 200) * commercialTier2,
          color: getTierColor(2, TariffType.commercial),
          fillPercent: ((kwh - 200) / 300).clamp(0.0, 1.0),
        ),
    ];
  }
}
