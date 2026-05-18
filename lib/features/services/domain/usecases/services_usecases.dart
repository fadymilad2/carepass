import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/service_entities.dart';
import '../repositories/services_repository.dart';

class GetServices {
  final ServicesRepository repo;
  GetServices(this.repo);

  Future<Either<Failure, List<MedicalService>>> call(
    ServicesFilter filter,
  ) => repo.getServices(filter);
}

class SearchServices {
  final ServicesRepository repo;
  SearchServices(this.repo);

  Future<Either<Failure, List<MedicalService>>> call({
    required String query,
    String? area,
  }) => repo.searchServices(query: query, area: area);
}