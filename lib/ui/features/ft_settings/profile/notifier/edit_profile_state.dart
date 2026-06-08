class EditProfilePageState {
  const EditProfilePageState({
    this.isLoading = true,
    this.isSaving = false,
    this.fullName = '',
    this.email = '',
    this.tnbAccountNo = '',
    this.fullNameError,
    this.tnbAccountError,
    this.successMessage,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final String fullName;
  final String email;
  final String tnbAccountNo;
  final String? fullNameError;
  final String? tnbAccountError;
  final String? successMessage;
  final String? errorMessage;
  static const Object _unset = Object();

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  bool get hasChanges => fullName.isNotEmpty || tnbAccountNo.isNotEmpty;

  EditProfilePageState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? fullName,
    String? email,
    String? tnbAccountNo,
    Object? fullNameError = _unset,
    Object? tnbAccountError = _unset,
    Object? successMessage = _unset,
    Object? errorMessage = _unset,
  }) {
    return EditProfilePageState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
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
    );
  }
}
