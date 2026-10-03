part of 'ai_bloc.dart';

abstract class AiState extends Equatable {
  const AiState();
  @override
  List<Object?> get props => [];
}

class AiInitial extends AiState {}

class AiLoaded extends AiState {
  final List<ChatMessage> messages;
  final bool isTyping;

  const AiLoaded({required this.messages, this.isTyping = false});

  AiLoaded copyWith({List<ChatMessage>? messages, bool? isTyping}) => AiLoaded(
    messages: messages ?? this.messages,
    isTyping: isTyping ?? this.isTyping,
  );

  @override
  List<Object?> get props => [messages, isTyping];
}

class AiError extends AiState {
  final String message;
  final List<ChatMessage> messages;
  const AiError({required this.message, required this.messages});
  @override
  List<Object?> get props => [message, messages];
}
