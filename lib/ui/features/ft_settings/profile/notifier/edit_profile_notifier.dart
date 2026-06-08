import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/ui/features/ft_settings/profile/notifier/edit_profile_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditProfileNotifier extends ChangeNotifier {
  EditProfileNotifier({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  bool _disposed = false;

  EditProfilePageState _state = const EditProfilePageState();
  EditProfilePageState get state => _state;

  String _originalFullName = '';
  String _originalTnbAccountNo = '';

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> init() async {
    _state = _state.copyWith(isLoading: true);
    _notify();

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final fullName = data['fullName'] as String? ?? '';
      final tnbAccountNo = data['tnbAccountNo'] as String? ?? '';
      final email = _auth.currentUser?.email ?? '';

      _originalFullName = fullName;
      _originalTnbAccountNo = tnbAccountNo;

      _state = _state.copyWith(
        fullName: fullName,
        email: email,
        tnbAccountNo: tnbAccountNo,
      );
    } on Exception catch (_) {
      _state = _state.copyWith(
        errorMessage: 'Failed to load profile.',
      );
    } finally {
      _state = _state.copyWith(isLoading: false);
      _notify();
    }
  }

  void setFullName(String value) {
    _state = _state.copyWith(
      fullName: value,
      fullNameError: null,
      successMessage: null,
    );
    _notify();
  }

  void setTnbAccountNo(String value) {
    _state = _state.copyWith(
      tnbAccountNo: value,
      tnbAccountError: null,
      successMessage: null,
    );
    _notify();
  }

  bool get hasChanges =>
      _state.fullName.trim() != _originalFullName ||
      _state.tnbAccountNo.trim() != _originalTnbAccountNo;

  Future<bool> save() async {
    _state = _state.copyWith(
      fullNameError: null,
      tnbAccountError: null,
      errorMessage: null,
      successMessage: null,
    );
    _notify();

    var hasError = false;

    if (_state.fullName.trim().isEmpty) {
      _state = _state.copyWith(fullNameError: 'Full name is required');
      hasError = true;
    } else if (_state.fullName.trim().length < 2) {
      _state = _state.copyWith(fullNameError: 'Name is too short');
      hasError = true;
    }

    if (_state.tnbAccountNo.trim().isNotEmpty &&
        _state.tnbAccountNo.trim().length < 6) {
      _state = _state.copyWith(
        tnbAccountError: 'TNB account number seems too short',
      );
      hasError = true;
    }

    if (hasError) {
      _notify();
      return false;
    }

    if (!hasChanges) {
      _state = _state.copyWith(successMessage: 'No changes to save.');
      _notify();
      return true;
    }

    _state = _state.copyWith(isSaving: true);
    _notify();

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Session expired.');

      await Future.wait([
        _firestore.collection('users').doc(uid).update({
          'fullName': _state.fullName.trim(),
          'tnbAccountNo': _state.tnbAccountNo.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }),
        _auth.currentUser!.updateDisplayName(_state.fullName.trim()),
      ]);

      _originalFullName = _state.fullName.trim();
      _originalTnbAccountNo = _state.tnbAccountNo.trim();

      _state = _state.copyWith(
        successMessage: 'Profile updated successfully.',
      );
      return true;
    } on FirebaseException catch (e) {
      _state = _state.copyWith(
        errorMessage: _mapError(e.code),
      );
      return false;
    } on Exception catch (_) {
      _state = _state.copyWith(
        errorMessage: 'Failed to save. Please try again.',
      );
      return false;
    } finally {
      _state = _state.copyWith(isSaving: false);
      _notify();
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'permission-denied':
        return 'Permission denied. Please try again.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Failed to save. Please try again.';
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
