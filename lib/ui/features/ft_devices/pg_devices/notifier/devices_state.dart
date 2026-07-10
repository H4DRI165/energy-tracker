import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/extensions/tariff_type_extension.dart';
import 'package:energy_tracker/models/appliance.dart';
import 'package:flutter/material.dart';

@immutable
class DevicesPageState {
  const DevicesPageState({
    this.isLoading = true,
    this.appliances = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final List<Appliance> appliances;
  final String? errorMessage;
  static const Object _unset = Object();

  double get totalMonthlyKwh =>
      appliances.fold(0, (total, a) => total + a.monthlyKwh);

  double totalMonthlyCost(TariffType tariffType) =>
      appliances.fold(0, (total, a) => total + a.monthlyCost(tariffType));

  DevicesPageState copyWith({
    bool? isLoading,
    List<Appliance>? appliances,
    Object? errorMessage = _unset,
  }) {
    return DevicesPageState(
      isLoading: isLoading ?? this.isLoading,
      appliances: appliances ?? this.appliances,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DevicesPageState &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage &&
        const ListEquality<Appliance>().equals(other.appliances, appliances);
  }

  @override
  int get hashCode => Object.hash(
    isLoading,
    errorMessage,
    const ListEquality<Appliance>().hash(appliances),
  );
}
