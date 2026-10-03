import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/account_models.dart';

abstract class AccountRemoteDataSource {
  Future<AccountUserModel> getAccountUser();
  Future<void> updateUsername(String username);
  // ✅ New method
  Future<void> updateProfile({
    String? email,
    String? city,
    String? bloodType,
    String? emergencyContact,
  });
  Future<void> signOut();
}

class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AccountRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  // ── Get Account User ────────────────────────────────────────────────
  @override
  Future<AccountUserModel> getAccountUser() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw const AuthException('Not logged in');

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        throw const ServerException('User not found');
      }

      return AccountUserModel.fromFirestore(doc.data()!, uid);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to load user');
    }
  }

  // ── Update Username ─────────────────────────────────────────────────
  @override
  Future<void> updateUsername(String username) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw const AuthException('Not logged in');

      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(
        {'username': username},
      );
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Update failed');
    }
  }

  // ── Update Profile (editable fields only) ──────────────────────────
  @override
  Future<void> updateProfile({
    String? email,
    String? city,
    String? bloodType,
    String? emergencyContact,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw const AuthException('Not logged in');

      // ✅ Only update fields that were provided
      final updates = <String, dynamic>{};
      if (email != null) updates['email'] = email;
      if (city != null) updates['city'] = city;
      if (bloodType != null) updates['bloodType'] = bloodType;
      if (emergencyContact != null) {
        updates['emergencyContact'] = emergencyContact;
      }
      updates['updatedAt'] = DateTime.now().toIso8601String();

      if (updates.length > 1) {
        // more than just updatedAt
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .update(updates);
      }
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Update failed');
    }
  }

  // ── Sign Out ────────────────────────────────────────────────────────
  @override
  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(
        {'fcmToken': ''},
      );
    }
    await _auth.signOut();
  }
}
