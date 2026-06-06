import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/services/app_user_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  factory AuthService() => _instance;
  AuthService._internal() {
    // Listen to auth changes and sync onboarding state
    _auth.authStateChanges().listen((user) async {
      if (user == null) {
        userNotifier.reset();
        return;
      }

      final uid = user.uid;
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (_auth.currentUser?.uid != uid) return;

        final raw = doc.data()?['onboardingCompleted'];
        userNotifier.setOnboardingCompleted(value: raw is bool && raw);
      } on Exception catch (_) {
        if (_auth.currentUser?.uid == uid) {
          userNotifier.setOnboardingCompleted(value: false);
        }
      }
    });
  }

  static final AuthService _instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final AppUserNotifier userNotifier = AppUserNotifier();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } finally {
      await _auth.signOut();
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
