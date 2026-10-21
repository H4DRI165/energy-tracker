import 'package:flutter/foundation.dart';

@immutable
class EeiBandRate {
  const EeiBandRate({required this.maxKwh, required this.senPerKwh});

  factory EeiBandRate.fromJson(Map<String, dynamic> json) {
    return EeiBandRate(
      maxKwh: (json['maxKwh'] as num?)?.toInt() ?? 0,
      senPerKwh: (json['senPerKwh'] as num?)?.toDouble() ?? 0,
    );
  }

  final int maxKwh;
  final double senPerKwh;

  Map<String, dynamic> toJson() => {
    'maxKwh': maxKwh,
    'senPerKwh': senPerKwh,
  };
}

/// A date window where the domestic protection threshold differs from the
/// schedule's base threshold (for example the 800 kWh relief in late 2026).
@immutable
class ProtectionPeriod {
  const ProtectionPeriod({
    required this.from,
    required this.to,
    required this.thresholdKwh,
  });

  factory ProtectionPeriod.fromJson(Map<String, dynamic> json) {
    return ProtectionPeriod(
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
      thresholdKwh: (json['thresholdKwh'] as num?)?.toDouble() ?? 0,
    );
  }

  final DateTime from;
  final DateTime to;
  final double thresholdKwh;

  bool covers(DateTime month) {
    final m = DateTime(month.year, month.month);
    return !m.isBefore(from) && !m.isAfter(to);
  }

  Map<String, dynamic> toJson() => {
    'from': _dateOnly(from),
    'to': _dateOnly(to),
    'thresholdKwh': thresholdKwh,
  };
}

/// A monthly AFA rate. [status] is `final` for a declared rate and
/// `forecast` for a Single Buyer projection.
@immutable
class AfaRate {
  const AfaRate({required this.senPerKwh, this.status = 'final'});

  factory AfaRate.fromJson(Object? json) {
    if (json is num) {
      return AfaRate(senPerKwh: json.toDouble());
    }
    if (json is Map) {
      return AfaRate(
        senPerKwh: (json['senPerKwh'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'final',
      );
    }
    return const AfaRate(senPerKwh: 0);
  }

  final double senPerKwh;
  final String status;

  bool get isForecast => status == 'forecast';

  Map<String, dynamic> toJson() => {
    'senPerKwh': senPerKwh,
    'status': status,
  };
}

/// The domestic tariff schedule and monthly AFA rates.
///
/// This is the data half of the tariff: rates, thresholds, bands and AFA.
/// The calculation rules stay in `TariffRates`.
@immutable
class DomesticTariff {
  const DomesticTariff({
    required this.id,
    required this.schemaVersion,
    required this.formulaVersion,
    required this.effectiveFrom,
    required this.effectiveTo,
    required this.energySenPerKwh,
    required this.energyHighSenPerKwh,
    required this.highUsageThresholdKwh,
    required this.capacitySenPerKwh,
    required this.networkSenPerKwh,
    required this.retailRmPerMonth,
    required this.kwtbbRate,
    required this.sstRate,
    required this.baseProtectionThresholdKwh,
    required this.protectionPeriods,
    required this.eeiBands,
    required this.afaByMonth,
    this.updatedAt,
    this.source = '',
  });

  factory DomesticTariff.fromJson(Map<String, dynamic> json) {
    final rawBands = json['eeiBands'];
    final rawProtection = json['protectionPeriods'];
    final rawAfa = json['afaByMonth'];

    return DomesticTariff(
      id: json['id'] as String? ?? 'domestic_general',
      schemaVersion:
          (json['schemaVersion'] as num?)?.toInt() ?? currentSchemaVersion,
      formulaVersion:
          (json['formulaVersion'] as num?)?.toInt() ?? currentFormulaVersion,
      effectiveFrom: _parseDate(json['effectiveFrom']) ?? DateTime(2025, 7),
      effectiveTo: _parseDate(json['effectiveTo']) ?? DateTime(2027, 12, 31),
      energySenPerKwh: _num(json['energySenPerKwh']),
      energyHighSenPerKwh: _num(json['energyHighSenPerKwh']),
      highUsageThresholdKwh: _num(json['highUsageThresholdKwh'], 1500),
      capacitySenPerKwh: _num(json['capacitySenPerKwh']),
      networkSenPerKwh: _num(json['networkSenPerKwh']),
      retailRmPerMonth: _num(json['retailRmPerMonth']),
      kwtbbRate: _num(json['kwtbbRate']),
      sstRate: _num(json['sstRate']),
      baseProtectionThresholdKwh: _num(
        json['baseProtectionThresholdKwh'],
        600,
      ),
      protectionPeriods: rawProtection is List
          ? rawProtection
                .whereType<Map<Object?, Object?>>()
                .map(
                  (e) => ProtectionPeriod.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const [],
      eeiBands: rawBands is List
          ? rawBands
                .whereType<Map<Object?, Object?>>()
                .map(
                  (e) => EeiBandRate.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      afaByMonth: rawAfa is Map<Object?, Object?>
          ? rawAfa.map(
              (key, value) => MapEntry(
                key.toString(),
                AfaRate.fromJson(value),
              ),
            )
          : const {},
      updatedAt: _parseDate(json['updatedAt']),
      source: json['source'] as String? ?? '',
    );
  }

  final String id;
  final int schemaVersion;
  final int formulaVersion;
  final DateTime effectiveFrom;
  final DateTime effectiveTo;

  final double energySenPerKwh;
  final double energyHighSenPerKwh;
  final double highUsageThresholdKwh;
  final double capacitySenPerKwh;
  final double networkSenPerKwh;
  final double retailRmPerMonth;
  final double kwtbbRate;
  final double sstRate;

  final double baseProtectionThresholdKwh;
  final List<ProtectionPeriod> protectionPeriods;
  final List<EeiBandRate> eeiBands;
  final Map<String, AfaRate> afaByMonth;

  final DateTime? updatedAt;
  final String source;

  static const int currentSchemaVersion = 1;
  static const int currentFormulaVersion = 1;

  /// Compiled-in fallback used when the bundled asset or Firestore is not
  /// available. Rates are the TNB Domestic General schedule effective
  /// 1 July 2025.
  static final DomesticTariff fallback = DomesticTariff(
    id: 'domestic_general',
    schemaVersion: currentSchemaVersion,
    formulaVersion: currentFormulaVersion,
    effectiveFrom: DateTime(2025, 7),
    effectiveTo: DateTime(2027, 12, 31),
    energySenPerKwh: 27.03,
    energyHighSenPerKwh: 37.03,
    highUsageThresholdKwh: 1500,
    capacitySenPerKwh: 4.55,
    networkSenPerKwh: 12.85,
    retailRmPerMonth: 10,
    kwtbbRate: 0.016,
    sstRate: 0.08,
    baseProtectionThresholdKwh: 600,
    protectionPeriods: [
      ProtectionPeriod(
        from: DateTime(2026, 9),
        to: DateTime(2026, 12, 31),
        thresholdKwh: 800,
      ),
    ],
    eeiBands: const [
      EeiBandRate(maxKwh: 200, senPerKwh: 25),
      EeiBandRate(maxKwh: 250, senPerKwh: 24.5),
      EeiBandRate(maxKwh: 300, senPerKwh: 22.5),
      EeiBandRate(maxKwh: 350, senPerKwh: 21),
      EeiBandRate(maxKwh: 400, senPerKwh: 17),
      EeiBandRate(maxKwh: 450, senPerKwh: 14.5),
      EeiBandRate(maxKwh: 500, senPerKwh: 12),
      EeiBandRate(maxKwh: 550, senPerKwh: 10.5),
      EeiBandRate(maxKwh: 600, senPerKwh: 9),
      EeiBandRate(maxKwh: 650, senPerKwh: 7.5),
      EeiBandRate(maxKwh: 700, senPerKwh: 5.5),
      EeiBandRate(maxKwh: 750, senPerKwh: 4.5),
      EeiBandRate(maxKwh: 800, senPerKwh: 4),
      EeiBandRate(maxKwh: 850, senPerKwh: 2.5),
      EeiBandRate(maxKwh: 900, senPerKwh: 1),
      EeiBandRate(maxKwh: 950, senPerKwh: 0.5),
      EeiBandRate(maxKwh: 1000, senPerKwh: 0.5),
    ],
    afaByMonth: const {
      '2025-07': AfaRate(senPerKwh: 0),
      '2025-08': AfaRate(senPerKwh: -1.45),
      '2025-09': AfaRate(senPerKwh: -1.10),
      '2025-10': AfaRate(senPerKwh: -6.50),
      '2025-11': AfaRate(senPerKwh: -8.91),
      '2025-12': AfaRate(senPerKwh: -6.42),
      '2026-01': AfaRate(senPerKwh: -4.99),
      '2026-02': AfaRate(senPerKwh: -2.77),
      '2026-03': AfaRate(senPerKwh: -2.15),
      '2026-04': AfaRate(senPerKwh: -0.47),
      '2026-05': AfaRate(senPerKwh: 1.38),
      '2026-06': AfaRate(senPerKwh: 2.59),
      '2026-07': AfaRate(senPerKwh: 3.59),
      '2026-08': AfaRate(senPerKwh: 3.80),
      '2026-09': AfaRate(senPerKwh: 3.67),
      '2026-10': AfaRate(senPerKwh: 3.61),
      '2026-11': AfaRate(senPerKwh: 4.27, status: 'forecast'),
      '2026-12': AfaRate(senPerKwh: 4.46, status: 'forecast'),
      '2027-01': AfaRate(senPerKwh: 7.59, status: 'forecast'),
    },
    updatedAt: DateTime(2026, 10),
    source: 'https://www.mytnb.com.my/tariff',
  );

  bool get isValid {
    if (schemaVersion != currentSchemaVersion) return false;
    if (formulaVersion > currentFormulaVersion) return false;
    if (energySenPerKwh <= 0 ||
        energyHighSenPerKwh < energySenPerKwh ||
        capacitySenPerKwh < 0 ||
        networkSenPerKwh < 0 ||
        retailRmPerMonth < 0 ||
        baseProtectionThresholdKwh <= 0) {
      return false;
    }
    if (kwtbbRate < 0 || kwtbbRate > 1 || sstRate < 0 || sstRate > 1) {
      return false;
    }
    if (eeiBands.isEmpty) return false;
    // The badge/summary UI has 17 hard-coded bands; reject a schedule that
    // would not fit it.
    if (eeiBands.length != 17) return false;
    for (var i = 1; i < eeiBands.length; i++) {
      if (eeiBands[i].maxKwh <= eeiBands[i - 1].maxKwh) return false;
      if (eeiBands[i].senPerKwh < 0) return false;
    }
    if (protectionPeriods.any(
      (p) => p.to.isBefore(p.from) || p.thresholdKwh <= 0,
    )) {
      return false;
    }
    if (afaByMonth.values.any(
      (r) => !r.senPerKwh.isFinite || r.senPerKwh.abs() > 20,
    )) {
      return false;
    }
    return true;
  }

  /// Domestic protection threshold for [month].
  double protectionThresholdKwh(DateTime month) {
    for (final period in protectionPeriods) {
      if (period.covers(month)) return period.thresholdKwh;
    }
    return baseProtectionThresholdKwh;
  }

  /// AFA rate for [month], or null when TNB has not published it yet.
  double? afaSenPerKwh(DateTime month) =>
      afaByMonth[_monthKey(month)]?.senPerKwh;

  AfaRate? afaRate(DateTime month) => afaByMonth[_monthKey(month)];

  /// EEI rebate for [kwh] (whole-month usage selects the band).
  double eeiSenPerKwh(double kwh) {
    if (kwh <= 0 || kwh > 1000) return 0;
    for (final band in eeiBands) {
      if (kwh <= band.maxKwh) return band.senPerKwh;
    }
    return 0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'schemaVersion': schemaVersion,
    'formulaVersion': formulaVersion,
    'effectiveFrom': _dateOnly(effectiveFrom),
    'effectiveTo': _dateOnly(effectiveTo),
    'energySenPerKwh': energySenPerKwh,
    'energyHighSenPerKwh': energyHighSenPerKwh,
    'highUsageThresholdKwh': highUsageThresholdKwh,
    'capacitySenPerKwh': capacitySenPerKwh,
    'networkSenPerKwh': networkSenPerKwh,
    'retailRmPerMonth': retailRmPerMonth,
    'kwtbbRate': kwtbbRate,
    'sstRate': sstRate,
    'baseProtectionThresholdKwh': baseProtectionThresholdKwh,
    'protectionPeriods': protectionPeriods.map((e) => e.toJson()).toList(),
    'eeiBands': eeiBands.map((e) => e.toJson()).toList(),
    'afaByMonth': afaByMonth.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'updatedAt': updatedAt?.toIso8601String(),
    'source': source,
  };

  DomesticTariff copyWith({
    String? id,
    int? schemaVersion,
    int? formulaVersion,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    double? energySenPerKwh,
    double? energyHighSenPerKwh,
    double? highUsageThresholdKwh,
    double? capacitySenPerKwh,
    double? networkSenPerKwh,
    double? retailRmPerMonth,
    double? kwtbbRate,
    double? sstRate,
    double? baseProtectionThresholdKwh,
    List<ProtectionPeriod>? protectionPeriods,
    List<EeiBandRate>? eeiBands,
    Map<String, AfaRate>? afaByMonth,
    DateTime? updatedAt,
    String? source,
  }) {
    return DomesticTariff(
      id: id ?? this.id,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      formulaVersion: formulaVersion ?? this.formulaVersion,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      energySenPerKwh: energySenPerKwh ?? this.energySenPerKwh,
      energyHighSenPerKwh: energyHighSenPerKwh ?? this.energyHighSenPerKwh,
      highUsageThresholdKwh:
          highUsageThresholdKwh ?? this.highUsageThresholdKwh,
      capacitySenPerKwh: capacitySenPerKwh ?? this.capacitySenPerKwh,
      networkSenPerKwh: networkSenPerKwh ?? this.networkSenPerKwh,
      retailRmPerMonth: retailRmPerMonth ?? this.retailRmPerMonth,
      kwtbbRate: kwtbbRate ?? this.kwtbbRate,
      sstRate: sstRate ?? this.sstRate,
      baseProtectionThresholdKwh:
          baseProtectionThresholdKwh ?? this.baseProtectionThresholdKwh,
      protectionPeriods: protectionPeriods ?? this.protectionPeriods,
      eeiBands: eeiBands ?? this.eeiBands,
      afaByMonth: afaByMonth ?? this.afaByMonth,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
    );
  }
}

double _num(Object? value, [double fallback = 0]) =>
    (value as num?)?.toDouble() ?? fallback;

DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return DateTime.tryParse(value.toString());
}

String _monthKey(DateTime month) =>
    '${month.year}-${month.month.toString().padLeft(2, '0')}';

String _dateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
