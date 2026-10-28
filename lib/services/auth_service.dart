import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  bool get isEmailVerified => _firebaseAuth.currentUser?.emailVerified ?? false;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(displayName.trim());
    await credential.user?.sendEmailVerification();
    return credential;
  }

  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw StateError('No signed-in account found.');
    await user.sendEmailVerification();
  }

  Future<void> reloadCurrentUser() async {
    await _firebaseAuth.currentUser?.reload();
  }

  Future<void> sendPasswordReset(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendPasswordChangeLink() async {
    final email = _firebaseAuth.currentUser?.email;
    if (email == null || email.trim().isEmpty) {
      throw StateError('No email address is linked to this account.');
    }
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> sendEmailChangeVerification(String newEmail) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw StateError('No signed-in account found.');
    await user.verifyBeforeUpdateEmail(newEmail.trim());
  }

  Future<void> signOut() => _firebaseAuth.signOut();
}

String firebaseAuthErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account is currently disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'requires-recent-login':
        return 'For safety, please sign in again before changing this account detail.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment, then try again.';
      default:
        return error.message ?? 'Account action failed. Please try again.';
    }
  }
  if (error is StateError) return error.message;
  return 'Account action failed. Please try again.';
}
