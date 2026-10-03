import 'package:carepass/core/errors/exceptions.dart';
import 'package:carepass/features/home/domain/entities/home_entities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/home_models.dart';
import '../models/home_provider_model.dart';

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
  Future<List<HomeServiceItem>> getPopularServices(String area);
  Future<List<HomeProviderItem>> getNearbyProviders(String area);
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  HomeRemoteDataSourceImpl({required this.firestore, required this.auth});

  @override
  Future<UserSummaryModel> getUserSummary() async {
    try {
      final uid = auth.currentUser?.uid;

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

      final doc = await firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        return UserSummaryModel(
          id: uid,
          firstName: 'New',
          fullName: 'New User',
          subscriptionStatus: SubscriptionStatus.none,
          cardExpiryDate: null,
          selectedArea: '',
        );
      }

      return UserSummaryModel.fromFirestore(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Firebase error', e.hashCode);
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  // ✅ Fixed Banners — fallback without area filter
  @override
  Future<List<HomeBannerModel>> getHomeBanners({
    required bool isSubscribed,
    String? area,
  }) async {
    try {
      List<QueryDocumentSnapshot> docs = [];

      // ── Step 1: Try with area filter ────────────────────────────────
      if (area != null && area.trim().isNotEmpty) {
        try {
          final snap = await firestore
              .collection('home_banners')
              .where('isActive', isEqualTo: true)
              .where('areas', arrayContains: area)
              .orderBy('order')
              .limit(10)
              .get();
          docs = snap.docs;
        } catch (_) {
          // Index might not exist — skip area filter
        }
      }

      // ── Step 2: Fallback — all active banners (no area filter) ──────
      if (docs.isEmpty) {
        try {
          final snap = await firestore
              .collection('home_banners')
              .where('isActive', isEqualTo: true)
              .orderBy('order')
              .limit(10)
              .get();
          docs = snap.docs;
        } catch (_) {
          // orderBy might fail without index — try without it
          final snap = await firestore
              .collection('home_banners')
              .where('isActive', isEqualTo: true)
              .limit(10)
              .get();
          docs = snap.docs;
        }
      }

      // ── Step 3: Static onboarding banners ───────────────────────────
      if (docs.isEmpty) {
        return HomeBannerModel.onboardingBanners;
      }

      return docs
          .map(
            (doc) => HomeBannerModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } on FirebaseException catch (e) {
      debugPrint('Banner error: ${e.message}');
      return HomeBannerModel.onboardingBanners;
    } catch (e) {
      debugPrint('Banner error: $e');
      return HomeBannerModel.onboardingBanners;
    }
  }

  @override
  Future<Map<String, dynamic>> getHomeQuickStats({
    required String userId,
    String? area,
  }) async {
    if (userId == 'guest_id') {
      return {
        'nearbyProviders': 0,
        'availableServices': 0,
        'checkupsRemaining': 0,
      };
    }

    try {
      Query providersQuery = firestore
          .collection('providers')
          .where('isActive', isEqualTo: true);

      if (area != null && area.trim().isNotEmpty) {
        providersQuery = providersQuery.where('area', isEqualTo: area);
      }

      Query servicesQuery = firestore
          .collection('services')
          .where('isAvailable', isEqualTo: true);

      final results = await Future.wait([
        providersQuery.count().get(),
        servicesQuery.count().get(),
        firestore.collection('users').doc(userId).get(),
        firestore.collection('settings').doc('app_config').get(),
      ]);

      final providersAgg = results[0] as AggregateQuerySnapshot;
      final servicesAgg = results[1] as AggregateQuerySnapshot;
      final userDoc = results[2] as DocumentSnapshot;
      final settings =
          (results[3] as DocumentSnapshot).data() as Map<String, dynamic>? ??
          {};

      int checkupsRemaining = 0;
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>? ?? {};
        final subStatus = data['subscriptionStatus'] ?? 'none';

        final expiry = DateTime.tryParse(
          data['cardExpiryDate'] as String? ?? '',
        );
        if (subStatus == 'active' && expiry?.isAfter(DateTime.now()) == true) {
          final sameMonth =
              data['checksResetMonth'] ==
              DateTime.now().toUtc().toIso8601String().substring(0, 7);
          final usedBp = sameMonth
              ? (data['bpChecksUsedThisMonth'] as int? ?? 0)
              : 0;
          final usedSugar = sameMonth
              ? (data['sugarChecksUsedThisMonth'] as int? ?? 0)
              : 0;
          final bpLimit = settings['bloodPressureChecksPerMonth'] as int? ?? 1;
          final sugarLimit = settings['bloodSugarChecksPerMonth'] as int? ?? 1;
          checkupsRemaining =
              (bpLimit - usedBp).clamp(0, 999) +
              (sugarLimit - usedSugar).clamp(0, 999);
        }
      }

      return {
        'nearbyProviders': providersAgg.count,
        'availableServices': servicesAgg.count,
        'checkupsRemaining': checkupsRemaining,
      };
    } catch (e) {
      debugPrint('QuickStats error: $e');
      return {
        'nearbyProviders': 0,
        'availableServices': 0,
        'checkupsRemaining': 0,
      };
    }
  }

  // ✅ Fixed — groups identical services (same name + category)
  // offered by multiple providers into ONE entry, showing the
  // highest discount among them. Same grouping logic used in
  // services_bloc.dart, so the Home tile and the Services page
  // agree on what counts as "one" service.
  @override
  Future<List<HomeServiceItem>> getPopularServices(String area) async {
    try {
      Set<String>? providerIds;
      if (area.trim().isNotEmpty) {
        final providers = await firestore
            .collection('providers')
            .where('isActive', isEqualTo: true)
            .where('area', isEqualTo: area)
            .get();
        providerIds = providers.docs.map((doc) => doc.id).toSet();
      }
      final snap = await firestore
          .collection('services')
          .where('isAvailable', isEqualTo: true)
          .get();

      if (snap.docs.isEmpty) return [];

      // ✅ Group by normalized name + category
      final Map<String, HomeServiceItem> grouped = {};
      final Map<String, int> bestDiscount = {};

      for (final doc in snap.docs) {
        final data = doc.data();
        if (providerIds != null && !providerIds.contains(data['providerId'])) {
          continue;
        }
        final category = data['category'] as String? ?? 'consultation';
        final name = data['name'] as String? ?? '';
        final discount = data['discountPercent'] as int? ?? 0;

        final key =
            '${category.toLowerCase().trim()}::'
            '${name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ')}';

        // ✅ Only keep the entry with the highest discount for this key
        if (!bestDiscount.containsKey(key) || discount > bestDiscount[key]!) {
          bestDiscount[key] = discount;
          grouped[key] = HomeServiceItem(
            id: doc.id,
            name: name,
            category: category,
            discountPercent: discount,
            icon: _categoryIcon(category),
          );
        }
      }

      final unique = grouped.values.toList();
      unique.sort((a, b) => a.name.compareTo(b.name));

      return unique.take(5).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<HomeProviderItem>> getNearbyProviders(String area) async {
    try {
      Query<Map<String, dynamic>> query = firestore
          .collection('providers')
          .where('isActive', isEqualTo: true);

      if (area.trim().isNotEmpty) {
        query = query.where('area', isEqualTo: area.trim());
      }

      final snap = await query.get();
      if (snap.docs.isEmpty) return [];
      final position = await _currentPosition();
      return nearestHomeProviders(
        snap.docs.map(
          (doc) => HomeProviderModel.fromFirestore(
            doc.data(),
            doc.id,
            position: position,
          ),
        ),
      );
    } on FirebaseException catch (_) {
      throw const ServerException(
        'Unable to load providers. Please try again.',
      );
    }
  }

  // Home does not interrupt browsing with a location permission prompt.
  // Without permission or coordinates, show real area data without a distance.
  Future<Position?> _currentPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 5),
          accuracy: LocationAccuracy.medium,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'consultation':
        return Icons.person_outlined;
      case 'radiology':
        return Icons.image_outlined;
      case 'lab':
        return Icons.science_outlined;
      case 'pharmacy':
        return Icons.medication_outlined;
      case 'dental':
        return Icons.masks_outlined;
      case 'physiotherapy':
        return Icons.accessibility_outlined;
      case 'blood_pressure':
        return Icons.favorite_outlined;
      case 'blood_sugar':
        return Icons.water_drop_outlined;
      default:
        return Icons.medical_services_outlined;
    }
  }
}
