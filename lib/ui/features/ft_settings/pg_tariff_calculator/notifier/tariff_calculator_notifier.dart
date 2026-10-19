import 'package:energy_tracker/ui/features/ft_settings/pg_tariff_calculator/notifier/tariff_calculator_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tariffCalculatorProvider =
    NotifierProvider<TariffCalculatorNotifier, TariffCalculatorState>(
      TariffCalculatorNotifier.new,
    );

class TariffCalculatorNotifier extends Notifier<TariffCalculatorState> {
  @override
  TariffCalculatorState build() => const TariffCalculatorState();

  void setKwh(double kwh) => state = state.copyWith(kwh: kwh);
}
