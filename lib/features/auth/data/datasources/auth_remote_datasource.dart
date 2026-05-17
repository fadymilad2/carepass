import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/auth_models.dart';

abstract class AuthRemoteDataSource {
  Future<AppUserModel> signIn({required String email, required String password});
  Future<AppUserModel> register({
    required String username,
    required String email,
    required String password,
  });
  Future<AppUserModel?> getCurrentUser();
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  // ── Sign In ─────────────────────────────────────────────────────────────
  @override
  Future<AppUserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = result.user?.uid;
      if (uid == null) throw const AuthException('Sign in failed');

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        throw const AuthException('Account not found');
      }

      return AppUserModel.fromFirestore(doc.data()!, doc.id);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e.code));
    }
  }

  // ── Register ─────────────────────────────────────────────────────────────
  @override
  Future<AppUserModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // 1. تأكد إن الـ username مش موجود
      final usernameQuery = await _firestore
          .collection(AppConstants.usersCollection)
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        throw const AuthException('Username already taken');
      }

      // 2. إنشاء حساب Firebase Auth
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = result.user?.uid;
      if (uid == null) throw const AuthException('Registration failed');

      // 3. حفظ البيانات في Firestore
      final user = AppUserModel(
        id: uid,
        username: username.trim(),
        email: email.trim(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(user.toFirestore());

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e.code));
    } on AuthException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Registration failed');
    }
  }

  // ── Get Current User ─────────────────────────────────────────────────────
  @override
  Future<AppUserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (!doc.exists || doc.data() == null) return null;
      return AppUserModel.fromFirestore(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Get user failed');
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  @override
  Future<void> signOut() => _auth.signOut();

  // ── Password Reset ────────────────────────────────────────────────────────
  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e.code));
    }
  }

  // ── Map Firebase errors ───────────────────────────────────────────────────
  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}