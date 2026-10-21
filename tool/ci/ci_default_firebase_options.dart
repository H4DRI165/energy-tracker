import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => const FirebaseOptions(
    apiKey: 'ci-placeholder',
    appId: 'ci-placeholder',
    messagingSenderId: 'ci-placeholder',
    projectId: 'ci-placeholder',
  );
}
