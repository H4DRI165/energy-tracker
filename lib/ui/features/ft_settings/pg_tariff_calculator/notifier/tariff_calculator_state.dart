class TariffCalculatorState {
  const TariffCalculatorState({this.kwh = 350});

  final double kwh;

  TariffCalculatorState copyWith({double? kwh}) {
    return TariffCalculatorState(kwh: kwh ?? this.kwh);
  }
}
