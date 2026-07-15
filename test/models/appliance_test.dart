import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:energy_tracker/models/appliance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final appliance = Appliance(
    id: 'fan-1',
    name: 'Ceiling fan',
    category: 'Cooling',
    wattage: 60,
    dailyHours: 8,
    createdAt: DateTime(2026, 7),
  );

  test('calculates daily and monthly kWh from wattage and hours', () {
    expect(appliance.dailyKwh, closeTo(0.48, 0.000001));
    expect(appliance.monthlyKwh, closeTo(14.4, 0.000001));
  });

  test('calculates estimated cost using the selected tariff', () {
    expect(
      appliance.dailyCost(TariffType.commercial),
      closeTo(0.243264, 0.000001),
    );
    expect(
      appliance.monthlyCost(TariffType.domestic),
      closeTo(6.39792, 0.000001),
    );
  });

  test('copyWith retains immutable fields and changes requested fields', () {
    final updated = appliance.copyWith(name: 'Standing fan', dailyHours: 10);

    expect(updated.id, appliance.id);
    expect(updated.createdAt, appliance.createdAt);
    expect(updated.name, 'Standing fan');
    expect(updated.dailyHours, 10);
    expect(updated.wattage, appliance.wattage);
  });
}
