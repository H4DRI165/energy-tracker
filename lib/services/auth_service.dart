import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:energy_tracker/models/user_profile.dart';
import 'package:energy_tracker/services/app_user_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  factory AuthService() => _instance;
  AuthService._internal() {
    _auth.authStateChanges().listen((user) {
      unawaited(_syncOnboardingListener(user));
    });
  }

  int _authSyncEpoch = 0;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;
  static final AuthService _instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final AppUserNotifier userNotifier = AppUserNotifier();

  final _uidController = StreamController<String?>.broadcast();
  String? _lastUid;
  bool _uidInitialized = false;

  /// Emits the current uid immediately to new listeners, then future changes.
  Stream<String?> get uidChanges async* {
    if (_uidInitialized) yield _lastUid;
    yield* _uidController.stream;
  }

  void _emitUid(String? uid) {
    _lastUid = uid;
    _uidInitialized = true;
    _uidController.add(uid);
  }

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
    _userDocSubscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (doc) {
            if (_auth.currentUser?.uid != uid) return;
            _applyUserDoc(doc);
          },
          onError: (_) {
            if (_auth.currentUser?.uid == uid) userNotifier.setError();
          },
        );
  }

  Future<void> _syncOnboardingListener(User? user) async {
    final epoch = ++_authSyncEpoch;
    await _userDocSubscription?.cancel();
    _userDocSubscription = null;

    if (user == null) {
      if (epoch == _authSyncEpoch) {
        userNotifier.reset();
        _emitUid(null);
      }
      return;
    }
    if (epoch != _authSyncEpoch) return;

    // Emit uid as soon as we know it, epoch-guarded flow as the profile fetch.
    _emitUid(user.uid);

    final uid = user.uid;
    final sub = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (doc) {
            if (epoch != _authSyncEpoch || _auth.currentUser?.uid != uid) {
              return;
            }
            _applyUserDoc(doc);
          },
          onError: (_) {
            if (epoch == _authSyncEpoch && _auth.currentUser?.uid == uid) {
              userNotifier.setError();
            }
          },
        );

    if (epoch != _authSyncEpoch) {
      await sub.cancel();
      return;
    }
    _userDocSubscription = sub;
  }

  void _applyUserDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      userNotifier.setIncomplete();
      return;
    }
    userNotifier.setProfile(UserProfile.fromDoc(data));
  }

  void dispose() {
    unawaited(_uidController.close());
  }
}
