import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/usecases/auth_usecases.dart';

// ── Events ───────────────────────────────────────────────────────────────────
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  AuthSignInRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email];
}

class AuthRegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;
  AuthRegisterRequested({
    required this.username,
    required this.email,
    required this.password,
  });
  @override
  List<Object?> get props => [username, email];
}

class AuthSignOutRequested extends AuthEvent {}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;
  AuthPasswordResetRequested(this.email);
  @override
  List<Object?> get props => [email];
}

// ── States ───────────────────────────────────────────────────────────────────
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthUnauthenticated extends AuthState {}
class AuthPasswordResetSent extends AuthState {}

class AuthAuthenticated extends AuthState {
  final AppUser user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignIn _signIn;
  final Register _register;
  final GetCurrentUser _getCurrentUser;
  final SignOut _signOut;
  final SendPasswordReset _sendPasswordReset;

  AuthBloc({
    required SignIn signIn,
    required Register register,
    required GetCurrentUser getCurrentUser,
    required SignOut signOut,
    required SendPasswordReset sendPasswordReset,
  })  : _signIn = signIn,
        _register = register,
        _getCurrentUser = getCurrentUser,
        _signOut = signOut,
        _sendPasswordReset = sendPasswordReset,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthPasswordResetRequested>(_onPasswordReset);
  }

  Future<void> _onCheck(
    AuthCheckRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _getCurrentUser();

    if (result.isLeft()) {
      emit(AuthUnauthenticated());
      return;
    }

    final user = result.getOrElse(() => null);
    user != null
        ? emit(AuthAuthenticated(user))
        : emit(AuthUnauthenticated());
  }

  Future<void> _onSignIn(
    AuthSignInRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _signIn(email: e.email, password: e.password);

    if (result.isLeft()) {
      emit(AuthError(result.fold((f) => f.message, (_) => '')));
      return;
    }

    emit(AuthAuthenticated(result.getOrElse(() => throw Exception())));
  }

  Future<void> _onRegister(
    AuthRegisterRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _register(
      username: e.username,
      email: e.email,
      password: e.password,
    );

    if (result.isLeft()) {
      emit(AuthError(result.fold((f) => f.message, (_) => '')));
      return;
    }

    emit(AuthAuthenticated(result.getOrElse(() => throw Exception())));
  }

  Future<void> _onSignOut(
    AuthSignOutRequested e,
    Emitter<AuthState> emit,
  ) async {
    await _signOut();
    emit(AuthUnauthenticated());
  }

  Future<void> _onPasswordReset(
    AuthPasswordResetRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _sendPasswordReset(e.email);

    result.isLeft()
        ? emit(AuthError(result.fold((f) => f.message, (_) => '')))
        : emit(AuthPasswordResetSent());
  }
}