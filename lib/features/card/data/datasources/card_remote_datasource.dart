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
  }) : _firestore = firestore,
       _auth = auth;

  @override
  Future<HealthCardModel> getUserCard() async {
    try {
      // 1. Get current user. If not logged in, throw an exception.
      // This is the source of the "Not logged in" error, which is correctly
      // handled by the BLoC's retry logic.
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw const AuthException('Not logged in');

      // 2. Fetch the user's document from Firestore.
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        throw const ServerException('User profile not found.');
      }

      final data = doc.data()!;
      final memberName = data['username'] ?? data['fullName'] ?? 'Member';

      // 3. Determine card state based on subscription.
      // If the user has an active, expired, or suspended subscription, we
      // build the card from the full Firestore data. Otherwise (e.g., they
      // have never subscribed), we return a default, inactive mock card.
      final status = data['subscriptionStatus'] as String?;
      if (status != null && status != 'none') {
        return HealthCardModel.fromFirestore(data, uid);
      }

      // Return a default/mock card for users without a subscription history.
      return HealthCardModel.mock(uid, memberName);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Card fetch failed');
    } on AuthException {
      rethrow; // Re-throw auth exceptions to be handled by the BLoC.
    } catch (e) {
      // Catch any other unexpected errors.
      throw ServerException('An unexpected error occurred: $e');
    }
  }
}
