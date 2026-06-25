enum TariffType {
  domestic,
  commercial,
}

extension TariffTypeX on TariffType {
  String get label {
    switch (this) {
      case TariffType.domestic:
        return 'Domestic (Residential)';
      case TariffType.commercial:
        return 'Commercial (LV)';
    }
  }

  String get shortLabel {
    switch (this) {
      case TariffType.domestic:
        return 'Domestic';
      case TariffType.commercial:
        return 'Commercial';
    }
  }

  String get subtitle {
    switch (this) {
      case TariffType.domestic:
        return 'Tariff A — For homes & apartments';
      case TariffType.commercial:
        return 'Tariff B — Shops, offices';
    }
  }

  String get icon {
    switch (this) {
      case TariffType.domestic:
        return '🏠';
      case TariffType.commercial:
        return '🏢';
    }
  }

  String get value {
    switch (this) {
      case TariffType.domestic:
        return 'domestic';
      case TariffType.commercial:
        return 'commercial';
    }
  }

  static TariffType fromValue(String value) => TariffType.values.firstWhere(
        (t) => t.value == value,
        orElse: () => TariffType.domestic,
      );
}
