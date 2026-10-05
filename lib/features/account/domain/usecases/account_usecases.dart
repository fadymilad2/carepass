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

// ✅ New use case — editable fields only
class UpdateProfile {
  final AccountRepository repo;
  UpdateProfile(this.repo);

  Future<Either<Failure, void>> call({
    String? email,
    String? city,
    String? bloodType,
    String? emergencyContact,
  }) => (repo as dynamic).updateProfile(
    email: email,
    city: city,
    bloodType: bloodType,
    emergencyContact: emergencyContact,
  );
}

class AccountSignOut {
  final AccountRepository repo;
  AccountSignOut(this.repo);

  Future<Either<Failure, void>> call() => repo.signOut();
}

class DeleteAccount {
  final AccountRepository repo;
  DeleteAccount(this.repo);

  Future<Either<Failure, void>> call() => repo.deleteAccount();
}
