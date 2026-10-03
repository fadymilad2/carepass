part of 'ai_bloc.dart';

abstract class AiEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AiMessageSent extends AiEvent {
  final String message;
  AiMessageSent(this.message);
  @override
  List<Object?> get props => [message];
}

class AiChatCleared extends AiEvent {}
