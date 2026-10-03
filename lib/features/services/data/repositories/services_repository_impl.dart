import 'package:carepass/features/services/domain/entities/service_entities.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/repositories/services_repository.dart';
import '../datasources/services_remote_datasource.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  final ServicesRemoteDataSource _ds;
  ServicesRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, List<ServiceEntity>>> getServicesByProvider(
    String providerId,
  ) async {
    try {
      return Right(await _ds.getServicesByProvider(providerId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<ServiceEntity>>> getAllServices() async {
    try {
      return Right(await _ds.getAllServices());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
