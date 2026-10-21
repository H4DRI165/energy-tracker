import 'package:cloud_firestore/cloud_firestore.dart';
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

  double get totalMonthlyCost =>
      appliances.fold(0, (total, a) => total + a.monthlyCost());

  double get estimatedLowMonthlyCost =>
      appliances.fold(0, (total, a) => total + a.estimatedLowMonthlyCost);

  double get estimatedHighMonthlyCost =>
      appliances.fold(0, (total, a) => total + a.estimatedHighMonthlyCost);

  List<Appliance> get appliancesByCost {
    final sorted = [...appliances]
      ..sort((a, b) => b.monthlyCost().compareTo(a.monthlyCost()));
    return sorted;
  }

  Map<String, double> get categoryMonthlyCost {
    final totals = <String, double>{};
    for (final appliance in appliances) {
      totals.update(
        appliance.category,
        (value) => value + appliance.monthlyCost(),
        ifAbsent: appliance.monthlyCost,
      );
    }
    return totals;
  }

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
