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

  static const none = EeiBand(
    number: 0,
    kwhRange: '0 kWh',
    rebateSenPerKwh: 0,
    color: AppColors.text3,
    label: 'No usage',
    description: 'No usage recorded',
  );
}

class TariffRates {
  /// Marginal cost rate per kWh — the flat components only.
  /// Used for per-appliance cost estimates, where EEI/KWTBB/SST
  /// depend on total household consumption and can't be attributed
  /// to a single appliance in isolation.
  static double marginalRatePerKwh(TariffType tariffType) {
    return switch (tariffType) {
      TariffType.domestic =>
        domesticGenerationLow + domesticCapacityRate + domesticNetworkRate,
      TariffType.commercial =>
        commercialGenerationRate +
            commercialCapacityRate +
            commercialNetworkRate,
    };
  }

  static double marginalCost(double kwh, TariffType tariffType) =>
      kwh * marginalRatePerKwh(tariffType);

  /// Reference kWh used to scale the appliance summary ring chart.
  /// Domestic: 1000 kWh — the point where EEI rebate disappears,
  /// a meaningful "high usage" threshold for residential users.
  /// Commercial: 500 kWh — a practical midpoint for small business
  /// LV usage; no equivalent EEI threshold exists for commercial.
  static const double domesticRingReferenceKwh = 1000;
  static const double commercialRingReferenceKwh = 500;

  static double ringReferenceKwh(TariffType tariffType) =>
      tariffType == TariffType.domestic
      ? domesticRingReferenceKwh
      : commercialRingReferenceKwh;

  /// Whether AFA applies for a given tariff type and monthly kWh.
  /// Commercial: always applies regardless of usage.
  /// Domestic: exempt at or below 600 kWh.
  static bool afaApplies(TariffType tariffType, double kwh) =>
      tariffType == TariffType.commercial || kwh > 600;

  static double estimateKwhFromBudget(
    double budget,
    TariffType tariffType, {
    double afaSenPerKwh = 0,
  }) {
    if (budget <= 0) return 0;

    double low = 0;
    double high = 3000;

    for (var i = 0; i < 50; i++) {
      final mid = (low + high) / 2;

      final bill = calculate(
        mid,
        tariffType,
        afaSenPerKwh: afaSenPerKwh,
      );

      if (bill < budget) {
        low = mid;
      } else {
        high = mid;
      }
    }

    return (low + high) / 2;
  }

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

  static String get generationLowLabel =>
      '${(domesticGenerationLow * 100).toStringAsFixed(2)} sen/kWh';

  static String get generationHighLabel =>
      '${(domesticGenerationHigh * 100).toStringAsFixed(2)} sen/kWh';

  static String get capacityLabel =>
      '${(domesticCapacityRate * 100).toStringAsFixed(2)} sen/kWh';

  static String get networkLabel =>
      '${(domesticNetworkRate * 100).toStringAsFixed(2)} sen/kWh';

  static String get retailLabel =>
      'RM${domesticRetailCharge.toStringAsFixed(0)}/month';

  static String get kwtbbLabel =>
      '${(domesticKwtbbRate * 100).toStringAsFixed(1)}%';

  static String get sstLabel =>
      '${(domesticSstRate * 100).toStringAsFixed(0)}%';

  /// EEI band range label for the info card grouped display.
  /// Groups adjacent bands with the same colour into human-readable ranges.
  static List<({String range, String rebateRange, bool isHighUsage})>
  get eeiBandGroups => [
    (
      range: '1–200 kWh',
      rebateRange: _senLabel(_eeiBands[0].rebateSen),
      isHighUsage: false,
    ),
    (
      range: '201–300 kWh',
      rebateRange:
          '${_senLabel(_eeiBands[2].rebateSen)}–'
          '${_senLabel(_eeiBands[1].rebateSen)}',
      isHighUsage: false,
    ),
    (
      range: '301–500 kWh',
      rebateRange:
          '${_senLabel(_eeiBands[6].rebateSen)}–'
          '${_senLabel(_eeiBands[3].rebateSen)}',
      isHighUsage: false,
    ),
    (
      range: '501–700 kWh',
      rebateRange:
          '${_senLabel(_eeiBands[10].rebateSen)}–'
          '${_senLabel(_eeiBands[7].rebateSen)}',
      isHighUsage: true,
    ),
    (
      range: '701–1000 kWh',
      rebateRange:
          '${_senLabel(_eeiBands[16].rebateSen)}–'
          '${_senLabel(_eeiBands[11].rebateSen)}',
      isHighUsage: true,
    ),
    (range: '1001+ kWh', rebateRange: 'No rebate', isHighUsage: true),
  ];

  static String _senLabel(double sen) =>
      '${sen.toStringAsFixed(sen.truncateToDouble() == sen ? 0 : 1)} sen';

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
  /// source: https://www.mytnb.com.my/tariff/index.html?v=1.1.60#calculator
  static const List<({int maxKwh, double rebateSen})> _eeiBands = [
    (maxKwh: 200, rebateSen: 25.0), // CONFIRMED
    (maxKwh: 250, rebateSen: 24.5), // CONFIRMED
    (maxKwh: 300, rebateSen: 22.5), // CONFIRMED
    (maxKwh: 350, rebateSen: 21.0), // CONFIRMED
    (maxKwh: 400, rebateSen: 17.0), // CONFIRMED
    (maxKwh: 450, rebateSen: 14.5), // CONFIRMED
    (maxKwh: 500, rebateSen: 12.0), // CONFIRMED
    (maxKwh: 550, rebateSen: 10.5), // CONFIRMED
    (maxKwh: 600, rebateSen: 9.0), // CONFIRMED
    (maxKwh: 650, rebateSen: 7.5), // CONFIRMED
    (maxKwh: 700, rebateSen: 5.5), // CONFIRMED
    (maxKwh: 750, rebateSen: 4.5), // CONFIRMED
    (maxKwh: 800, rebateSen: 4.0), // CONFIRMED
    (maxKwh: 850, rebateSen: 2.5), // CONFIRMED
    (maxKwh: 900, rebateSen: 1.0), // CONFIRMED
    (maxKwh: 950, rebateSen: 0.5), // CONFIRMED
    (maxKwh: 1000, rebateSen: 0.5), // CONFIRMED
  ];

  static double _eeiSenPerKwh(double kwh) {
    if (kwh > 1000) return 0;
    for (final band in _eeiBands) {
      if (kwh <= band.maxKwh) return band.rebateSen;
    }
    return 0;
  }

  /// Full domestic bill total. [afaSenPerKwh] defaults to 0 (exempt ≤600
  /// kWh; pass the current published rate for >600 kWh for accuracy).
  /// Displays a disclaimer wherever this is called without a real AFA rate.
  // Private record holding all intermediate domestic charge values.
  // Single source of truth — calculateDomestic and domesticBreakdown
  // both derive from this, guaranteeing the total always equals the
  // sum of the line items.
  static ({
    double gen,
    double energy,
    double afa,
    double capacity,
    double network,
    double retail,
    double eei,
    double net,
    double kwtbb,
    double sst,
    double total,
  })
  _domesticCharges(double kwh, {double afaSenPerKwh = domesticAfaDefault}) {
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
    return (
      gen: gen,
      energy: energy,
      afa: afa,
      capacity: capacity,
      network: network,
      retail: retail,
      eei: eei,
      net: net,
      kwtbb: kwtbb,
      sst: sst,
      total: net + kwtbb + sst,
    );
  }

  static double calculateDomestic(
    double kwh, {
    double afaSenPerKwh = domesticAfaDefault,
  }) {
    if (kwh <= 0) return 0;
    return _domesticCharges(kwh, afaSenPerKwh: afaSenPerKwh).total;
  }

  static List<ChargeLineItem> domesticBreakdown(
    double kwh, {
    double afaSenPerKwh = domesticAfaDefault,
  }) {
    if (kwh <= 0) return [];
    final c = _domesticCharges(kwh, afaSenPerKwh: afaSenPerKwh);

    return [
      ChargeLineItem(
        label: 'Energy',
        rateLabel: '${(c.gen * 100).toStringAsFixed(2)} sen/kWh',
        amount: c.energy,
      ),
      if (kwh > 600)
        ChargeLineItem(
          label: 'AFA',
          rateLabel: afaSenPerKwh == 0
              ? '0 sen/kWh (Jun 2026)'
              : '${afaSenPerKwh.toStringAsFixed(2)} sen/kWh',
          amount: c.afa,
        ),
      ChargeLineItem(
        label: 'Capacity',
        rateLabel: '${(domesticCapacityRate * 100).toStringAsFixed(2)} sen/kWh',
        amount: c.capacity,
      ),
      ChargeLineItem(
        label: 'Network',
        rateLabel: '${(domesticNetworkRate * 100).toStringAsFixed(2)} sen/kWh',
        amount: c.network,
      ),
      if (kwh > 600)
        ChargeLineItem(
          label: 'Retail',
          rateLabel: 'RM${domesticRetailCharge.toStringAsFixed(0)}/month',
          amount: c.retail,
        ),
      if (c.eei > 0)
        ChargeLineItem(
          label: 'Energy Efficiency Incentive',
          rateLabel: '-${_eeiSenPerKwh(kwh).toStringAsFixed(2)} sen/kWh',
          amount: -c.eei,
          isRebate: true,
        ),
      if (c.kwtbb > 0)
        ChargeLineItem(
          label: 'KWTBB',
          rateLabel: kwtbbLabel,
          amount: c.kwtbb,
          isLevy: true,
        ),
      if (c.sst > 0)
        ChargeLineItem(
          label: 'Service Tax (SST)',
          rateLabel: '8% on usage above 600 kWh',
          amount: c.sst,
          isLevy: true,
        ),
    ];
  }

  /// EEI band for the given kWh — the new "tier" equivalent for domestic,
  /// used by badge/summary displays (Direction C).
  static EeiBand getEeiBand(double kwh) {
    if (kwh <= 0) {
      return EeiBand.none;
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

  static double calculate(
    double kwh,
    TariffType tariffType, {
    double afaSenPerKwh = 0,
  }) {
    return switch (tariffType) {
      TariffType.domestic => calculateDomestic(kwh, afaSenPerKwh: afaSenPerKwh),
      TariffType.commercial => calculateCommercial(
        kwh,
        afaSenPerKwh: afaSenPerKwh,
      ),
    };
  }

  static List<ChargeLineItem> breakdownFor(
    double kwh,
    TariffType tariffType, {
    double afaSenPerKwh = 0,
  }) {
    return switch (tariffType) {
      TariffType.domestic => domesticBreakdown(kwh, afaSenPerKwh: afaSenPerKwh),
      TariffType.commercial => commercialBreakdown(
        kwh,
        afaSenPerKwh: afaSenPerKwh,
      ),
    };
  }

  static double minChargeFor(TariffType tariffType) => switch (tariffType) {
    TariffType.domestic => 0,
    TariffType.commercial => 0,
  };

  // =========================================================================
  // Commercial LV (Tariff B) — UNCHANGED, old 2-tier structure
  // =========================================================================
  // Single flat generation rate — no crossover at 1500 kWh unlike domestic.
  // CONFIRMED: 27.03 sen applies at 100, 200, ..., 1200, 1600 kWh.
  static const double commercialGenerationRate = 0.2703;

  static const double commercialCapacityRate = 0.0883; // CONFIRMED
  static const double commercialNetworkRate = 0.1482; // CONFIRMED
  static const double commercialRetailCharge =
      20; // CONFIRMED — always applied, no threshold
  static const double commercialAfaDefault = 0; // monthly, excluded by default
  static const double commercialKwtbbRate =
      0.016; // CONFIRMED — no exemption threshold

  static String get commercialCapacityLabel =>
      '${(commercialCapacityRate * 100).toStringAsFixed(2)} sen/kWh';

  static String get commercialNetworkLabel =>
      '${(commercialNetworkRate * 100).toStringAsFixed(2)} sen/kWh';

  static String get commercialRetailLabel =>
      'RM${commercialRetailCharge.toStringAsFixed(0)}/month';

  // EEI: 11.0 sen/kWh for ≤200 kWh, 0 above. CONFIRMED.
  static const double commercialEeiRateSenPerKwh = 11;

  static String get commercialEeiRateLabel =>
      '$commercialEeiRateSenPerKwh sen/kWh';

  static double _commercialEeiSenPerKwh(double kwh) =>
      kwh <= 200 ? commercialEeiRateSenPerKwh : 0.0;

  // SST: not applicable for Non-Domestic LV General.
  // CONFIRMED absent across full 100–1600 kWh range (all consumption
  // in Non-Applicable column with zero in Applicable column at all levels).
  static ({
    double energy,
    double afa,
    double capacity,
    double network,
    double eei,
    double net,
    double kwtbb,
    double total,
  })
  _commercialCharges(
    double kwh, {
    double afaSenPerKwh = commercialAfaDefault,
  }) {
    final energy = kwh * commercialGenerationRate;
    final afa = kwh * (afaSenPerKwh / 100);
    final capacity = kwh * commercialCapacityRate;
    final network = kwh * commercialNetworkRate;
    final eei = kwh * (_commercialEeiSenPerKwh(kwh) / 100);
    final net =
        energy + afa + capacity + network + commercialRetailCharge - eei;
    final kwtbb = (energy + capacity + network - eei) * commercialKwtbbRate;
    return (
      energy: energy,
      afa: afa,
      capacity: capacity,
      network: network,
      eei: eei,
      net: net,
      kwtbb: kwtbb,
      total: net + kwtbb,
    );
  }

  static double calculateCommercial(
    double kwh, {
    double afaSenPerKwh = commercialAfaDefault,
  }) {
    if (kwh <= 0) return 0;
    return _commercialCharges(kwh, afaSenPerKwh: afaSenPerKwh).total;
  }

  static List<ChargeLineItem> commercialBreakdown(
    double kwh, {
    double afaSenPerKwh = commercialAfaDefault,
  }) {
    if (kwh <= 0) return [];
    final c = _commercialCharges(kwh, afaSenPerKwh: afaSenPerKwh);

    return [
      ChargeLineItem(
        label: 'Energy',
        rateLabel:
            '${(commercialGenerationRate * 100).toStringAsFixed(2)} sen/kWh',
        amount: c.energy,
      ),
      if (afaSenPerKwh > 0)
        ChargeLineItem(
          label: 'AFA',
          rateLabel: '${afaSenPerKwh.toStringAsFixed(2)} sen/kWh',
          amount: c.afa,
        ),
      ChargeLineItem(
        label: 'Capacity',
        rateLabel:
            '${(commercialCapacityRate * 100).toStringAsFixed(2)} sen/kWh',
        amount: c.capacity,
      ),
      ChargeLineItem(
        label: 'Network',
        rateLabel:
            '${(commercialNetworkRate * 100).toStringAsFixed(2)} sen/kWh',
        amount: c.network,
      ),
      ChargeLineItem(
        label: 'Retail',
        rateLabel: commercialRetailLabel,
        amount: commercialRetailCharge,
      ),
      if (c.eei > 0)
        ChargeLineItem(
          label: 'Energy Efficiency Incentive',
          rateLabel:
              '-${_commercialEeiSenPerKwh(kwh).toStringAsFixed(1)} sen/kWh',
          amount: -c.eei,
          isRebate: true,
        ),
      ChargeLineItem(
        label: 'KWTBB',
        rateLabel: kwtbbLabel,
        amount: c.kwtbb,
        isLevy: true,
      ),
    ];
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
      return tier == 1 ? '11.0 sen EEI rebate' : 'No rebate';
    }
    if (tier == 0 || tier > _eeiBands.length) return '0 sen';
    return '${_eeiBands[tier - 1].rebateSen.toStringAsFixed(1)} sen rebate';
  }

  static String tierBadgeLabel(int tier, TariffType tariffType) {
    if (tariffType == TariffType.commercial) {
      return tier == 1 ? 'EEI applies · ≤200 kWh' : 'No EEI rebate · >200 kWh';
    }
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
}
