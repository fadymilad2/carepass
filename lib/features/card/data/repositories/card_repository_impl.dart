import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/card_entities.dart';
import '../../domain/repositories/card_repository.dart';
import '../datasources/card_remote_datasource.dart';

class CardRepositoryImpl implements CardRepository {
  final CardRemoteDataSource _remote;
  CardRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, HealthCard>> getUserCard() async {
    try {
      final result = await _remote.getUserCard();
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
  Future<Either<Failure, void>> renewCard(String planId) async {
    return const Left(
      ServerFailure('Renew your subscription through checkout.'),
    );
  }
}
