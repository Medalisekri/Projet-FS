import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usermodel.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Sign Up ──────────────────────────────────────────
  Future<UserModel?> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;
      await user.updateDisplayName(name);

      // ✅ Send verification email immediately after signup
      await user.sendEmailVerification();

      // Save to Firestore with verified: false
      final userModel = UserModel(
        uid: user.uid,
        name: name,
        phone: phone,
        email: email,
        createdAt: DateTime.now(),
        isVerified: false,        // ← new field
      );

      await _db
          .collection('users')
          .doc(user.uid)
          .set(userModel.toMap());

      return userModel;

    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ── Resend verification email ─────────────────────────
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // ── Check if email is verified ────────────────────────
  // Must reload user first to get fresh data from Firebase
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    await user.reload();               // ← refresh from Firebase
    final refreshed = _auth.currentUser!;

    if (refreshed.emailVerified) {
      // Update Firestore too
      await _db
          .collection('users')
          .doc(refreshed.uid)
          .update({'isVerified': true});
      return true;
    }
    return false;
  }

  // ── Login — block unverified users ───────────────────
  Future<UserModel?> login({
  required String email,
  required String password,
}) async {
  try {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;

    // Fetch user doc from Firestore
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) throw 'User data not found.';

    final userModel = UserModel.fromMap(doc.data()!);

    // Block unverified non-admin users
    if (!user.emailVerified && !userModel.isAdmin) {
      await _auth.signOut();
      throw 'Please verify your email before logging in.';
    }

    return userModel;

  } on FirebaseAuthException catch (e) {
    throw _handleAuthError(e);
  }
}
  // ── Delete unverified account ─────────────────────────
  Future<void> deleteUnverifiedAccount() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await _db.collection('users').doc(user.uid).delete();
      await user.delete();
    }
  }
Future<void> sendPasswordReset({required String email}) async {
  try {
    // 1. Check Firestore for email
    final query = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();

    // 2. Not found — stop here, don't send anything
    if (query.docs.isEmpty) {
      throw 'No account found with this email.';
    }

    // 3. Found — send reset email
    await _auth.sendPasswordResetEmail(email: email.trim());

  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case 'invalid-email':
        throw 'Invalid email address.';
      case 'too-many-requests':
        throw 'Too many attempts. Please wait and try again.';
      default:
        throw 'Something went wrong. Please try again.';
    }
  } catch (e) {
    rethrow;
  }
}

  Future<void> signOut() async => await _auth.signOut();

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}