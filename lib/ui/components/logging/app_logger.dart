import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  static void error(
    String message,
    Object? error,
    StackTrace? stack, {
    Map<String, Object?>? keys,
  }) {
    final safeKeys = _sanitize(keys);

    if (kDebugMode) {
      debugPrint('❌ $message');
      if (error != null) debugPrint('   Error: $error');
      if (keys != null) debugPrint('   Keys: $keys → sanitized: $safeKeys');
    }

    unawaited(_recordError(message, error, stack, safeKeys));
  }

  /// Only String/int/double/bool survive. Anything else is dropped
  /// with a debug warning instead of silently failing setCustomKey.
  static Map<String, Object> _sanitize(Map<String, Object?>? keys) {
    if (keys == null) return {};
    final result = <String, Object>{};
    for (final entry in keys.entries) {
      final v = entry.value;
      if (v == null) continue;
      if (v is String || v is int || v is double || v is bool) {
        result[entry.key] = v;
      } else if (kDebugMode) {
        debugPrint(
          '⚠️ AppLogger: dropped key "${entry.key}" — '
          'unsupported type ${v.runtimeType}. Convert to String/num/bool.',
        );
      }
    }
    return result;
  }

  static Future<void> _recordError(
    String message,
    Object? error,
    StackTrace? stack,
    Map<String, Object> keys,
  ) async {
    try {
      // Reset well-known keys to avoid stale values from prior reports.
      await FirebaseCrashlytics.instance.setCustomKey('firebase_code', '');
      await FirebaseCrashlytics.instance.setCustomKey('firebase_auth_code', '');
      await FirebaseCrashlytics.instance.setCustomKey('screen', '');
      await FirebaseCrashlytics.instance.setCustomKey('uid', '');

      for (final entry in keys.entries) {
        await FirebaseCrashlytics.instance.setCustomKey(entry.key, entry.value);
      }
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: message,
      );
    } on Exception catch (loggingError, loggingStack) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ AppLogger failed to record: $loggingError\n$loggingStack',
        );
      }
    }
  }
}

String mapFirebaseError(String code) {
  switch (code) {
    case 'permission-denied':
      return 'Permission denied. Please check your account.';
    case 'network-request-failed':
    case 'unavailable':
      return 'No internet connection. Please check your network.';
    case 'not-found':
      return 'This record no longer exists.';
    case 'deadline-exceeded':
      return 'Request timed out. Please try again.';
    default:
      return 'Something went wrong. Please try again.';
  }
}

String mapFirebaseAuthError(String code) {
  switch (code) {
    case 'user-not-found':
      return 'No account found with this email.';
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    case 'network-request-failed':
      return 'No internet connection. Please check your network.';
    case 'wrong-password':
    case 'invalid-credential':
      return 'Incorrect email or password.';
    case 'email-already-in-use':
      return 'An account already exists with this email.';
    case 'weak-password':
      return 'Password is too weak. Please use a stronger password.';
    case 'operation-not-allowed':
      return 'This sign-in method is not enabled.';
    case 'expired-action-code':
      return 'This link has expired. Please request a new one.';
    case 'invalid-action-code':
      return 'This link is invalid. Please request a new one.';
    default:
      return 'Something went wrong. Please try again.';
  }
}
