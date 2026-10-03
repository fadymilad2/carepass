part of 'card_bloc.dart';

abstract class CardState extends Equatable {
  const CardState();
  @override
  List<Object?> get props => [];
}

class CardInitial extends CardState {
  const CardInitial();
}

class CardLoading extends CardState {
  const CardLoading();
}

class CardLoaded extends CardState {
  final HealthCard card;
  const CardLoaded(this.card);
  @override
  List<Object?> get props => [card];
}

class CardError extends CardState {
  final String message;
  const CardError(this.message);
  @override
  List<Object?> get props => [message];
}
