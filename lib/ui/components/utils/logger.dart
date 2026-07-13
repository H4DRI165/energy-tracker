import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  static void error(String message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('❌ $message');
      if (error != null) debugPrint('   Error: $error');
      if (stack != null) debugPrint('   Stack: $stack');
    }
    unawaited(
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: message,
      ),
    );
  }
}
