import 'package:energy_tracker/ui/ft_auth/ft_login/notifier/login_state.dart';
import 'package:flutter/material.dart';

class LoginNotifier extends ChangeNotifier {
  LoginPageState _state = const LoginPageState();
  LoginPageState get state => _state;

  void setEmail(String value) {
    _state = _state.copyWith(email: value, emailError: null);
    notifyListeners();
  }

  void setPassword(String value) {
    _state = _state.copyWith(password: value, passwordError: null);
    notifyListeners();
  }

  void toggleObscure() {
    _state = _state.copyWith(obscurePassword: !_state.obscurePassword);
    notifyListeners();
  }

  Future<void> login() async {
    if (!_validate()) return;
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    // TODO: wire auth
    await Future.delayed(const Duration(milliseconds: 1500));

    _state = _state.copyWith(isLoading: false);
    notifyListeners();
  }

  bool _validate() {
    String? emailError;
    String? passwordError;

    if (_state.email.isEmpty) emailError = 'Email is required';
    if (_state.password.isEmpty) passwordError = 'Password is required';

    _state = _state.copyWith(
      emailError: emailError,
      passwordError: passwordError,
    );
    notifyListeners();
    return emailError == null && passwordError == null;
  }
}
