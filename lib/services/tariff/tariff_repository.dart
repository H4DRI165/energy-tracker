import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/models/domestic_tariff.dart';
import 'package:flutter/services.dart';

/// Loads the domestic tariff schedule.
///
/// Order of preference:
/// 1. Firestore `tariffs/domestic_general` (published by TNB/Cloud Function)
/// 2. Bundled asset `assets/tariff/domestic_general.json`
/// 3. [DomesticTariff.fallback] compiled into the app
class TariffRepository {
  TariffRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _assetPath = 'assets/tariff/domestic_general.json';
  static const _docPath = 'tariffs/domestic_general';
  static const _timeout = Duration(seconds: 2);

  Future<DomesticTariff> load() async {
    final bundled = await _loadBundled();

    try {
      final remote = await _fetchRemote();
      if (remote != null && remote.isValid) return remote;
    } on Object catch (error, stack) {
      developer.log(
        'Falling back to bundled domestic tariff. '
        'Check that firestore.rules allows reads on tariffs/{id} and that '
        'tariffs/domestic_general exists.',
        name: 'TariffRepository',
        error: error,
        stackTrace: stack,
      );
    }

    return bundled;
  }

  Future<DomesticTariff> _loadBundled() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final parsed = DomesticTariff.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return parsed.isValid ? parsed : DomesticTariff.fallback;
    } on Object {
      return DomesticTariff.fallback;
    }
  }

  Future<DomesticTariff?> _fetchRemote() async {
    final snapshot = await _firestore.doc(_docPath).get().timeout(_timeout);
    if (!snapshot.exists) return null;

    final data = Map<String, dynamic>.from(snapshot.data()!);
    _normaliseTimestamps(data, ['effectiveFrom', 'effectiveTo', 'updatedAt']);
    return DomesticTariff.fromJson(data);
  }

  void _normaliseTimestamps(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is Timestamp) {
        data[key] = value.toDate().toIso8601String();
      }
    }
  }
}
