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

  LoginPageState copyWith({
    String? email,
    String? password,
    bool? obscurePassword,
    bool? isLoading,
    String? emailError,
    String? passwordError,
  }) {
    return LoginPageState(
      email: email ?? this.email,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isLoading: isLoading ?? this.isLoading,
      emailError: emailError,
      passwordError: passwordError,
    );
  }
}
