import 'package:energy_tracker/services/auth/auth_service.dart';
import 'package:energy_tracker/ui/components/logging/app_logger.dart';
import 'package:energy_tracker/ui/components/logging/notifier/loggable_notifier.dart';
import 'package:energy_tracker/ui/ft_auth/ft_login/notifier/login_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<LoginNotifier, LoginPageState> loginProvider =
    NotifierProvider.autoDispose<LoginNotifier, LoginPageState>(
      LoginNotifier.new,
    );

class LoginNotifier extends Notifier<LoginPageState>
    with LoggableNotifier<LoginPageState> {
  AuthService get _authService => AuthService();

  @override
  String get screenName => 'LoginPage';

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
    } on FirebaseAuthException catch (e, st) {
      const expectedCodes = {
        'wrong-password',
        'user-not-found',
        'invalid-credential',
      };

      if (!expectedCodes.contains(e.code)) {
        logError('Failed to sign in (Firebase Auth)', e, st);
      }

      if (ref.mounted) {
        state = state.copyWith(authError: mapFirebaseAuthError(e.code));
      }
    } on Exception catch (e, st) {
      logError('Failed to sign in', e, st);

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
    } on FirebaseAuthException catch (e, st) {
      logError(
        'Failed to sign in with Google (Firebase Auth)',
        e,
        st,
      );

      if (ref.mounted) {
        state = state.copyWith(authError: mapFirebaseAuthError(e.code));
      }
    } on Exception catch (e, st) {
      logError('Failed to sign in with Google', e, st);

      if (ref.mounted) {
        state = state.copyWith(
          authError: 'Failed to sign in with Google. Please try again.',
        );
      }
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isLoading: false);
      }
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
}
