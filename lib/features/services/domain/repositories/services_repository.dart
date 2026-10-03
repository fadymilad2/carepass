import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/service_entities.dart';

abstract class ServicesRepository {
  Future<Either<Failure, List<ServiceEntity>>> getServicesByProvider(
    String providerId,
  );
  Future<Either<Failure, List<ServiceEntity>>> getAllServices();
}
