import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usermodel.dart';

class AdminSeeder {
  static final _auth = FirebaseAuth.instance;
  static final _db   = FirebaseFirestore.instance;

  static const _adminEmail    = 'admin@refound.com';
  static const _adminPassword = 'Admin12a';
  static const _adminName     = 'Admin';
  static const _adminPhone    = ' 00 000 000';

  static Future<void> seedAdmin() async {
    try {
      UserCredential credential;

      // 1. Try creating the account first
      try {
        credential = await _auth.createUserWithEmailAndPassword(
          email: _adminEmail,
          password: _adminPassword,
        );
        print('⚙️  New admin auth account created.');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Auth exists — sign in to get uid
          credential = await _auth.signInWithEmailAndPassword(
            email: _adminEmail,
            password: _adminPassword,
          );
          print('⚙️  Signed in as existing admin auth account.');
        } else {
          rethrow;
        }
      }

      final user = credential.user!;

      // 2. NOW check Firestore — we are authenticated at this point
      final existing = await _db
          .collection('users')
          .doc(user.uid)
          .get();

      if (existing.exists && existing.data()?['role'] == 'admin') {
        print('✅ Admin doc already exists, skipping.');
        return;
      }

      // 3. Create/overwrite the Firestore doc
      await user.updateDisplayName(_adminName);

      final adminModel = UserModel(
        uid: user.uid,
        name: _adminName,
        phone: _adminPhone,
        email: _adminEmail,
        createdAt: DateTime.now(),
        isVerified: true,
        role: 'admin',
      );

      await _db
          .collection('users')
          .doc(user.uid)
          .set(adminModel.toMap());

      print('✅ Admin account created successfully.');

    } on FirebaseAuthException catch (e) {
      print('❌ Auth error during admin seed: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error during admin seed: $e');
    } finally {
      await _auth.signOut();
      print('🔒 Signed out after seed.');
    }
  }
}