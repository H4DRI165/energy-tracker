import 'dart:ui';

class RegisterPageState {
  RegisterPageState({
    this.fullName = '',
    this.email = '',
    this.tnbAccount = '',
    this.password = '',
    this.passwordStrength = 0,
    this.strengthLabel = '',
    this.strengthColor,
    this.confirmedPassword = '',
    this.obscurePassword = true,
    this.obscureConfirmedPassword = true,
    this.isLoading = false,
    this.fullNameError,
    this.emailError,
    this.tnbAccountError,
    this.passwordError,
    this.confirmedPasswordError,
    this.authError,
  });

  final String fullName;
  final String email;
  final String tnbAccount;
  final String password;
  final int passwordStrength;
  final String strengthLabel;
  final Color? strengthColor;
  final String confirmedPassword;
  final bool obscurePassword;
  final bool obscureConfirmedPassword;
  final bool isLoading;
  final String? fullNameError;
  final String? emailError;
  final String? tnbAccountError;
  final String? passwordError;
  final String? confirmedPasswordError;
  final String? authError;

  static const Object _unset = Object();

  RegisterPageState copyWith({
    String? fullName,
    String? email,
    String? tnbAccount,
    String? password,
    int? passwordStrength,
    String? strengthLabel,
    Color? strengthColor,
    String? confirmedPassword,
    bool? obscurePassword,
    bool? obscureConfirmedPassword,
    bool? isLoading,
    Object? fullNameError = _unset,
    Object? emailError = _unset,
    Object? tnbAccountError = _unset,
    Object? passwordError = _unset,
    Object? confirmedPasswordError = _unset,
    Object? authError = _unset,
  }) {
    return RegisterPageState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      tnbAccount: tnbAccount ?? this.tnbAccount,
      password: password ?? this.password,
      passwordStrength: passwordStrength ?? this.passwordStrength,
      strengthLabel: strengthLabel ?? this.strengthLabel,
      strengthColor: strengthColor ?? this.strengthColor,
      confirmedPassword: confirmedPassword ?? this.confirmedPassword,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmedPassword:
          obscureConfirmedPassword ?? this.obscureConfirmedPassword,
      isLoading: isLoading ?? this.isLoading,
      fullNameError: identical(fullNameError, _unset)
          ? this.fullNameError
          : fullNameError as String?,
      emailError: identical(emailError, _unset)
          ? this.emailError
          : emailError as String?,
      tnbAccountError: identical(tnbAccountError, _unset)
          ? this.tnbAccountError
          : tnbAccountError as String?,
      passwordError: identical(passwordError, _unset)
          ? this.passwordError
          : passwordError as String?,
      confirmedPasswordError: identical(confirmedPasswordError, _unset)
          ? this.confirmedPasswordError
          : confirmedPasswordError as String?,
      authError:
          identical(authError, _unset) ? this.authError : authError as String?,
    );
  }
}
