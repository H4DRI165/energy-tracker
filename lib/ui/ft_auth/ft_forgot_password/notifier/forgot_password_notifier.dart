import 'package:energy_tracker/ui/components/logging/app_logger.dart';
import 'package:energy_tracker/ui/components/logging/notifier/loggable_notifier.dart';
import 'package:energy_tracker/ui/ft_auth/ft_forgot_password/notifier/forgot_password_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<ForgotPasswordNotifier, ForgotPasswordPageState>
forgotPasswordProvider =
    NotifierProvider.autoDispose<
      ForgotPasswordNotifier,
      ForgotPasswordPageState
    >(
      ForgotPasswordNotifier.new,
    );

class ForgotPasswordNotifier extends Notifier<ForgotPasswordPageState>
    with LoggableNotifier<ForgotPasswordPageState> {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  String get screenName => 'ForgotPasswordPage';

  @override
  ForgotPasswordPageState build() => const ForgotPasswordPageState();

  void setEmail(String value) {
    state = state.copyWith(email: value, emailError: null, errorMessage: null);
  }

  Future<void> sendResetEmail() async {
    if (state.isLoading) return;

    state = state.copyWith(emailError: null, errorMessage: null);

    final email = state.email.trim();

    if (email.isEmpty) {
      state = state.copyWith(emailError: 'Email address is required');

      return;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      state = state.copyWith(emailError: 'Please enter a valid email address');

      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (!ref.mounted) return;

      state = state.copyWith(
        isLoading: false,
        step: ForgotPasswordStep.emailSent,
      );
    } on FirebaseAuthException catch (e, st) {
      logError('Failed to send reset email (Firebase Auth)', e, st);

      if (!ref.mounted) return;

      state = state.copyWith(
        isLoading: false,
        errorMessage: mapFirebaseAuthError(e.code),
      );
    } on Exception catch (e, st) {
      logError(
        'Failed to send reset email',
        e,
        st,
      );

      if (!ref.mounted) return;

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }
}
