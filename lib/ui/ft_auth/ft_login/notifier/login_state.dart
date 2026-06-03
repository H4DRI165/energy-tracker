class LoginPageState {
  const LoginPageState({
    this.email = '',
    this.password = '',
    this.obscurePassword = true,
    this.isLoading = false,
    this.emailError,
    this.passwordError,
  });

  final String email;
  final String password;
  final bool obscurePassword;
  final bool isLoading;
  final String? emailError;
  final String? passwordError;
  static const Object _unset = Object();

  LoginPageState copyWith({
    String? email,
    String? password,
    bool? obscurePassword,
    bool? isLoading,
    Object? emailError = _unset,
    Object? passwordError = _unset,
  }) {
    return LoginPageState(
      email: email ?? this.email,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isLoading: isLoading ?? this.isLoading,
      emailError: identical(emailError, _unset)
          ? this.emailError
          : emailError as String?,
      passwordError: identical(passwordError, _unset)
          ? this.passwordError
          : passwordError as String?,
    );
  }
}
