import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/service_entities.dart';

abstract class ServicesRepository {
  Future<Either<Failure, List<MedicalService>>> getServices(
    ServicesFilter filter,
  );

  Future<Either<Failure, List<MedicalService>>> searchServices({
    required String query,
    String? area,
  });

  Future<Either<Failure, int>> getProviderCountForService({
    required String serviceId,
    required String area,
  });
}