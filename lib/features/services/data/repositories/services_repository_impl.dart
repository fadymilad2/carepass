import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/service_entities.dart';
import '../../domain/repositories/services_repository.dart';
import '../datasources/services_remote_datasource.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  final ServicesRemoteDataSource _remote;
  ServicesRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<MedicalService>>> getServices(
    ServicesFilter filter,
  ) async {
    try {
      final result = await _remote.getServices(filter);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<MedicalService>>> searchServices({
    required String query,
    String? area,
  }) async {
    try {
      final result = await _remote.searchServices(
        query: query,
        area: area,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, int>> getProviderCountForService({
    required String serviceId,
    required String area,
  }) async {
    return const Right(0);
  }
}