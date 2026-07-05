import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/constants/tariff_rates.dart';
import 'package:energy_tracker/extensions/tariff_type_extension.dart';

class Appliance {
  const Appliance({
    required this.id,
    required this.name,
    required this.category,
    required this.wattage,
    required this.dailyHours,
    required this.createdAt,
  });

  factory Appliance.fromDoc(String id, Map<String, dynamic> data) {
    return Appliance(
      id: id,
      name: _readString(data['name'], fallback: ''),
      category: _readString(data['category'], fallback: 'Other'),
      wattage: _readDouble(data['wattage']),
      dailyHours: _readDouble(data['dailyHours']),
      createdAt: _readCreatedAt(data['createdAt']),
    );
  }

  static String _readString(dynamic value, {required String fallback}) {
    return value is String ? value : fallback;
  }

  static double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _readCreatedAt(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  final String id;
  final String name;
  final String category;
  final double wattage;
  final double dailyHours;
  final DateTime createdAt;

  double get monthlyKwh => (wattage / 1000) * dailyHours * 30;
  double get dailyKwh => (wattage / 1000) * dailyHours;

  double monthlyCost(TariffType tariffType) =>
      TariffRates.marginalCost(monthlyKwh, tariffType);

  double dailyCost(TariffType tariffType) =>
      TariffRates.marginalCost(dailyKwh, tariffType);

  String get categoryEmoji {
    switch (category) {
      case 'Cooling':
        return '❄️';
      case 'Lighting':
        return '💡';
      case 'Kitchen':
        return '🍳';
      case 'Entertainment':
        return '🖥️';
      case 'Washing':
        return '🫧';
      case 'Heating':
        return '🌡️';
      default:
        return '🔌';
    }
  }

  Appliance copyWith({
    String? name,
    String? category,
    double? wattage,
    double? dailyHours,
  }) {
    return Appliance(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      wattage: wattage ?? this.wattage,
      dailyHours: dailyHours ?? this.dailyHours,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'wattage': wattage,
        'dailyHours': dailyHours,
        'createdAt': createdAt,
      };
}
