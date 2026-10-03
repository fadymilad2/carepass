part of 'card_bloc.dart';

abstract class CardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CardLoadRequested extends CardEvent {}

class CardRenewRequested extends CardEvent {
  final String planId;
  CardRenewRequested(this.planId);
  @override
  List<Object?> get props => [planId];
}
