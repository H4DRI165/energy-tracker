import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/services/auth/providers/current_uid_provider.dart';
import 'package:energy_tracker/ui/components/logging/app_logger.dart';
import 'package:energy_tracker/ui/components/logging/notifier/loggable_notifier.dart';
import 'package:energy_tracker/ui/features/ft_settings/pg_edit_profile/notifier/edit_profile_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final AsyncNotifierProvider<EditProfileNotifier, EditProfilePageState>
editProfileProvider =
    AsyncNotifierProvider.autoDispose<
      EditProfileNotifier,
      EditProfilePageState
    >(
      EditProfileNotifier.new,
    );

class EditProfileNotifier extends AsyncNotifier<EditProfilePageState>
    with LoggableNotifier<EditProfilePageState> {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  String get screenName => 'EditProfilePage';

  String _originalFullName = '';
  String _originalTnbAccountNo = '';

  @override
  Future<EditProfilePageState> build() async {
    final uid = ref.watch(currentUidProvider).value;
    if (uid == null) return const EditProfilePageState(isLoading: false);

    final authUser = FirebaseAuth.instance.currentUser;
    final authName = authUser?.displayName ?? '';
    final email = authUser?.email ?? '';

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      _originalFullName = authName;
      return EditProfilePageState(
        isLoading: false,
        fullName: authName,
        email: email,
      );
    }

    final data = doc.data()!;
    final fullName = data['fullName'] as String? ?? authName;
    final tnbAccountNo = data['tnbAccountNo'] as String? ?? '';
    final photoUrl = data['photoUrl'] as String?;
    final photoUpdatedAt = data['photoUpdatedAt'] as Timestamp?;

    _originalFullName = fullName;
    _originalTnbAccountNo = tnbAccountNo;

    return EditProfilePageState(
      isLoading: false,
      fullName: fullName,
      email: email,
      tnbAccountNo: tnbAccountNo,
      photoUrl: photoUrl,
      photoVersion: photoUpdatedAt?.millisecondsSinceEpoch,
    );
  }

  void setFullName(String value) {
    state = state.whenData(
      (s) => s.copyWith(
        fullName: value,
        fullNameError: null,
        successMessage: null,
        hasChanges:
            value.trim() != _originalFullName ||
            s.tnbAccountNo.trim() != _originalTnbAccountNo ||
            s.localPhotoFile != null ||
            (s.removePhoto && s.photoUrl != null),
      ),
    );
  }

  void setTnbAccountNo(String value) {
    state = state.whenData(
      (s) => s.copyWith(
        tnbAccountNo: value,
        tnbAccountError: null,
        successMessage: null,
        hasChanges:
            s.fullName.trim() != _originalFullName ||
            value.trim() != _originalTnbAccountNo ||
            s.localPhotoFile != null ||
            (s.removePhoto && s.photoUrl != null),
      ),
    );
  }

  void setLocalPhoto(XFile file) {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        localPhotoFile: file,
        removePhoto: false,
        successMessage: null,
        hasChanges: true,
      ),
    );
  }

  void removePhoto() {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        localPhotoFile: null,
        removePhoto: true,
        successMessage: null,
        hasChanges:
            current.fullName.trim() != _originalFullName ||
            current.tnbAccountNo.trim() != _originalTnbAccountNo ||
            current.photoUrl != null,
      ),
    );
  }

  Future<void> pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked == null) return;
    setLocalPhoto(picked);
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
        current.tnbAccountNo.trim().length != 12) {
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

    String? uploadedPath;
    final oldPhotoUrl = current.photoUrl;
    final shouldRemovePhoto = current.removePhoto && current.photoUrl != null;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Session expired.');

      String? newPhotoUrl;
      int? newPhotoVersion;

      if (current.localPhotoFile != null) {
        newPhotoVersion = DateTime.now().millisecondsSinceEpoch;
        uploadedPath = 'users/${user.uid}/profile_$newPhotoVersion.jpg';

        final ref = FirebaseStorage.instance.ref(uploadedPath);
        final bytes = await current.localPhotoFile!.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        newPhotoUrl = await ref.getDownloadURL();
      }

      final updates = <String, dynamic>{
        'fullName': current.fullName.trim(),
        'tnbAccountNo': current.tnbAccountNo.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (newPhotoUrl != null) {
        updates['photoUrl'] = newPhotoUrl;
        updates['photoUpdatedAt'] = Timestamp.fromMillisecondsSinceEpoch(
          newPhotoVersion!,
        );
      } else if (shouldRemovePhoto) {
        updates['photoUrl'] = FieldValue.delete();
        updates['photoUpdatedAt'] = FieldValue.delete();
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(updates, SetOptions(merge: true));

      if ((newPhotoUrl != null || shouldRemovePhoto) && oldPhotoUrl != null) {
        try {
          await FirebaseStorage.instance.refFromURL(oldPhotoUrl).delete();
        } on FirebaseException catch (e, st) {
          logError('Failed to delete previous avatar', e, st);
        }
      }

      try {
        await user.updateDisplayName(current.fullName.trim());
      } on Exception catch (e, st) {
        logError(
          'Failed to sync displayName to FirebaseAuth',
          e,
          st,
        );
      }

      _originalFullName = current.fullName.trim();
      _originalTnbAccountNo = current.tnbAccountNo.trim();

      state = state.whenData(
        (s) => s.copyWith(
          isSaving: false,
          successMessage: 'Profile updated successfully.',
          photoUrl: newPhotoUrl ?? (shouldRemovePhoto ? null : s.photoUrl),
          photoVersion:
              newPhotoVersion ?? (shouldRemovePhoto ? null : s.photoVersion),
          localPhotoFile: null,
          removePhoto: false,
          hasChanges: false,
        ),
      );
      return true;
    } on FirebaseException catch (e, st) {
      if (uploadedPath != null) {
        try {
          await FirebaseStorage.instance.ref(uploadedPath).delete();
        } on FirebaseException catch (cleanupError, cleanupSt) {
          logError(
            'Failed to clean up orphaned avatar upload',
            cleanupError,
            cleanupSt,
          );
        }
      }

      logError(
        'Failed to save profile (Firebase)',
        e,
        st,
        context: {
          'full_name_length': current.fullName.trim().length,
          'has_tnb_account': current.tnbAccountNo.trim().isNotEmpty,
        },
      );
      state = state.whenData(
        (s) =>
            s.copyWith(isSaving: false, errorMessage: mapFirebaseError(e.code)),
      );
      return false;
    } on Exception catch (e, st) {
      if (uploadedPath != null) {
        try {
          await FirebaseStorage.instance.ref(uploadedPath).delete();
        } on FirebaseException catch (cleanupError, cleanupSt) {
          logError(
            'Failed to clean up orphaned avatar upload',
            cleanupError,
            cleanupSt,
          );
        }
      }

      logError(
        'Failed to save profile',
        e,
        st,
        context: {
          'full_name_length': current.fullName.trim().length,
          'has_tnb_account': current.tnbAccountNo.trim().isNotEmpty,
        },
      );
      state = state.whenData(
        (s) => s.copyWith(
          isSaving: false,
          errorMessage: 'Failed to save. Please try again.',
        ),
      );
      return false;
    }
  }
}
