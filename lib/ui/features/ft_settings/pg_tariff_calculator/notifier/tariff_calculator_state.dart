import 'package:energy_tracker/extensions/tariff_type_extension.dart';

class TariffCalculatorState {
  const TariffCalculatorState({
    this.kwh = 350,
    this.tariffType = TariffType.domestic,
    this.isInitializing = false,
  });

  final double kwh;
  final TariffType tariffType;
  final bool isInitializing;

  TariffCalculatorState copyWith({
    double? kwh,
    TariffType? tariffType,
    bool? isInitializing,
  }) {
    return TariffCalculatorState(
      kwh: kwh ?? this.kwh,
      tariffType: tariffType ?? this.tariffType,
      isInitializing: isInitializing ?? this.isInitializing,
    );
  }
}
