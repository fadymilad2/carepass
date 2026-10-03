import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/usecases/auth_usecases.dart';

// ── Events ────────────────────────────────────────────────────────────
part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendOtp _sendOtp;
  final VerifyOtp _verifyOtp;
  final CreateProfile _createProfile;
  final GetCurrentUser _getCurrentUser;
  final SignOut _signOut;

  AuthBloc({
    required SendOtp sendOtp,
    required VerifyOtp verifyOtp,
    required CreateProfile createProfile,
    required GetCurrentUser getCurrentUser,
    required SignOut signOut,
  }) : _sendOtp = sendOtp,
       _verifyOtp = verifyOtp,
       _createProfile = createProfile,
       _getCurrentUser = getCurrentUser,
       _signOut = signOut,
       super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthSendOtpRequested>(_onSendOtp);
    on<AuthVerifyOtpRequested>(_onVerifyOtp);
    on<AuthCreateProfileRequested>(_onCreateProfile);
    on<AuthSignOutRequested>(_onSignOut);
  }

  Future<void> _onCheck(AuthCheckRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _getCurrentUser();
    result.fold((failure) => emit(AuthUnauthenticated()), (user) {
      if (user == null) {
        emit(AuthUnauthenticated());
      } else if (!user.hasProfile) {
        emit(AuthNeedsProfile(uid: user.uid, phoneNumber: user.phoneNumber));
      } else {
        emit(AuthAuthenticated(user));
      }
    });
  }

  Future<void> _onSendOtp(
    AuthSendOtpRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _sendOtp(e.phoneNumber);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (verificationId) => emit(
        AuthOtpSent(verificationId: verificationId, phoneNumber: e.phoneNumber),
      ),
    );
  }

  Future<void> _onVerifyOtp(
    AuthVerifyOtpRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _verifyOtp(
      verificationId: e.verificationId,
      otp: e.otp,
    );
    result.fold((failure) => emit(AuthError(failure.message)), (user) {
      if (!user.hasProfile) {
        emit(AuthNeedsProfile(uid: user.uid, phoneNumber: user.phoneNumber));
      } else {
        emit(AuthAuthenticated(user));
      }
    });
  }

  Future<void> _onCreateProfile(
    AuthCreateProfileRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    // ✅ Pass all new fields to use case
    final result = await _createProfile(
      uid: e.uid,
      username: e.username,
      phoneNumber: e.phoneNumber,
      email: e.email,
      dateOfBirth: e.dateOfBirth,
      city: e.city,
      emergencyContact: e.emergencyContact,
      bloodType: e.bloodType,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignOut(
    AuthSignOutRequested e,
    Emitter<AuthState> emit,
  ) async {
    final result = await _signOut();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }
}
