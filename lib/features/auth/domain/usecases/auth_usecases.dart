import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_entities.dart';
import '../repositories/auth_repository.dart';

class SendOtp {
  final AuthRepository repo;
  SendOtp(this.repo);

  Future<Either<Failure, String>> call(String phoneNumber) =>
      repo.sendOtp(phoneNumber);
}

class VerifyOtp {
  final AuthRepository repo;
  VerifyOtp(this.repo);

  Future<Either<Failure, AppUser>> call({
    required String verificationId,
    required String otp,
  }) => repo.verifyOtp(verificationId: verificationId, otp: otp);
}

// ✅ Updated — optional new fields
class CreateProfile {
  final AuthRepository repo;
  CreateProfile(this.repo);

  Future<Either<Failure, AppUser>> call({
    required String uid,
    required String username,
    required String phoneNumber,
    String? email,
    String? dateOfBirth,
    String? city,
    String? emergencyContact,
    String? bloodType,
  }) => repo.createProfile(
    uid: uid,
    username: username,
    phoneNumber: phoneNumber,
    email: email,
    dateOfBirth: dateOfBirth,
    city: city,
    emergencyContact: emergencyContact,
    bloodType: bloodType,
  );
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
