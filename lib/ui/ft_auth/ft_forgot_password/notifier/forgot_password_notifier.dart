import 'package:energy_tracker/ui/components/utils/logger.dart';
import 'package:energy_tracker/ui/ft_auth/ft_forgot_password/notifier/forgot_password_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<ForgotPasswordNotifier, ForgotPasswordPageState>
    forgotPasswordProvider = NotifierProvider.autoDispose<
        ForgotPasswordNotifier, ForgotPasswordPageState>(
  ForgotPasswordNotifier.new,
);

class ForgotPasswordNotifier extends Notifier<ForgotPasswordPageState> {
  FirebaseAuth get _auth => FirebaseAuth.instance;

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
    } on FirebaseAuthException catch (e) {
      if (!ref.mounted) return;

      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapError(e.code),
      );
    } on Exception catch (e, stack) {
      AppLogger.error('Forgot Password error: ', e, stack);

      if (!ref.mounted) return;

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
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
}
