import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/ui/features/ft_settings/edit_profile/notifier/edit_profile_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final AsyncNotifierProvider<EditProfileNotifier, EditProfilePageState>
    editProfileProvider = AsyncNotifierProvider.autoDispose<EditProfileNotifier,
        EditProfilePageState>(
  EditProfileNotifier.new,
);

class EditProfileNotifier extends AsyncNotifier<EditProfilePageState> {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  String _originalFullName = '';
  String _originalTnbAccountNo = '';

  @override
  Future<EditProfilePageState> build() async {
    final user = _auth.currentUser;
    if (user == null) return const EditProfilePageState(isLoading: false);

    final uid = user.uid;
    final authName = user.displayName ?? '';

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      _originalFullName = authName;
      return EditProfilePageState(
        isLoading: false,
        fullName: authName,
        email: user.email ?? '',
      );
    }

    final data = doc.data()!;
    final fullName = data['fullName'] as String? ?? authName;
    final tnbAccountNo = data['tnbAccountNo'] as String? ?? '';

    _originalFullName = fullName;
    _originalTnbAccountNo = tnbAccountNo;

    return EditProfilePageState(
      isLoading: false,
      fullName: fullName,
      email: user.email ?? '',
      tnbAccountNo: tnbAccountNo,
    );
  }

  void setFullName(String value) {
    state = state.whenData(
      (s) => s.copyWith(
        fullName: value,
        fullNameError: null,
        successMessage: null,
        hasChanges: value.trim() != _originalFullName ||
            s.tnbAccountNo.trim() != _originalTnbAccountNo,
      ),
    );
  }

  void setTnbAccountNo(String value) {
    state = state.whenData(
      (s) => s.copyWith(
        tnbAccountNo: value,
        tnbAccountError: null,
        successMessage: null,
        hasChanges: s.fullName.trim() != _originalFullName ||
            value.trim() != _originalTnbAccountNo,
      ),
    );
  }

  Future<bool> save() async {
    final current = state.value;
    if (current == null) return false;

    state = state.whenData(
      (s) => s.copyWith(
        fullNameError: null,
        tnbAccountError: null,
        errorMessage: null,
        successMessage: null,
      ),
    );

    var hasError = false;

    if (current.fullName.trim().isEmpty) {
      state = state.whenData(
        (s) => s.copyWith(fullNameError: 'Full name is required'),
      );
      hasError = true;
    } else if (current.fullName.trim().length < 2) {
      state = state.whenData(
        (s) => s.copyWith(fullNameError: 'Name is too short'),
      );
      hasError = true;
    }

    if (current.tnbAccountNo.trim().isNotEmpty &&
        current.tnbAccountNo.trim().length < 12) {
      state = state.whenData(
        (s) => s.copyWith(
          tnbAccountError: 'TNB Account Number must be exactly 12 digits',
        ),
      );
      hasError = true;
    }

    if (hasError) return false;

    if (!(state.value?.hasChanges ?? false)) {
      state = state.whenData(
        (s) => s.copyWith(successMessage: 'No changes to save.'),
      );
      return true;
    }

    state = state.whenData((s) => s.copyWith(isSaving: true));

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Session expired.');

      await _firestore.collection('users').doc(user.uid).set(
        {
          'fullName': current.fullName.trim(),
          'tnbAccountNo': current.tnbAccountNo.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await user.updateDisplayName(current.fullName.trim());

      _originalFullName = current.fullName.trim();
      _originalTnbAccountNo = current.tnbAccountNo.trim();

      state = state.whenData(
        (s) => s.copyWith(
          isSaving: false,
          successMessage: 'Profile updated successfully.',
        ),
      );
      return true;
    } on FirebaseException catch (e) {
      state = state.whenData(
        (s) => s.copyWith(isSaving: false, errorMessage: _mapError(e.code)),
      );
      return false;
    } on Exception catch (_) {
      state = state.whenData(
        (s) => s.copyWith(
          isSaving: false,
          errorMessage: 'Failed to save. Please try again.',
        ),
      );
      return false;
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
}
