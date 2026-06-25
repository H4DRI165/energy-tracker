import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:energy_tracker/services/notifiers/user_profile_notifier.dart';
import 'package:energy_tracker/ui/features/ft_settings/pg_tariff_calculator/notifier/tariff_calculator_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tariffCalculatorProvider =
    NotifierProvider<TariffCalculatorNotifier, TariffCalculatorState>(
  TariffCalculatorNotifier.new,
);

class TariffCalculatorNotifier extends Notifier<TariffCalculatorState> {
  @override
  TariffCalculatorState build() {
    // flipping it here never writes back to the account setting.
    final isLoading = ref.watch(isProfileLoadingProvider);
    final savedTariffType = ref.read(tariffTypeProvider);

    return TariffCalculatorState(
      tariffType: savedTariffType,
      isInitializing: isLoading,
    );
  }

  void setKwh(double kwh) => state = state.copyWith(kwh: kwh);

  void setTariffType(TariffType type) =>
      state = state.copyWith(tariffType: type, isInitializing: false);
}
