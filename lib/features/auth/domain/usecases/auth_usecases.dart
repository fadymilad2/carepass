import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_entities.dart';
import '../repositories/auth_repository.dart';

class SignIn {
  final AuthRepository repo;
  SignIn(this.repo);
  Future<Either<Failure, AppUser>> call({
    required String email,
    required String password,
  }) => repo.signIn(email: email, password: password);
}

class Register {
  final AuthRepository repo;
  Register(this.repo);
  Future<Either<Failure, AppUser>> call({
    required String username,
    required String email,
    required String password,
  }) => repo.register(username: username, email: email, password: password);
}

class GetCurrentUser {
  final AuthRepository repo;
  GetCurrentUser(this.repo);
  Future<Either<Failure, AppUser?>> call() => repo.getCurrentUser();
}

class SignOut {
  final AuthRepository repo;
  SignOut(this.repo);
  Future<Either<Failure, void>> call() => repo.signOut();
}

class SendPasswordReset {
  final AuthRepository repo;
  SendPasswordReset(this.repo);
  Future<Either<Failure, void>> call(String email) =>
      repo.sendPasswordReset(email);
}