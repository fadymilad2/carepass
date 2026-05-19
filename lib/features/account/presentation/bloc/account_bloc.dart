import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/account_entities.dart';
import '../../domain/usecases/account_usecases.dart';

abstract class AccountEvent extends Equatable {
  @override List<Object?> get props => [];
}
class AccountLoadRequested  extends AccountEvent {}
class AccountSignOutRequested extends AccountEvent {}
class AccountUsernameUpdateRequested extends AccountEvent {
  final String username;
  AccountUsernameUpdateRequested(this.username);
  @override List<Object?> get props => [username];
}

abstract class AccountState extends Equatable {
  const AccountState();
  @override List<Object?> get props => [];
}
class AccountInitial  extends AccountState {}
class AccountLoading  extends AccountState {}
class AccountSignedOut extends AccountState {}
class AccountLoaded extends AccountState {
  final AccountUser user;
  const AccountLoaded(this.user);
  @override List<Object?> get props => [user];
}
class AccountError extends AccountState {
  final String message;
  const AccountError(this.message);
  @override List<Object?> get props => [message];
}
class AccountUpdateSuccess extends AccountState {
  final AccountUser user;
  const AccountUpdateSuccess(this.user);
  @override List<Object?> get props => [user];
}

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final GetAccountUser  _getUser;
  final UpdateUsername  _updateUsername;
  final AccountSignOut  _signOut;

  AccountBloc({
    required GetAccountUser getUser,
    required UpdateUsername updateUsername,
    required AccountSignOut signOut,
  })  : _getUser        = getUser,
        _updateUsername = updateUsername,
        _signOut        = signOut,
        super(AccountInitial()) {
    on<AccountLoadRequested>(_onLoad);
    on<AccountSignOutRequested>(_onSignOut);
    on<AccountUsernameUpdateRequested>(_onUpdateUsername);
  }

  Future<void> _onLoad(
      AccountLoadRequested e, Emitter<AccountState> emit) async {
    emit(AccountLoading());
    final result = await _getUser();
    if (result.isLeft()) {
      emit(AccountError(result.fold((f) => f.message, (_) => '')));
      return;
    }
    emit(AccountLoaded(result.getOrElse(() => throw Exception())));
  }

  Future<void> _onSignOut(
      AccountSignOutRequested e, Emitter<AccountState> emit) async {
    await _signOut();
    emit(AccountSignedOut());
  }

  Future<void> _onUpdateUsername(
      AccountUsernameUpdateRequested e, Emitter<AccountState> emit) async {
    if (state is! AccountLoaded) return;
    final result = await _updateUsername(e.username);
    if (result.isLeft()) {
      emit(AccountError(result.fold((f) => f.message, (_) => '')));
      return;
    }
    add(AccountLoadRequested());
  }
}