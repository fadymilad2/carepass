import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // ✅ ضفنا الباكيدج دي لحساب المسافة
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/provider_models.dart';
import '../../domain/entities/provider_entities.dart';

abstract class ProvidersRemoteDataSource {
  Future<List<MedicalProviderModel>> getProviders(ProvidersFilter filter);
  Future<void> toggleFavorite(String providerId);
  Future<MedicalProviderModel> getProviderById(String id);
  Future<List<MedicalProviderModel>> searchProviders({
    required String query,
    String? area,
  });
}

class ProvidersRemoteDataSourceImpl implements ProvidersRemoteDataSource {
  final FirebaseFirestore _firestore;

  ProvidersRemoteDataSourceImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  @override
  Future<List<MedicalProviderModel>> getProviders(
    ProvidersFilter filter,
  ) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(AppConstants.providersCollection)
          .where('isActive', isEqualTo: true);

      if (filter.area != null && filter.area!.isNotEmpty) {
        query = query.where('area', isEqualTo: filter.area);
      }

      final snapshot = await query.get();

      final position = await _position(required: filter.nearbyOnly);
      final favorites = await _favoriteIds();

      var providers = snapshot.docs.map((doc) {
        final data = doc.data();
        double? calculatedDistance;

        // ✅ حساب المسافة لايف لو البروفايدر عنده إحداثيات
        if (position != null &&
            data['latitude'] != null &&
            data['longitude'] != null) {
          final pLat = (data['latitude'] as num).toDouble();
          final pLng = (data['longitude'] as num).toDouble();

          final distanceInMeters = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            pLat,
            pLng,
          );
          calculatedDistance = distanceInMeters / 1000; // تحويل لكيلومتر
        }

        return MedicalProviderModel.fromFirestore(
          data,
          doc.id,
          distanceKm: calculatedDistance,
          isFavorite: favorites.contains(doc.id),
        );
      }).toList();

      if (filter.type != null) {
        providers = providers.where((p) => p.offersType(filter.type!)).toList();
      }

      final search = filter.searchQuery?.trim().toLowerCase() ?? '';
      if (search.isNotEmpty) {
        providers = providers
            .where(
              (p) =>
                  p.name.toLowerCase().contains(search) ||
                  p.typeLabel.toLowerCase().contains(search) ||
                  p.address.toLowerCase().contains(search) ||
                  p.services.any((s) => s.toLowerCase().contains(search)),
            )
            .toList();
      }
      if (filter.nearbyOnly) {
        providers = providers
            .where((p) => p.distanceKm != null && p.distanceKm! <= 10)
            .toList();
      }
      providers = _applySort(providers, filter.sortBy);

      return providers;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to load providers');
    } catch (e) {
      throw ServerException('Failed to load providers: $e');
    }
  }

  @override
  Future<MedicalProviderModel> getProviderById(String id) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.providersCollection)
          .doc(id)
          .get();

      if (!doc.exists || doc.data() == null) {
        throw const ServerException('Provider not found');
      }

      return MedicalProviderModel.fromFirestore(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Failed to load provider');
    }
  }

  @override
  Future<List<MedicalProviderModel>> searchProviders({
    required String query,
    String? area,
  }) async {
    return getProviders(ProvidersFilter(searchQuery: query, area: area));
  }

  Future<Position?> _position({required bool required}) async {
    try {
      var permission = await Geolocator.checkPermission();
      if (required && permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (required) {
          throw const ServerException(
            'Allow location access to find nearby providers.',
          );
        }
        return null;
      }
      if (!required) return await Geolocator.getLastKnownPosition();
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      if (required) {
        throw const ServerException(
          'Unable to find your location. Check location permissions.',
        );
      }
      return null;
    }
  }

  Future<Set<String>> _favoriteIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .get();
    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  @override
  Future<void> toggleFavorite(String providerId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw const AuthException('Sign in to save favorites.');
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(providerId);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      if (existing.exists) {
        transaction.delete(ref);
      } else {
        transaction.set(ref, {'providerId': providerId});
      }
    });
  }

  List<MedicalProviderModel> _applySort(
    List<MedicalProviderModel> providers,
    ProviderSortOption sortBy,
  ) {
    final result = List<MedicalProviderModel>.from(providers);

    switch (sortBy) {
      case ProviderSortOption.distance:
        result.sort(
          (a, b) => (a.distanceKm ?? 99).compareTo(b.distanceKm ?? 99),
        );
        break;
      case ProviderSortOption.rating:
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ProviderSortOption.discount:
        result.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
        break;
    }

    return result;
  }
}
