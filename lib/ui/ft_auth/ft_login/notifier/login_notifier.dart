import 'package:energy_tracker/services/auth_service.dart';
import 'package:energy_tracker/ui/ft_auth/ft_login/notifier/login_state.dart';
import 'package:flutter/material.dart';

class LoginNotifier extends ChangeNotifier {
  LoginPageState _state = const LoginPageState();
  LoginPageState get state => _state;

  final _authService = AuthService();

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
    if (_state.isLoading) return;

    if (!_validate()) return;

    _state = _state.copyWith(isLoading: true, authError: null);
    notifyListeners();

    try {
      await _authService.signInWithEmail(_state.email, _state.password);
    } catch (e) {
      _state = _state.copyWith(authError: e.toString());
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle() async {
    if (_state.isLoading) return;

    _state = _state.copyWith(isLoading: true, authError: null);
    notifyListeners();

    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      _state = _state.copyWith(authError: e.toString());
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
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
