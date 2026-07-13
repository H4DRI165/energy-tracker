import 'package:energy_tracker/services/auth/providers/current_uid_provider.dart';
import 'package:energy_tracker/ui/components/logging/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin LoggableNotifier<T> {
  String get screenName;
  Ref get ref;

  void logError(
    String message,
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?>? context,
  }) {
    String? uid;
    if (ref.mounted) {
      uid = ref.read(currentUidProvider).value;
    }

    AppLogger.error(
      message,
      error,
      stackTrace,
      keys: {
        'screen': screenName,
        'uid': ?uid,
        if (error is FirebaseAuthException)
          'firebase_auth_code': error.code
        else if (error is FirebaseException)
          'firebase_code': error.code,
        ...?context,
      },
    );
  }
}
