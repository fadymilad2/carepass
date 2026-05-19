import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/provider_models.dart';
import '../../domain/entities/provider_entities.dart';

abstract class ProvidersRemoteDataSource {
  Future<List<MedicalProviderModel>> getProviders(ProvidersFilter filter);
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
      Query query = _firestore
          .collection(AppConstants.providersCollection)
          .where('isActive', isEqualTo: true);

      if (filter.type != null) {
        query = query.where('type', isEqualTo: filter.type!.firestoreKey);
      }

      final snapshot = await query.limit(30).get();

      if (snapshot.docs.isEmpty) {
        return _sortMock(
          MedicalProviderModel.mockProviders(filter.area ?? 'Accra'),
          filter,
        );
      }

      final providers = snapshot.docs
          .map((doc) => MedicalProviderModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      return _sortMock(providers, filter);
    } on FirebaseException catch (_) {
      return _sortMock(
        MedicalProviderModel.mockProviders(filter.area ?? 'Accra'),
        filter,
      );
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
    final mock = MedicalProviderModel.mockProviders(area ?? 'Accra');
    return mock
        .where((p) =>
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            p.typeLabel.toLowerCase().contains(query.toLowerCase()) ||
            p.services.any((s) =>
                s.toLowerCase().contains(query.toLowerCase())))
        .toList();
  }

  List<MedicalProviderModel> _sortMock(
    List<MedicalProviderModel> providers,
    ProvidersFilter filter,
  ) {
    final result = List<MedicalProviderModel>.from(providers);

    if (filter.type != null) {
      result.removeWhere((p) => p.type != filter.type);
    }

    switch (filter.sortBy) {
      case ProviderSortOption.distance:
        result.sort((a, b) =>
            (a.distanceKm ?? 99).compareTo(b.distanceKm ?? 99));
        break;
      case ProviderSortOption.rating:
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ProviderSortOption.discount:
        result.sort(
            (a, b) => b.discountPercent.compareTo(a.discountPercent));
        break;
    }

    return result;
  }
}