enum ForgotPasswordStep {
  enterEmail,
  emailSent,
}

class ForgotPasswordPageState {
  const ForgotPasswordPageState({
    this.step = ForgotPasswordStep.enterEmail,
    this.email = '',
    this.emailError,
    this.isLoading = false,
    this.errorMessage,
  });

  final ForgotPasswordStep step;
  final String email;
  final String? emailError;
  final bool isLoading;
  final String? errorMessage;

  bool get isEmailSent => step == ForgotPasswordStep.emailSent;

  static const Object _unset = Object();

  ForgotPasswordPageState copyWith({
    ForgotPasswordStep? step,
    String? email,
    bool? isLoading,
    Object? emailError = _unset,
    Object? errorMessage = _unset,
  }) {
    return ForgotPasswordPageState(
      step: step ?? this.step,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      emailError: identical(emailError, _unset)
          ? this.emailError
          : emailError as String?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
