import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/card_models.dart';

abstract class CardRemoteDataSource {
  Future<HealthCardModel> getUserCard();
}

class CardRemoteDataSourceImpl implements CardRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CardRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  @override
  Future<HealthCardModel> getUserCard() async {
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

      final data = doc.data()!;

      // لو مفيش subscription بعد — return mock active card
      final status = data['subscriptionStatus'] ?? 'none';
      if (status == 'none') {
        return HealthCardModel.mock(
          uid,
          data['username'] ?? data['fullName'] ?? 'Member',
        );
      }

      return HealthCardModel.fromFirestore(data, uid);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Card fetch failed');
    }
  }
}