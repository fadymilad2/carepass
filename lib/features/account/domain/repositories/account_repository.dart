import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/account_entities.dart';

abstract class AccountRepository {
  Future<Either<Failure, AccountUser>> getAccountUser();
  Future<Either<Failure, void>> updateUsername(String username);
  Future<Either<Failure, void>> updateEmail(String email);
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, void>> deleteAccount();
}