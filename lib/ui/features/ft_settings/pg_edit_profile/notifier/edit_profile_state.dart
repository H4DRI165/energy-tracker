import 'package:image_picker/image_picker.dart';

class EditProfilePageState {
  const EditProfilePageState({
    this.isLoading = true,
    this.isSaving = false,
    this.hasChanges = false,
    this.fullName = '',
    this.email = '',
    this.tnbAccountNo = '',
    this.fullNameError,
    this.tnbAccountError,
    this.successMessage,
    this.errorMessage,
    this.photoUrl,
    this.localPhotoFile,
    this.isUploadingPhoto = false,
    this.photoVersion,
  });

  final bool isLoading;
  final bool isSaving;
  final bool hasChanges;
  final String fullName;
  final String email;
  final String tnbAccountNo;
  final String? fullNameError;
  final String? tnbAccountError;
  final String? successMessage;
  final String? errorMessage;
  final String? photoUrl;
  final XFile? localPhotoFile;
  final bool isUploadingPhoto;
  final int? photoVersion;
  static const Object _unset = Object();

  String? get displayPhotoUrl {
    if (photoUrl == null || photoVersion == null) return photoUrl;
    final uri = Uri.parse(photoUrl!);
    return uri
        .replace(
          queryParameters: {
            ...uri.queryParameters,
            'v': '$photoVersion',
          },
        )
        .toString();
  }

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  EditProfilePageState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? hasChanges,
    String? fullName,
    String? email,
    String? tnbAccountNo,
    Object? fullNameError = _unset,
    Object? tnbAccountError = _unset,
    Object? successMessage = _unset,
    Object? errorMessage = _unset,
    Object? photoUrl = _unset,
    Object? localPhotoFile = _unset,
    bool? isUploadingPhoto,
    Object? photoVersion = _unset,
  }) {
    return EditProfilePageState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      hasChanges: hasChanges ?? this.hasChanges,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      tnbAccountNo: tnbAccountNo ?? this.tnbAccountNo,
      fullNameError: identical(fullNameError, _unset)
          ? this.fullNameError
          : fullNameError as String?,
      tnbAccountError: identical(tnbAccountError, _unset)
          ? this.tnbAccountError
          : tnbAccountError as String?,
      successMessage: identical(successMessage, _unset)
          ? this.successMessage
          : successMessage as String?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      photoUrl: identical(photoUrl, _unset)
          ? this.photoUrl
          : photoUrl as String?,
      localPhotoFile: identical(localPhotoFile, _unset)
          ? this.localPhotoFile
          : localPhotoFile as XFile?,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      photoVersion: identical(photoVersion, _unset)
          ? this.photoVersion
          : photoVersion as int?,
    );
  }
}
