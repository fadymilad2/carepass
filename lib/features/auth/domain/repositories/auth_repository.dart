import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_entities.dart';

abstract class AuthRepository {
  Future<Either<Failure, String>> sendOtp(String phoneNumber);

  Future<Either<Failure, AppUser>> verifyOtp({
    required String verificationId,
    required String otp,
  });

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
  });

  Future<Either<Failure, AppUser?>> getCurrentUser();

  Future<Either<Failure, void>> signOut();
}
