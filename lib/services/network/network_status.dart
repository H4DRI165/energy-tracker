import 'dart:io';

abstract final class NetworkStatus {
  static const Duration _lookupTimeout = Duration(seconds: 4);

  /// A lightweight reachability check before starting a Firestore write.
  /// Firestore queues offline writes, which can leave a save spinner waiting
  /// indefinitely. Failing fast gives the user a clear message instead.
  static Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup(
        'firebase.google.com',
      ).timeout(_lookupTimeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on Exception {
      return false;
    }
  }
}
