import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/service_models.dart';
import '../../domain/entities/service_entities.dart';

abstract class ServicesRemoteDataSource {
  Future<List<MedicalServiceModel>> getServices(ServicesFilter filter);
  Future<List<MedicalServiceModel>> searchServices({
    required String query,
    String? area,
  });
}

class ServicesRemoteDataSourceImpl implements ServicesRemoteDataSource {
  final FirebaseFirestore _firestore;

  ServicesRemoteDataSourceImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  @override
  Future<List<MedicalServiceModel>> getServices(ServicesFilter filter) async {
    try {
      // ✅ query بسيطة من غير orderBy — بنعمل sort محلياً
      Query query = _firestore
          .collection(AppConstants.servicesCollection)
          .where('isAvailable', isEqualTo: true);

      // Filter by category فقط لو مش All
      if (filter.category != ServiceCategory.all) {
        query = query.where(
          'category',
          isEqualTo: filter.category.firestoreKey,
        );
      }

      final snapshot = await query.limit(30).get();

      // Firestore فاضية — رجّع mock data
      if (snapshot.docs.isEmpty) {
        return _filterAndSort(MedicalServiceModel.mockServices, filter);
      }

      // ✅ Sort محلياً بدل Firestore orderBy
      final services = snapshot.docs
          .map(
            (doc) => MedicalServiceModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      return _filterAndSort(services, filter);
    } on FirebaseException {
      // لو Firestore فشل → mock data دايماً
      return _filterAndSort(MedicalServiceModel.mockServices, filter);
    }
  }

  // ── Local sort ────────────────────────────────────────────────────────────────
  List<MedicalServiceModel> _filterAndSort(
    List<MedicalServiceModel> services,
    ServicesFilter filter,
  ) {
    var result = List<MedicalServiceModel>.from(services);

    // ✅ Filter by category أولاً
    if (filter.category != ServiceCategory.all) {
      result = result
          .where((s) => s.category == filter.category.firestoreKey)
          .toList();
    }

    // Filter by search query
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      result = result
          .where(
            (s) =>
                s.name.toLowerCase().contains(
                  filter.searchQuery!.toLowerCase(),
                ) ||
                s.category.toLowerCase().contains(
                  filter.searchQuery!.toLowerCase(),
                ),
          )
          .toList();
    }

    // Sort
    switch (filter.sortBy) {
      case SortOption.distance:
        result.sort(
          (a, b) => (a.distanceKm ?? 99).compareTo(b.distanceKm ?? 99),
        );
        break;
      case SortOption.discount:
        result.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
        break;
      case SortOption.alphabetical:
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return result;
  }

  @override
  Future<List<MedicalServiceModel>> searchServices({
    required String query,
    String? area,
  }) async {
    try {
      // Firestore مش بيدعم full-text search
      // بنجيب كل الـ services ونفلتر locally
      final snapshot = await _firestore
          .collection(AppConstants.servicesCollection)
          .where('isAvailable', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        return MedicalServiceModel.mockServices
            .where((s) => s.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }

      return snapshot.docs
          .map(
            (doc) => MedicalServiceModel.fromFirestore(
              doc.data(),
              doc.id,
            ),
          )
          .where(
            (s) =>
                s.name.toLowerCase().contains(query.toLowerCase()) ||
                s.category.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Search failed');
    }
  }
}
