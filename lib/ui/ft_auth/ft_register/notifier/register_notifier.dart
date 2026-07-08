import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/theme/app_colors.dart';
import 'package:energy_tracker/ui/components/logger.dart';
import 'package:energy_tracker/ui/ft_auth/ft_register/notifier/register_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<RegisterNotifier, RegisterPageState> registerProvider =
    NotifierProvider.autoDispose<RegisterNotifier, RegisterPageState>(
      RegisterNotifier.new,
    );

class RegisterNotifier extends Notifier<RegisterPageState> {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  RegisterPageState build() => RegisterPageState();

  void setFullName(String fullName) {
    state = state.copyWith(fullName: fullName, fullNameError: null);
  }

  void setEmail(String value) {
    state = state.copyWith(email: value, emailError: null);
  }

  void setTnbAccount(String tnbAccount) {
    state = state.copyWith(tnbAccount: tnbAccount, tnbAccountError: null);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password, passwordError: null);
    _evaluatePasswordStrength(password);
    _validateConfirmPassword();
  }

  void setConfirmedPassword(String confirmedPassword) {
    state = state.copyWith(
      confirmedPassword: confirmedPassword,
      confirmedPasswordError: null,
    );
    _validateConfirmPassword();
  }

  void _validateConfirmPassword() {
    final password = state.password;
    final confirm = state.confirmedPassword;

    String? error;
    if (confirm.isNotEmpty && password != confirm) {
      error = 'Passwords do not match';
    }

    state = state.copyWith(confirmedPasswordError: error);
  }

  void toggleObscurePassword() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void toggleObscureConfirmedPassword() {
    state = state.copyWith(
      obscureConfirmedPassword: !state.obscureConfirmedPassword,
    );
  }

  void _evaluatePasswordStrength(String password) {
    if (password.isEmpty) {
      state = state.copyWith(
        passwordStrength: 0,
        strengthLabel: '',
        strengthColor: AppColors.text3,
      );
      return;
    }

    var score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp('[A-Z]'))) score++;
    if (password.contains(RegExp('[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$&*~%^()]'))) score++;

    String label;
    Color color;
    switch (score) {
      case 0:
      case 1:
        label = 'Too weak';
        color = AppColors.danger;
      case 2:
        label = 'Fair — add numbers & symbols';
        color = AppColors.warn;
      case 3:
        label = 'Good';
        color = AppColors.accent2;
      default:
        label = 'Strong';
        color = AppColors.accent;
    }

    state = state.copyWith(
      passwordStrength: score,
      strengthLabel: label,
      strengthColor: color,
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> register() async {
    state = state.copyWith(
      fullNameError: null,
      emailError: null,
      tnbAccountError: null,
      passwordError: null,
      confirmedPasswordError: null,
      authError: null,
    );

    var hasError = false;

    if (state.fullName.trim().isEmpty) {
      state = state.copyWith(fullNameError: 'Full name is required');
      hasError = true;
    } else if (state.fullName.trim().length < 2) {
      state = state.copyWith(fullNameError: 'Name is too short');
      hasError = true;
    }

    if (state.email.trim().isEmpty || !_isValidEmail(state.email)) {
      state = state.copyWith(emailError: 'Valid email is required');
      hasError = true;
    }
    final tnbAccount = state.tnbAccount.trim();
    if (tnbAccount.length != 12) {
      state = state.copyWith(
        tnbAccountError: 'TNB Account Number must be exactly 12 digits',
      );
      hasError = true;
    }
    if (state.password.isEmpty || state.password.length < 8) {
      state = state.copyWith(
        passwordError: 'Password must be at least 8 characters',
      );
      hasError = true;
    }
    if (state.confirmedPassword != state.password) {
      state = state.copyWith(confirmedPasswordError: 'Passwords do not match');
      hasError = true;
    }

    if (hasError) {
      return;
    }

    state = state.copyWith(isLoading: true);

    var shouldRollback = false;
    var userDocWritten = false;
    User? createdUser;
    try {
      final fullName = state.fullName.trim();
      final email = state.email.trim();
      final tnbAccount = state.tnbAccount.trim();
      final password = state.password;

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Registration failed. Please try again.');
      }
      createdUser = user;
      shouldRollback = true;

      await user.updateDisplayName(fullName);
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': fullName,
        'email': email,
        'tnbAccountNo': tnbAccount,
        'tariffType': 'domestic',
        'monthlyBudget': 150.0,
        'onboardingCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'photoURL': null,
        'isGuest': false,
      });
      userDocWritten = true;
      shouldRollback = false;

      // TODO(dev): enable when want to test email verification flow
      // await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          authError: _getFirebaseErrorMessage(e.code),
        );
      }
    } on Exception catch (e, stack) {
      AppLogger.error('Registration error: ', e, stack);

      if (ref.mounted) {
        state = state.copyWith(
          authError: 'Registration failed. Please try again.',
        );
      }
    } finally {
      if (shouldRollback && createdUser != null) {
        if (userDocWritten) {
          await _firestore.collection('users').doc(createdUser.uid).delete();
        }
        try {
          await createdUser.delete();
        } on Exception catch (_) {}
        await _auth.signOut();
      }

      if (ref.mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email registration is not enabled. Please contact support.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Registration failed. Please try again.';
    }
  }
}
