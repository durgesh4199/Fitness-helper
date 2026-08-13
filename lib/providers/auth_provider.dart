import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// A plain, user-presentable error from any auth operation — callers never
/// need to interpret FirebaseAuthException codes themselves.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

/// Wraps Firebase Authentication (email/password + Google). [auth] is
/// injectable so tests can pass a MockFirebaseAuth instead of talking to a
/// real backend/platform channel.
///
/// Firebase requires a real `google-services.json` (see
/// docs/FIREBASE_SETUP.md) to initialize at all. Rather than making every
/// screen in the app conditional on whether that's present, this provider
/// swallows the "Firebase not initialized" failure itself: [isAvailable]
/// reports false, [isSignedIn] stays false, and every action throws a plain
/// [AuthException] instead of crashing — so the rest of the app (and the
/// existing widget tests, which never initialize Firebase) keeps working
/// exactly as it did before sign-in existed.
class AppAuthProvider extends ChangeNotifier {
  AppAuthProvider({FirebaseAuth? auth}) {
    try {
      _auth = auth ?? FirebaseAuth.instance;
      final auth0 = _auth!;
      _user = auth0.currentUser;
      _authSub = auth0.authStateChanges().listen((user) {
        _user = user;
        notifyListeners();
      });
    } catch (_) {
      _auth = null;
    }
  }

  FirebaseAuth? _auth;
  StreamSubscription<User?>? _authSub;
  User? _user;
  bool _googleInitialized = false;

  bool get isAvailable => _auth != null;
  User? get user => _user;
  bool get isSignedIn => _user != null;
  String? get email => _user?.email;
  String? get displayName => _user?.displayName;

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  FirebaseAuth _requireAuth() {
    final auth = _auth;
    if (auth == null) {
      throw const AuthException('Cloud sign-in isn\'t set up for this build yet.');
    }
    return auth;
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await _requireAuth().createUserWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _requireAuth().signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _requireAuth().sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  /// Google Sign-In additionally requires the Google provider to be enabled
  /// in the Firebase console — see docs/FIREBASE_SETUP.md. Without it this
  /// throws a clear [AuthException] instead of crashing.
  Future<void> signInWithGoogle() async {
    final auth = _requireAuth();
    try {
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize();
        _googleInitialized = true;
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('Google sign-in didn\'t return a token. Please try again.');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      // A user backing out of the picker isn't an error worth surfacing.
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      throw AuthException('Google sign-in failed: ${e.description ?? e.code}');
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  Future<void> signOut() async {
    await _requireAuth().signOut();
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Not signed in with Google this session — fine to ignore.
      }
    }
  }

  String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address doesn\'t look right.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a bit and try again.';
      case 'network-request-failed':
        return 'Network error — check your connection and try again.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
