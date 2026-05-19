import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/card_entities.dart';
import '../../domain/usecases/card_usecases.dart';

abstract class CardEvent extends Equatable {
  @override List<Object?> get props => [];
}
class CardLoadRequested extends CardEvent {}
class CardRenewRequested extends CardEvent {
  final String planId;
  CardRenewRequested(this.planId);
  @override List<Object?> get props => [planId];
}

abstract class CardState extends Equatable {
  const CardState();
  @override List<Object?> get props => [];
}
class CardInitial extends CardState {}
class CardLoading extends CardState {}
class CardLoaded extends CardState {
  final HealthCard card;
  const CardLoaded(this.card);
  @override List<Object?> get props => [card];
}
class CardError extends CardState {
  final String message;
  const CardError(this.message);
  @override List<Object?> get props => [message];
}

class CardBloc extends Bloc<CardEvent, CardState> {
  final GetUserCard _getCard;
  final RenewCard   _renewCard;

  CardBloc({required GetUserCard getCard, required RenewCard renewCard})
      : _getCard   = getCard,
        _renewCard = renewCard,
        super(CardInitial()) {
    on<CardLoadRequested>(_onLoad);
    on<CardRenewRequested>(_onRenew);
  }

  Future<void> _onLoad(CardLoadRequested e, Emitter<CardState> emit) async {
    emit(CardLoading());
    final result = await _getCard();
    if (result.isLeft()) {
      emit(CardError(result.fold((f) => f.message, (_) => '')));
      return;
    }
    emit(CardLoaded(result.getOrElse(() => throw Exception())));
  }

  Future<void> _onRenew(CardRenewRequested e, Emitter<CardState> emit) async {
    final result = await _renewCard(e.planId);
    result.fold((_) {}, (_) => add(CardLoadRequested()));
  }
}