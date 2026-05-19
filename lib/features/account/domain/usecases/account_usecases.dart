import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/account_entities.dart';
import '../repositories/account_repository.dart';

class GetAccountUser {
  final AccountRepository repo;
  GetAccountUser(this.repo);
  Future<Either<Failure, AccountUser>> call() => repo.getAccountUser();
}

class UpdateUsername {
  final AccountRepository repo;
  UpdateUsername(this.repo);
  Future<Either<Failure, void>> call(String username) =>
      repo.updateUsername(username);
}

class AccountSignOut {
  final AccountRepository repo;
  AccountSignOut(this.repo);
  Future<Either<Failure, void>> call() => repo.signOut();
}