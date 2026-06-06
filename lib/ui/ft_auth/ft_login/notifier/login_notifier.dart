import 'package:energy_tracker/services/auth_service.dart';
import 'package:energy_tracker/ui/components/logger.dart';
import 'package:energy_tracker/ui/ft_auth/ft_login/notifier/login_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
    } on FirebaseAuthException catch (e) {
      _state = _state.copyWith(
        authError: _mapAuthError(e.code),
      );
    } on Exception catch (e, stack) {
      AppLogger.error('Sign-In error: ', e, stack);

      _state = _state.copyWith(
        authError: 'Something went wrong. Please try again.',
      );
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
    } on FirebaseAuthException catch (e) {
      _state = _state.copyWith(
        authError: _mapAuthError(e.code),
      );
    } on Exception catch (e, stack) {
      AppLogger.error('Google Sign-In failed: ', e, stack);

      _state = _state.copyWith(
        authError: 'Failed to sign in with Google. Please try again.',
      );
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email '
            'but different sign-in method.';
      default:
        return 'Login failed. Please try again.';
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
