import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the currently signed-in Firebase user, or null if none.
  User? get currentUser => _auth.currentUser;

  /// Registers a new user using [name], [email], and [password].
  /// Returns the [User] on success, or null on failure.
  Future<User?> createUserWithEmailAndPassword(
      String name, String email, String password) async {
    try {
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set display name immediately after account creation
      await cred.user?.updateDisplayName(name);
      await cred.user?.reload();

      return _auth.currentUser;
    } catch (e, stack) {
      log("Signup failed: $e", stackTrace: stack);
      return null;
    }
  }

  /// Logs in a user with [email] and [password].
  /// Returns the [User] on success, or null on failure.
  Future<User?> loginUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } catch (e, stack) {
      log("Login failed: $e", stackTrace: stack);
      return null;
    }
  }

  /// Signs out the currently logged-in user.
  Future<void> signout() async {
    try {
      await _auth.signOut();
    } catch (e, stack) {
      log("Sign out failed: $e", stackTrace: stack);
    }
  }
}
