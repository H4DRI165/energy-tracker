import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/models/appliance.dart';
import 'package:energy_tracker/services/auth/providers/current_uid_provider.dart';
import 'package:energy_tracker/ui/features/ft_devices/pg_add_appliance/notifier/add_appliance_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<AddApplianceNotifier, AddAppliancePageState>
addApplianceProvider =
    NotifierProvider.autoDispose<AddApplianceNotifier, AddAppliancePageState>(
      AddApplianceNotifier.new,
    );

class AddApplianceNotifier extends Notifier<AddAppliancePageState> {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  Appliance? _editing;

  @override
  AddAppliancePageState build() => const AddAppliancePageState();

  void initForEdit(Appliance appliance) {
    _editing = appliance;
    state = AddAppliancePageState(
      name: appliance.name,
      category: appliance.category,
      wattage: appliance.wattage,
      dailyHours: appliance.dailyHours,
    );
  }

  void setName(String value) {
    state = state.copyWith(
      name: value,
      nameError: value.trim().isEmpty ? 'Name is required' : null,
    );
  }

  void setCategory(String value) {
    state = state.copyWith(category: value);
  }

  void setWattage(String value) {
    final w = double.tryParse(value) ?? 0;
    state = state.copyWith(
      wattage: w,
      wattageError: w <= 0 ? 'Enter a valid wattage' : null,
    );
  }

  void incrementHours() {
    if (state.dailyHours >= 24) return;
    state = state.copyWith(dailyHours: state.dailyHours + 0.5);
  }

  void decrementHours() {
    if (state.dailyHours <= 0.5) return;
    state = state.copyWith(dailyHours: state.dailyHours - 0.5);
  }

  Future<bool> save() async {
    if (!state.canSave) return false;

    final uid = ref.read(currentUidProvider).value;
    if (uid == null) {
      state = state.copyWith(errorMessage: 'Session expired.');
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final data = {
        'name': state.name.trim(),
        'category': state.category,
        'wattage': state.wattage,
        'dailyHours': state.dailyHours,
        'createdAt': _editing?.createdAt != null
            ? Timestamp.fromDate(_editing!.createdAt)
            : FieldValue.serverTimestamp(),
      };

      final col = _firestore
          .collection('users')
          .doc(uid)
          .collection('appliances');

      if (_editing != null) {
        await col.doc(_editing!.id).update(data);
      } else {
        await col.add(data);
      }

      if (!ref.mounted) return true;
      state = state.copyWith(isSaving: false);
      return true;
    } on FirebaseException catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isSaving: false,
        errorMessage: _mapError(e.code),
      );
      return false;
    } on Exception catch (_) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save. Please try again.',
      );
      return false;
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'permission-denied':
        return 'Permission denied.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Failed to save. Please try again.';
    }
  }
}
