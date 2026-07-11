import 'package:energy_tracker/services/auth/auth_service.dart';
import 'package:energy_tracker/ui/components/utils/logger.dart';
import 'package:energy_tracker/ui/ft_auth/ft_login/notifier/login_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<LoginNotifier, LoginPageState> loginProvider =
    NotifierProvider.autoDispose<LoginNotifier, LoginPageState>(
  LoginNotifier.new,
);

class LoginNotifier extends Notifier<LoginPageState> {
  AuthService get _authService => AuthService();

  @override
  LoginPageState build() => const LoginPageState();

  void setEmail(String value) {
    state = state.copyWith(email: value, emailError: null);
  }

  void setPassword(String value) {
    state = state.copyWith(password: value, passwordError: null);
  }

  void toggleObscure() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  Future<void> login() async {
    if (state.isLoading) return;

    if (!_validate()) return;

    state = state.copyWith(isLoading: true, authError: null);

    try {
      await _authService.signInWithEmail(state.email, state.password);
    } on FirebaseAuthException catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          authError: _mapAuthError(e.code),
        );
      }
    } on Exception catch (e, stack) {
      AppLogger.error('Sign-In error: ', e, stack);

      if (ref.mounted) {
        state = state.copyWith(
          authError: 'Something went wrong. Please try again.',
        );
      }
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> loginWithGoogle() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, authError: null);

    try {
      await _authService.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        authError: _mapAuthError(e.code),
      );
    } on Exception catch (e, stack) {
      AppLogger.error('Google Sign-In failed: ', e, stack);

      state = state.copyWith(
        authError: 'Failed to sign in with Google. Please try again.',
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  bool _validate() {
    String? emailError;
    String? passwordError;

    if (state.email.isEmpty) emailError = 'Email is required';
    if (state.password.isEmpty) passwordError = 'Password is required';

    state = state.copyWith(
      emailError: emailError,
      passwordError: passwordError,
    );

    return emailError == null && passwordError == null;
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
}
