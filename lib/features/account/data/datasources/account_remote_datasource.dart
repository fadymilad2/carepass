import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/account_models.dart';

abstract class AccountRemoteDataSource {
  Future<AccountUserModel> getAccountUser();
  Future<void> updateUsername(String username);
  Future<void> signOut();
}

class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AccountRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

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
      throw ServerException(e.message ?? 'Failed');
    }
  }

  @override
  Future<void> updateUsername(String username) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw const AuthException('Not logged in');

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({'username': username});
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Update failed');
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}