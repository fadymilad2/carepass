import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/service_entities.dart';
import '../repositories/services_repository.dart';

class GetServicesByProvider {
  final ServicesRepository repo;
  GetServicesByProvider(this.repo);

  Future<Either<Failure, List<ServiceEntity>>> call(String providerId) =>
      repo.getServicesByProvider(providerId);
}

class GetAllServices {
  final ServicesRepository repo;
  GetAllServices(this.repo);

  Future<Either<Failure, List<ServiceEntity>>> call() => repo.getAllServices();
}
