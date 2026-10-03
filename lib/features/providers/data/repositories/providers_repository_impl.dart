import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/provider_entities.dart';
import '../../domain/repositories/providers_repository.dart';
import '../datasources/providers_remote_datasource.dart';

class ProvidersRepositoryImpl implements ProvidersRepository {
  final ProvidersRemoteDataSource _remote;
  ProvidersRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<MedicalProvider>>> getProviders(
    ProvidersFilter filter,
  ) async {
    try {
      final result = await _remote.getProviders(filter);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, MedicalProvider>> getProviderById(String id) async {
    try {
      final result = await _remote.getProviderById(id);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<MedicalProvider>>> searchProviders({
    required String query,
    String? area,
  }) async {
    try {
      final result = await _remote.searchProviders(query: query, area: area);
      return Right(result);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> toggleFavorite(String providerId) async {
    try {
      await _remote.toggleFavorite(providerId);
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure('Could not update favorite.'));
    }
  }
}
