import 'package:cloud_firestore/cloud_firestore.dart';

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
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? 'Other',
      wattage: (data['wattage'] as num?)?.toDouble() ?? 0,
      dailyHours: (data['dailyHours'] as num?)?.toDouble() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  final String id;
  final String name;
  final String category;
  final double wattage;
  final double dailyHours;
  final DateTime createdAt;

  double get monthlyKwh => (wattage / 1000) * dailyHours * 30;

  double get monthlyCost {
    final kwh = monthlyKwh;
    if (kwh <= 0) return 0;
    double bill = 0;
    bill += kwh.clamp(0.0, 200.0) * 0.218;
    if (kwh > 200) bill += (kwh - 200).clamp(0.0, 100.0) * 0.334;
    if (kwh > 300) bill += (kwh - 300).clamp(0.0, 300.0) * 0.516;
    if (kwh > 600) bill += (kwh - 600) * 0.546;
    return bill;
  }

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
