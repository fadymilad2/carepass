import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_entities.dart';

abstract class AuthRepository {
  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, AppUser>> register({
    required String username,
    required String email,
    required String password,
  });

  Future<Either<Failure, AppUser?>> getCurrentUser();
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, void>> sendPasswordReset(String email);
}