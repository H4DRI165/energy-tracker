import 'package:energy_tracker/models/domestic_tariff.dart';
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

/// Metadata for an EEI rebate band — the "tier" concept for badge/summary
/// displays.
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
  static DomesticTariff _tariff = DomesticTariff.fallback;

  /// The tariff data currently in use (bundled or Firestore-backed).
  static DomesticTariff get tariff => _tariff;

  /// Applies a remote/bundled schedule. Invalid schedules are ignored.
  static void configure(DomesticTariff tariff) {
    if (tariff.isValid) _tariff = tariff;
  }

  @visibleForTesting
  static void resetToFallback() => _tariff = DomesticTariff.fallback;

  /// Marginal cost rate per kWh — the flat components only.
  /// Used for per-appliance cost estimates, where EEI/KWTBB/SST
  /// depend on total household consumption and can't be attributed
  /// to a single appliance in isolation.
  static double marginalRatePerKwh() =>
      domesticGenerationLow + domesticCapacityRate + domesticNetworkRate;

  static double marginalCost(double kwh) => kwh * marginalRatePerKwh();

  /// Reference kWh used to scale the appliance summary ring chart: the point
  /// where the EEI rebate disappears.
  static const double ringReferenceKwh = 1000;

  /// Whether AFA is chargeable for [kwh] in the billing month. Domestic
  /// customers are exempt at or below the protection threshold (600 kWh, or
  /// 800 kWh for Sep–Dec 2026).
  static bool afaChargeable(double kwh, {DateTime? billingMonth}) =>
      kwh > protectionThresholdKwh(billingMonth ?? DateTime.now());

  /// Domestic bill-protection threshold for [billingMonth].
  ///
  /// TNB raised the domestic threshold from 600 kWh to 800 kWh for
  /// consumption from 1 Sep to 31 Dec 2026 (AFA, Retail and SST exemptions).
  /// It returns to 600 kWh from 1 Jan 2027.
  ///
  /// A billing period is treated as a whole calendar month here. TNB's own
  /// calculator prorates by days when a cycle spans the changeover dates.
  static double protectionThresholdKwh(DateTime billingMonth) =>
      _tariff.protectionThresholdKwh(billingMonth);

  /// Human-readable threshold for the current billing month.
  static String get protectionThresholdLabel =>
      '${protectionThresholdKwh(DateTime.now()).toStringAsFixed(0)} kWh';

  /// Round to sen, matching TNB's half-away-from-zero rounding.
  static double _round2(double value) => (value * 100).roundToDouble() / 100;

  static double estimateKwhFromBudget(
    double budget, {
    double? afaSenPerKwh,
    DateTime? billingMonth,
  }) {
    if (budget <= 0) return 0;

    double low = 0;
    double high = 3000;

    for (var i = 0; i < 50; i++) {
      final mid = (low + high) / 2;

      final bill = calculate(
        mid,
        afaSenPerKwh: afaSenPerKwh,
        billingMonth: billingMonth,
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
  // Golden tests cover 200/601/700/800/900/1600 kWh against TNB's public
  // bill calculator, including the 800 kWh Sep–Dec 2026 protection window.
  //
  // Charges split into two columns on TNB's bill (≤ protection threshold
  // "non-SST" slice and above-threshold "SST-applicable" slice), but
  // underlying per-kWh rates are flat across the whole month — the split is
  // a display/SST-computation device only.

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
      rebateRange: _senLabel(_eeiBands[0].senPerKwh),
      isHighUsage: false,
    ),
    (
      range: '201–300 kWh',
      rebateRange:
          '${_senLabel(_eeiBands[2].senPerKwh)}–'
          '${_senLabel(_eeiBands[1].senPerKwh)}',
      isHighUsage: false,
    ),
    (
      range: '301–500 kWh',
      rebateRange:
          '${_senLabel(_eeiBands[6].senPerKwh)}–'
          '${_senLabel(_eeiBands[3].senPerKwh)}',
      isHighUsage: false,
    ),
    (
      range: '501–700 kWh',
      rebateRange:
          '${_senLabel(_eeiBands[10].senPerKwh)}–'
          '${_senLabel(_eeiBands[7].senPerKwh)}',
      isHighUsage: true,
    ),
    (
      range: '701–1000 kWh',
      rebateRange:
          '${_senLabel(_eeiBands[16].senPerKwh)}–'
          '${_senLabel(_eeiBands[11].senPerKwh)}',
      isHighUsage: true,
    ),
    (range: '1001+ kWh', rebateRange: 'No rebate', isHighUsage: true),
  ];

  static String _senLabel(double sen) =>
      '${sen.toStringAsFixed(sen.truncateToDouble() == sen ? 0 : 1)} sen';

  // --- Generation (Energy) -------------------------------------------------
  /// Applied to ALL kWh when total ≤1500 kWh.
  static double get domesticGenerationLow => _tariff.energySenPerKwh / 100;

  /// Applied to ALL kWh (not just excess) when total >1500 kWh.
  static double get domesticGenerationHigh => _tariff.energyHighSenPerKwh / 100;

  // --- Other flat components -----------------------------------------------
  static double get domesticCapacityRate => _tariff.capacitySenPerKwh / 100;
  static double get domesticNetworkRate => _tariff.networkSenPerKwh / 100;
  static double get domesticRetailCharge => _tariff.retailRmPerMonth;

  // --- AFA -----------------------------------------------------------------
  /// AFA is published by TNB monthly. The schedule carries the published
  /// rates; returns null when the billing month has not been published yet.
  static double? afaSenPerKwhFor(DateTime billingMonth) =>
      _tariff.afaSenPerKwh(billingMonth);

  static AfaRate? afaRateFor(DateTime billingMonth) =>
      _tariff.afaRate(billingMonth);

  // --- Levies --------------------------------------------------------------
  /// KWTBB: 1.6% of (Energy + Capacity + Network − EEI).
  /// Excludes AFA and Retail from its base.
  /// Exempt when total ≤300 kWh.
  static double get domesticKwtbbRate => _tariff.kwtbbRate;

  /// SST: 8% of the value of the kWh above the protection threshold.
  /// TNB puts the full RM10 retail charge into the taxable slice even though
  /// it is a fixed charge.
  static double get domesticSstRate => _tariff.sstRate;

  // --- EEI lookup table ----------------------------------------------------
  /// Each band covers usage up to `maxKwh` (inclusive). The rebate rate is
  /// applied to the ENTIRE month's kWh, not just the incremental portion.
  static List<EeiBandRate> get _eeiBands => _tariff.eeiBands;

  static double _eeiSenPerKwh(double kwh) => _tariff.eeiSenPerKwh(kwh);

  /// Full domestic bill total. [afaSenPerKwh] defaults to 0 (excluded from
  /// estimates; pass the current published rate for accuracy).
  ///
  /// [billingMonth] selects the protection threshold (600 kWh normally,
  /// 800 kWh for Sep–Dec 2026) and defaults to the current month.
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
    double threshold,
    double taxableKwh,
    double afaSen,
    bool chargeable,
  })
  _domesticCharges(
    double kwh, {
    double? afaSenPerKwh,
    DateTime? billingMonth,
  }) {
    final month = billingMonth ?? DateTime.now();
    final threshold = protectionThresholdKwh(month);
    final chargeable = kwh > threshold;
    final taxableKwh = chargeable ? kwh - threshold : 0.0;
    final nonStKwh = chargeable ? threshold : kwh;

    final gen = kwh > 1500 ? domesticGenerationHigh : domesticGenerationLow;
    final afaSen = afaSenPerKwh ?? afaSenPerKwhFor(month) ?? 0;
    final afaRate = afaSen / 100;
    final eeiRate = _eeiSenPerKwh(kwh) / 100;

    // TNB splits the bill at the protection threshold and rounds each slice
    // to sen before totalling. Mirror that so the estimate matches TNB's
    // calculator to the sen.
    final energy = _round2(
      _round2(nonStKwh * gen) + _round2(taxableKwh * gen),
    );
    final afa = chargeable
        ? _round2(
            _round2(nonStKwh * afaRate) + _round2(taxableKwh * afaRate),
          )
        : 0.0;
    final capacity = _round2(
      _round2(nonStKwh * domesticCapacityRate) +
          _round2(taxableKwh * domesticCapacityRate),
    );
    final network = _round2(
      _round2(nonStKwh * domesticNetworkRate) +
          _round2(taxableKwh * domesticNetworkRate),
    );
    final retail = chargeable ? domesticRetailCharge : 0.0;
    final eei = _round2(kwh * eeiRate);

    final netNonSt = _round2(
      _round2(nonStKwh * gen) +
          _round2(nonStKwh * domesticCapacityRate) +
          _round2(nonStKwh * domesticNetworkRate) +
          (chargeable ? _round2(nonStKwh * afaRate) : 0.0) -
          (kwh > 0 ? eei * nonStKwh / kwh : 0.0),
    );
    final netSt = _round2(
      _round2(taxableKwh * gen) +
          _round2(taxableKwh * domesticCapacityRate) +
          _round2(taxableKwh * domesticNetworkRate) +
          _round2(taxableKwh * afaRate) +
          retail -
          (kwh > 0 ? eei * taxableKwh / kwh : 0.0),
    );
    final net = _round2(netNonSt + netSt);

    final kwtbb = kwh > 300
        ? _round2((energy + capacity + network - eei) * domesticKwtbbRate)
        : 0.0;
    // SST applies to the taxable slice's value, including the full RM10
    // retail charge (TNB's rule), not a proportional share of the whole bill.
    final sst = chargeable ? _round2(netSt * domesticSstRate) : 0.0;

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
      total: _round2(net + kwtbb + sst),
      threshold: threshold,
      taxableKwh: taxableKwh,
      afaSen: afaSen,
      chargeable: chargeable,
    );
  }

  static double calculateDomestic(
    double kwh, {
    double? afaSenPerKwh,
    DateTime? billingMonth,
  }) {
    if (kwh <= 0) return 0;
    return _domesticCharges(
      kwh,
      afaSenPerKwh: afaSenPerKwh,
      billingMonth: billingMonth,
    ).total;
  }

  static List<ChargeLineItem> domesticBreakdown(
    double kwh, {
    double? afaSenPerKwh,
    DateTime? billingMonth,
  }) {
    if (kwh <= 0) return [];
    final c = _domesticCharges(
      kwh,
      afaSenPerKwh: afaSenPerKwh,
      billingMonth: billingMonth,
    );

    return [
      ChargeLineItem(
        label: 'Energy',
        rateLabel: '${(c.gen * 100).toStringAsFixed(2)} sen/kWh',
        amount: c.energy,
      ),
      if (c.chargeable && c.afaSen != 0)
        ChargeLineItem(
          label: 'AFA',
          rateLabel: '${c.afaSen.toStringAsFixed(2)} sen/kWh',
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
      if (c.chargeable)
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
          rateLabel: '8% on usage above ${c.threshold.toStringAsFixed(0)} kWh',
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
        final sen = _eeiBands[i].senPerKwh;
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
    double kwh, {
    double? afaSenPerKwh,
    DateTime? billingMonth,
  }) => calculateDomestic(
    kwh,
    afaSenPerKwh: afaSenPerKwh,
    billingMonth: billingMonth,
  );

  static List<ChargeLineItem> breakdownFor(
    double kwh, {
    double? afaSenPerKwh,
    DateTime? billingMonth,
  }) => domesticBreakdown(
    kwh,
    afaSenPerKwh: afaSenPerKwh,
    billingMonth: billingMonth,
  );

  static double get minCharge => 0;

  static int getTier(double kwh) => getEeiBand(kwh).number;
}
