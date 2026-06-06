import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/services/app_user_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  factory AuthService() => _instance;
  AuthService._internal() {
    _auth.authStateChanges().listen((user) async {
      if (user == null) {
        userNotifier.reset();
        _userDocSubscription?.cancel(); // ← cancel previous listener
        return;
      }

      final uid = user.uid;

      // Cancel any previous subscription first
      await _userDocSubscription?.cancel();

      // Real-time listener — fires immediately + on every change
      _userDocSubscription =
          _firestore.collection('users').doc(uid).snapshots().listen(
        (doc) {
          if (_auth.currentUser?.uid != uid) return;
          final raw = doc.data()?['onboardingCompleted'];
          if (raw is bool && raw) {
            userNotifier.setComplete();
          } else {
            userNotifier.setIncomplete();
          }
        },
        onError: (_) {
          if (_auth.currentUser?.uid == uid) {
            userNotifier.setError();
          }
        },
      );
    });
  }

  StreamSubscription<DocumentSnapshot>? _userDocSubscription;
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

  Future<void> retryLoadUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    userNotifier.reset();
    await _userDocSubscription?.cancel();

    final uid = user.uid;
    _userDocSubscription =
        _firestore.collection('users').doc(uid).snapshots().listen(
      (doc) {
        final raw = doc.data()?['onboardingCompleted'];
        if (raw is bool && raw) {
          userNotifier.setComplete();
        } else {
          userNotifier.setIncomplete();
        }
      },
      onError: (_) => userNotifier.setError(),
    );
  }
}
