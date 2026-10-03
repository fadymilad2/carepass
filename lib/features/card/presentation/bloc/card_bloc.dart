import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/card_entities.dart';
import '../../domain/usecases/card_usecases.dart';

part 'card_event.dart';
part 'card_state.dart';

class CardBloc extends Bloc<CardEvent, CardState> {
  final GetUserCard _getCard;
  final RenewCard _renewCard;

  // ✅ New — how many silent retries to attempt before actually
  // showing the user an error screen, and how long to wait between
  // them. 3 attempts with a short growing delay comfortably covers
  // the brief window right after registration where the user's
  // Firestore document may not be immediately readable yet, without
  // making a genuinely broken load feel like it's hanging forever.
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 600);

  CardBloc({
    required GetUserCard getCard,
    required RenewCard renewCard,
    required FirebaseAuth auth,
  }) : _getCard = getCard,
       _renewCard = renewCard,
       super(const CardInitial()) {
    on<CardLoadRequested>(_onLoad);
    on<CardRenewRequested>(_onRenew);
  }

  // ✅ Fixed — was a single unconditional attempt: any failure
  // (including a transient "user document not ready yet" race right
  // after sign-up) went straight to CardError with a "Try Again"
  // button. Now it silently retries a few times first — the user
  // just sees a normal loading spinner the whole time (CardLoading
  // is only emitted once, up front, so there's no flicker between
  // attempts) — and only falls through to a real error state if it
  // still hasn't succeeded after all retries, which means something
  // is actually wrong rather than just bad timing.
  Future<void> _onLoad(CardLoadRequested e, Emitter<CardState> emit) async {
    // Always show a loading indicator while we attempt to fetch the card.
    emit(const CardLoading());

    // We will try to fetch the card multiple times. This handles transient
    // issues like network flakes or, more commonly, the delay in Firebase
    // Auth state propagating to the client right after login. The user will
    // only see a loading spinner during these retries.
    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      final result = await _getCard();

      if (result.isRight()) {
        result.fold((_) {}, (card) => emit(CardLoaded(card)));
        return; // Success, exit the loop
      }

      final isLastAttempt = attempt == _maxRetries;
      if (isLastAttempt) {
        // If all retries fail, we finally show an error to the user.
        // This could be due to being logged out, network issues, or a
        // server problem.
        emit(CardError(result.fold((f) => f.message, (_) => '')));
        return;
      }

      // Use exponential backoff for the delay, waiting longer each time.
      // e.g., 600ms, then 1200ms, then 1800ms.
      await Future.delayed(_retryDelay * attempt);

      // If a newer CardLoadRequested (or anything else) came in
      // while we were waiting, abandon this stale retry loop rather
      // than emitting a state that might race with the newer call.
      if (emit.isDone) return;
    }
  }

  Future<void> _onRenew(CardRenewRequested e, Emitter<CardState> emit) async {
    emit(const CardLoading());
    final result = await _renewCard(e.planId);
    result.fold(
      // On failure, show an error to the user.
      (failure) => emit(CardError(failure.message)),
      // On success, trigger a reload to get the new card data.
      (_) => add(CardLoadRequested()),
    );
  }
}
