import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _ds;
  AuthRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, String>> sendOtp(String phoneNumber) async {
    try {
      return Right(await _ds.sendOtp(phoneNumber));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AppUser>> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    try {
      return Right(
        await _ds.verifyOtp(verificationId: verificationId, otp: otp),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AppUser>> createProfile({
    required String uid,
    required String username,
    required String phoneNumber,
    // ✅ New optional fields
    String? email,
    String? dateOfBirth,
    String? city,
    String? emergencyContact,
    String? bloodType,
  }) async {
    try {
      return Right(
        await _ds.createProfile(
          uid: uid,
          username: username,
          phoneNumber: phoneNumber,
          email: email,
          dateOfBirth: dateOfBirth,
          city: city,
          emergencyContact: emergencyContact,
          bloodType: bloodType,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() async {
    try {
      return Right(await _ds.getCurrentUser());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _ds.signOut();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
