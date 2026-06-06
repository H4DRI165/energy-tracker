import 'package:energy_tracker/ui/components/logger.dart';
import 'package:energy_tracker/ui/ft_auth/ft_forgot_password/notifier/forgot_password_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordNotifier extends ChangeNotifier {
  ForgotPasswordNotifier({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  bool _disposed = false;

  ForgotPasswordPageState _state = const ForgotPasswordPageState();
  ForgotPasswordPageState get state => _state;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void setEmail(String value) {
    _state = _state.copyWith(email: value, emailError: null);
    _notify();
  }

  Future<void> sendResetEmail() async {
    if (_state.isLoading) return;

    _state = _state.copyWith(emailError: null, errorMessage: null);
    _notify();

    final email = _state.email.trim();
    if (email.isEmpty) {
      _state = _state.copyWith(emailError: 'Email address is required');
      _notify();
      return;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      _state =
          _state.copyWith(emailError: 'Please enter a valid email address');
      _notify();
      return;
    }

    _state = _state.copyWith(isLoading: true);
    _notify();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _state = _state.copyWith(
        isLoading: false,
        step: ForgotPasswordStep.emailSent,
      );
    } on FirebaseAuthException catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: _mapError(e.code),
      );
    } on Exception catch (e, stack) {
      AppLogger.error('Forgot Password error: ', e, stack);

      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
    _notify();
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Failed to send reset email. Please try again.';
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
