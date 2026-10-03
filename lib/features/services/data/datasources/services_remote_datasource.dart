import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/service_model.dart';

abstract class ServicesRemoteDataSource {
  Future<List<ServiceModel>> getServicesByProvider(String providerId);
  Future<List<ServiceModel>> getAllServices();
}

class ServicesRemoteDataSourceImpl implements ServicesRemoteDataSource {
  final FirebaseFirestore _db;
  ServicesRemoteDataSourceImpl(this._db);

  @override
  Future<List<ServiceModel>> getServicesByProvider(String providerId) async {
    try {
      final snap = await _db
          .collection('services')
          .where('providerId', isEqualTo: providerId)
          .where('isAvailable', isEqualTo: true)
          .get();

      return snap.docs
          .map((doc) => ServiceModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw ServerException('Failed to load services: $e');
    }
  }

  @override
  Future<List<ServiceModel>> getAllServices() async {
    try {
      // ✅ Single field query only — no compound queries
      final snap = await _db
          .collection('services')
          .where('isAvailable', isEqualTo: true)
          .get();

      final list = snap.docs
          .map((doc) => ServiceModel.fromFirestore(doc.data(), doc.id))
          .toList();

      // Sort in memory
      list.sort((a, b) => a.category.compareTo(b.category));
      return list;
    } catch (e) {
      throw ServerException('Failed to load services: $e');
    }
  }
}
