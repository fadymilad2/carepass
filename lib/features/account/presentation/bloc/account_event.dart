part of 'account_bloc.dart';

abstract class AccountEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AccountLoadRequested extends AccountEvent {}

class AccountSignOutRequested extends AccountEvent {}

class AccountDeleteRequested extends AccountEvent {}

class AccountUsernameUpdateRequested extends AccountEvent {
  final String username;
  AccountUsernameUpdateRequested(this.username);
  @override
  List<Object?> get props => [username];
}

// ✅ New event — update editable profile fields
class AccountProfileUpdateRequested extends AccountEvent {
  final String? email;
  final String? city;
  final String? bloodType;
  final String? emergencyContact;

  AccountProfileUpdateRequested({
    this.email,
    this.city,
    this.bloodType,
    this.emergencyContact,
  });

  @override
  List<Object?> get props => [email, city, bloodType, emergencyContact];
}
