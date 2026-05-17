import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  AuthRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remote.signIn(email: email, password: password);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(AuthFailure());
    }
  }

  @override
  Future<Either<Failure, AppUser>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remote.register(
        username: username,
        email: email,
        password: password,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(AuthFailure());
    }
  }

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() async {
    try {
      final user = await _remote.getCurrentUser();
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _remote.signOut();
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordReset(String email) async {
    try {
      await _remote.sendPasswordReset(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(AuthFailure());
    }
  }
}