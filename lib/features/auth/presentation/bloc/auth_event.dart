part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthSignOutRequested extends AuthEvent {}

class AuthSendOtpRequested extends AuthEvent {
  final String phoneNumber;
  AuthSendOtpRequested(this.phoneNumber);
  @override
  List<Object?> get props => [phoneNumber];
}

class AuthVerifyOtpRequested extends AuthEvent {
  final String verificationId;
  final String otp;
  AuthVerifyOtpRequested({required this.verificationId, required this.otp});
  @override
  List<Object?> get props => [otp];
}

class AuthCreateProfileRequested extends AuthEvent {
  final String uid;
  final String username;
  final String phoneNumber;
  // ✅ New optional fields
  final String? email;
  final String? dateOfBirth;
  final String? city;
  final String? emergencyContact;
  final String? bloodType;

  AuthCreateProfileRequested({
    required this.uid,
    required this.username,
    required this.phoneNumber,
    this.email,
    this.dateOfBirth,
    this.city,
    this.emergencyContact,
    this.bloodType,
  });

  @override
  List<Object?> get props => [uid, username];
}
