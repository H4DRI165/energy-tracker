import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/theme/app_colors.dart';
import 'package:energy_tracker/ui/ft_auth/ft_register/notifier/register_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterNotifier extends ChangeNotifier {
  RegisterNotifier({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  RegisterPageState _state = RegisterPageState();
  RegisterPageState get state => _state;

  void setFullName(String fullName) {
    _state = _state.copyWith(fullName: fullName);
    notifyListeners();
  }

  void setEmail(String value) {
    _state = _state.copyWith(email: value, emailError: null);
    notifyListeners();
  }

  void setTnbAccount(String tnbAccount) {
    _state = _state.copyWith(tnbAccount: tnbAccount, tnbAccountError: null);
    notifyListeners();
  }

  void setPassword(String password) {
    _state = _state.copyWith(password: password, passwordError: null);
    _evaluatePasswordStrength(password);
    _validateConfirmPassword();
    notifyListeners();
  }

  void setConfirmedPassword(String confirmedPassword) {
    _state = _state.copyWith(
      confirmedPassword: confirmedPassword,
      confirmedPasswordError: null,
    );
    _validateConfirmPassword();
    notifyListeners();
  }

  void _evaluatePasswordStrength(String password) {
    if (password.isEmpty) {
      _state = _state.copyWith(
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

    _state = _state.copyWith(
      passwordStrength: score,
      strengthLabel: label,
      strengthColor: color,
    );
  }

  void _validateConfirmPassword() {
    final password = _state.password;
    final confirm = _state.confirmedPassword;

    String? error;
    if (confirm.isNotEmpty && password != confirm) {
      error = 'Passwords do not match';
    }

    _state = _state.copyWith(confirmedPasswordError: error);
  }

  void toggleObscurePassword() {
    _state = _state.copyWith(obscurePassword: !_state.obscurePassword);
    notifyListeners();
  }

  void toggleObscureConfirmedPassword() {
    _state = _state.copyWith(
      obscureConfirmedPassword: !_state.obscureConfirmedPassword,
    );
    notifyListeners();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> register() async {
    _state = _state.copyWith(
      fullNameError: null,
      emailError: null,
      tnbAccountError: null,
      passwordError: null,
      confirmedPasswordError: null,
      authError: null,
    );
    notifyListeners();

    var hasError = false;

    if (_state.fullName.trim().isEmpty) {
      _state = _state.copyWith(fullNameError: 'Full name is required');
      hasError = true;
    }
    if (_state.email.trim().isEmpty || !_isValidEmail(_state.email)) {
      _state = _state.copyWith(emailError: 'Valid email is required');
      hasError = true;
    }
    if (_state.tnbAccount.trim().isEmpty) {
      _state =
          _state.copyWith(tnbAccountError: 'TNB Account Number is required');
      hasError = true;
    }
    if (_state.password.isEmpty || _state.password.length < 8) {
      _state = _state.copyWith(
        passwordError: 'Password must be at least 8 characters',
      );
      hasError = true;
    }
    if (_state.confirmedPassword != _state.password) {
      _state =
          _state.copyWith(confirmedPasswordError: 'Passwords do not match');
      hasError = true;
    }

    if (hasError) {
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _state.email.trim(),
        password: _state.password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Registration failed. Please try again.');
      }

      await user.updateDisplayName(_state.fullName.trim());
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': _state.fullName.trim(),
        'email': _state.email.trim(),
        'tnbAccountNo': _state.tnbAccount.trim(),
        'tariffType': 'domestic',
        'monthlyBudget': 150.0,
        'onboardingCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'photoURL': null,
        'isGuest': false,
      });

      // TODO(dev): enable when want to test email verification flow
      // await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      _state = _state.copyWith(authError: _getFirebaseErrorMessage(e.code));
    } catch (e) {
      _state = _state.copyWith(authError: e.toString());
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
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
