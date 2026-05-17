import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Raw Firebase Auth instance ──────────────────────────────────
final firebaseAuthProvider = Provider<FirebaseAuth>(
      (_) => FirebaseAuth.instance,
);

// ── Stream of auth state (User? = null when signed out) ─────────
// Used by widgets that need to reactively rebuild on sign-in / out.
final authStateStreamProvider = StreamProvider<User?>(
      (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);

// ── Convenience: current user (non-reactive snapshot) ───────────
final currentUserProvider = Provider<User?>(
      (ref) => ref.watch(authStateStreamProvider).valueOrNull,
);

// ── ChangeNotifier wrapper ───────────────────────────────────────
// GoRouter requires a Listenable for refreshListenable.
// This notifier listens to Firebase and calls notifyListeners()
// so GoRouter re-evaluates its redirect() on every auth change.
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier(FirebaseAuth auth) {
    _sub = auth.authStateChanges().listen((user) {
      _isSignedIn = user != null;
      notifyListeners();
    });
  }

  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;

  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final authChangeNotifierProvider = ChangeNotifierProvider<AuthChangeNotifier>(
      (ref) => AuthChangeNotifier(ref.watch(firebaseAuthProvider)),
);

// ── AuthService ─────────────────────────────────────────────────
// Encapsulates all Firebase Auth operations (Clean Architecture:
// this lives in the Data layer, consumed by the Presentation layer).
class AuthService {
  const AuthService(this._auth);
  final FirebaseAuth _auth;

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);

  Future<void> register(String email, String password) =>
      _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);

  Future<void> signOut() => _auth.signOut();

  // Maps FirebaseAuthException codes → user-friendly strings
  static String friendlyError(String code) => switch (code) {
    'user-not-found'      => 'No account found with this email.',
    'wrong-password'      => 'Incorrect email or password.',
    'invalid-credential'  => 'Incorrect email or password.',
    'email-already-in-use'=> 'An account with this email already exists.',
    'weak-password'       => 'Password must be at least 6 characters.',
    'invalid-email'       => 'Please enter a valid email address.',
    'too-many-requests'   => 'Too many attempts. Try again later.',
    'network-request-failed' => 'No internet connection.',
    _                     => 'Something went wrong. Please try again.',
  };
}

final authServiceProvider = Provider<AuthService>(
      (ref) => AuthService(ref.watch(firebaseAuthProvider)),
);