part of 'account_bloc.dart';

abstract class AccountState extends Equatable {
  const AccountState();
  @override
  List<Object?> get props => [];
}

class AccountInitial extends AccountState {}

class AccountLoading extends AccountState {}

class AccountSignedOut extends AccountState {}

class AccountDeleted extends AccountState {}

class AccountDeletionFailed extends AccountLoaded {
  final String message;
  const AccountDeletionFailed(super.user, this.message);
  @override
  List<Object?> get props => [user, message];
}

class AccountLoaded extends AccountState {
  final AccountUser user;
  const AccountLoaded(this.user);
  @override
  List<Object?> get props => [user];
}

class AccountError extends AccountState {
  final String message;
  const AccountError(this.message);
  @override
  List<Object?> get props => [message];
}

class AccountUpdateSuccess extends AccountState {
  final AccountUser user;
  const AccountUpdateSuccess(this.user);
  @override
  List<Object?> get props => [user];
}
