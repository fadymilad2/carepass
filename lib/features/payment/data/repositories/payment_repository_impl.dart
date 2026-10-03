import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/payment_entities.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource _remote;
  PaymentRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<SubscriptionPlan>>> getPlans() async {
    try {
      return Right(await _remote.getPlans());
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, PaymentCheckout>> initializePayment({
    required String email,
    required String planId,
    required double amount,
    required String currency,
  }) async {
    try {
      final url = await _remote.initializePayment(
        email: email,
        planId: planId,
        amount: amount,
        currency: currency,
      );
      return Right(url);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, PaymentVerification>> verifyPayment(
    String reference,
  ) async {
    try {
      final success = await _remote.verifyPayment(reference);
      return Right(success);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> saveTransaction(PaymentTransaction tx) async {
    try {
      await _remote.saveTransaction(tx);
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
