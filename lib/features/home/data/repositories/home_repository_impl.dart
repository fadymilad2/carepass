import 'package:carepass/core/errors/exceptions.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/home_entities.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserSummary>> getUserSummary() async {
    try {
      final result = await remoteDataSource.getUserSummary();
      return Right(result);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<HomeBanner>>> getHomeBanners({
    required bool isSubscribed,
    String? area,
  }) async {
    try {
      final result = await remoteDataSource.getHomeBanners(
        isSubscribed: isSubscribed,
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
  Future<Either<Failure, HomeQuickStat>> getHomeQuickStats({
    required String userId,
    String? area,
  }) async {
    try {
      final data = await remoteDataSource.getHomeQuickStats(
        userId: userId,
        area: area,
      );
      return Right(
        HomeQuickStat(
          nearbyProviders: data['nearbyProviders'] as int,
          availableServices: data['availableServices'] as int,
          checkupsRemaining: data['checkupsRemaining'] as int,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<HomeProviderItem>>> getNearbyProviders(
    String area,
  ) async {
    try {
      return Right(await remoteDataSource.getNearbyProviders(area));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<HomeServiceItem>>> getPopularServices(
    String area,
  ) async {
    try {
      return Right(await remoteDataSource.getPopularServices(area));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
