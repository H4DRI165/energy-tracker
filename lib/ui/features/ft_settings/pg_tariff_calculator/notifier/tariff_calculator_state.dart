
import 'package:energy_tracker/extensions/tariff_type_extension.dart';

class TariffCalculatorState {
  const TariffCalculatorState({
    this.kwh = 350,
    this.tariffType = TariffType.domestic,
  });

  final double kwh;
  final TariffType tariffType;

  TariffCalculatorState copyWith({double? kwh, TariffType? tariffType}) {
    return TariffCalculatorState(
      kwh: kwh ?? this.kwh,
      tariffType: tariffType ?? this.tariffType,
    );
  }
}
