import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/account_entities.dart';
import '../../domain/usecases/account_usecases.dart';

// ── Events ────────────────────────────────────────────────────────────
part 'account_event.dart';
part 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final GetAccountUser _getUser;
  final UpdateUsername _updateUsername;
  final UpdateProfile _updateProfile; // ✅ New use case
  final AccountSignOut _signOut;
  final DeleteAccount _deleteAccount;
  bool _deleting = false;
  int _revision = 0;

  AccountBloc({
    required GetAccountUser getUser,
    required UpdateUsername updateUsername,
    required UpdateProfile updateProfile,
    required AccountSignOut signOut,
    required DeleteAccount deleteAccount,
  }) : _getUser = getUser,
       _updateUsername = updateUsername,
       _updateProfile = updateProfile,
       _signOut = signOut,
       _deleteAccount = deleteAccount,
       super(AccountInitial()) {
    on<AccountLoadRequested>(_onLoad);
    on<AccountDeleteRequested>(_onDelete);
    on<AccountSignOutRequested>(_onSignOut);
    on<AccountUsernameUpdateRequested>(_onUpdateUsername);
    on<AccountProfileUpdateRequested>(_onUpdateProfile); // ✅
  }

  // ── Load ─────────────────────────────────────────────────────────────
  Future<void> _onLoad(
    AccountLoadRequested e,
    Emitter<AccountState> emit,
  ) async {
    if (_deleting) return;
    final revision = ++_revision;
    emit(AccountLoading());
    final result = await _getUser();
    if (_deleting || revision != _revision) return;
    result.fold(
      (failure) => emit(AccountError(failure.message)),
      (user) => emit(AccountLoaded(user)),
    );
  }

  Future<void> _onDelete(
    AccountDeleteRequested event,
    Emitter<AccountState> emit,
  ) async {
    if (_deleting || state is! AccountLoaded) return;
    final user = (state as AccountLoaded).user;
    _deleting = true;
    _revision++;
    emit(AccountLoading());
    final result = await _deleteAccount();
    result.fold(
      (failure) {
        _deleting = false;
        emit(AccountDeletionFailed(user, failure.message));
      },
      (_) {
        _deleting = false;
        emit(AccountDeleted());
      },
    );
  }

  // ── Sign Out ─────────────────────────────────────────────────────────
  Future<void> _onSignOut(
    AccountSignOutRequested e,
    Emitter<AccountState> emit,
  ) async {
    if (_deleting) return;
    final revision = ++_revision;
    final result = await _signOut();
    if (_deleting || revision != _revision) return;
    result.fold(
      (failure) => emit(AccountError(failure.message)),
      (_) => emit(AccountSignedOut()),
    );
  }

  // ── Update Username ───────────────────────────────────────────────────
  Future<void> _onUpdateUsername(
    AccountUsernameUpdateRequested e,
    Emitter<AccountState> emit,
  ) async {
    if (state is! AccountLoaded) return;
    final revision = _revision;
    final result = await _updateUsername(e.username);
    if (_deleting || revision != _revision) return;
    result.fold(
      (failure) => emit(AccountError(failure.message)),
      (_) => add(AccountLoadRequested()),
    );
  }

  // ── Update Profile ✅ ─────────────────────────────────────────────────
  Future<void> _onUpdateProfile(
    AccountProfileUpdateRequested e,
    Emitter<AccountState> emit,
  ) async {
    if (state is! AccountLoaded) return;
    final currentUser = (state as AccountLoaded).user;
    final revision = _revision;

    final result = await _updateProfile(
      email: e.email,
      city: e.city,
      bloodType: e.bloodType,
      emergencyContact: e.emergencyContact,
    );
    if (_deleting || revision != _revision) return;

    result.fold(
      (failure) => emit(AccountError(failure.message)),
      (_) => emit(AccountUpdateSuccess(currentUser)),
    );

    // Reload to get updated data
    add(AccountLoadRequested());
  }
}
