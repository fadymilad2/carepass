import 'package:carepass/core/errors/exceptions.dart';
import 'package:carepass/features/home/domain/entities/home_entities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/home_models.dart';

abstract class HomeRemoteDataSource {
  Future<UserSummaryModel> getUserSummary();
  Future<List<HomeBannerModel>> getHomeBanners({
    required bool isSubscribed,
    String? area,
  });
  Future<Map<String, dynamic>> getHomeQuickStats({
    required String userId,
    String? area,
  });
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  HomeRemoteDataSourceImpl({required this.firestore, required this.auth});

  @override
  Future<UserSummaryModel> getUserSummary() async {
    try {
      final uid = auth.currentUser?.uid;
      
      // هنا بنقول للتطبيق: لو مفيش حد عامل تسجيل دخول، اعتبره ضيف (Guest)
      if (uid == null) {
        return const UserSummaryModel(
          id: 'guest_id',
          firstName: 'Guest',
          fullName: 'Guest User',
          subscriptionStatus: SubscriptionStatus.none,
          cardExpiryDate: null,
          selectedArea: '',
        );
      }

      final doc = await firestore.collection(AppConstants.usersCollection).doc(uid).get();

      if (!doc.exists || doc.data() == null) {
        throw const ServerException('User data not found');
      }

      return UserSummaryModel.fromFirestore(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Firebase error', e.hashCode);
    }
  }

  @override
  Future<List<HomeBannerModel>> getHomeBanners({
    required bool isSubscribed,
    String? area,
  }) async {
    // Non-subscribed → return static onboarding banners (no Firestore call needed)
    if (!isSubscribed) {
      return HomeBannerModel.onboardingBanners;
    }

    try {
      // Subscribed → fetch provider/promotional banners filtered by area
      Query query = firestore
          .collection('home_banners')
          .where('isActive', isEqualTo: true)
          .orderBy('order');

      if (area != null && area.isNotEmpty) {
        query = query.where('areas', arrayContains: area);
      }

      final snapshot = await query.limit(10).get();

      return snapshot.docs
          .map((doc) => HomeBannerModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Banners fetch error');
    }
  }

  @override
  Future<Map<String, dynamic>> getHomeQuickStats({
    required String userId,
    String? area,
  }) async {
    // 💡 التعديل هنا: منع الطلب من فايربيز للـ Guest عشان الشيمر ميعلقش
    if (userId == 'guest_id') {
      return {
        'nearbyProviders': 0,
        'availableServices': 0,
        'checkupsRemaining': 0,
      };
    }

    try {
      // Parallel requests for better performance
      final results = await Future.wait([
        // Count providers in area
        firestore
            .collection(AppConstants.providersCollection)
            .where('areas', arrayContains: area ?? '')
            .where('isActive', isEqualTo: true)
            .count()
            .get(),

        // Count available services
        firestore
            .collection(AppConstants.servicesCollection)
            .where('isActive', isEqualTo: true)
            .count()
            .get(),

        // Get remaining checkups for user
        firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .collection(AppConstants.checkupsCollection)
            .where('used', isEqualTo: false)
            .count()
            .get(),
      ]);

      return {
        'nearbyProviders':   results[0].count ?? 0,
        'availableServices': results[1].count ?? 0,
        'checkupsRemaining': results[2].count ?? 0,
      };
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Stats fetch error');
    }
  }
}