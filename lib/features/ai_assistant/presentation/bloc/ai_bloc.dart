import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/ai_entities.dart';
import '../../domain/usecases/ai_usecases.dart';
import '../../data/models/ai_models.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class AiEvent extends Equatable {
  @override List<Object?> get props => [];
}

class AiMessageSent extends AiEvent {
  final String message;
  AiMessageSent(this.message);
  @override List<Object?> get props => [message];
}

class AiChatCleared extends AiEvent {}

// ── States ────────────────────────────────────────────────────────────────────
abstract class AiState extends Equatable {
  const AiState();
  @override List<Object?> get props => [];
}

class AiInitial extends AiState {}

class AiLoaded extends AiState {
  final List<ChatMessage> messages;
  final bool isTyping;

  const AiLoaded({
    required this.messages,
    this.isTyping = false,
  });

  AiLoaded copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
  }) => AiLoaded(
    messages:  messages  ?? this.messages,
    isTyping:  isTyping  ?? this.isTyping,
  );

  @override
  List<Object?> get props => [messages, isTyping];
}

class AiError extends AiState {
  final String message;
  final List<ChatMessage> messages;
  const AiError({required this.message, required this.messages});
  @override List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class AiBloc extends Bloc<AiEvent, AiState> {
  final AnalyzeSymptoms _analyze;

  // Greeting message
  static final _greeting = ChatMessageModel(
    id:        const Uuid().v4(),
    content:   "Hi! I'm your CarePass AI Health Assistant 👋\n\n"
               "Describe your symptoms and I'll help guide you to the right specialist and suggest relevant tests.\n\n"
               "⚠️ Note: This is for guidance only — not a medical diagnosis.",
    role:      MessageRole.assistant,
    timestamp: DateTime.now(),
  );

  AiBloc({required AnalyzeSymptoms analyze})
      : _analyze = analyze,
        super(AiLoaded(messages: [_greeting])) {
    on<AiMessageSent>(_onMessageSent);
    on<AiChatCleared>(_onChatCleared);
  }

  Future<void> _onMessageSent(
    AiMessageSent e,
    Emitter<AiState> emit,
  ) async {
    final currentMessages = state is AiLoaded
        ? (state as AiLoaded).messages
        : [_greeting];

    // Add user message
    final userMsg = ChatMessageModel.user(e.message);
    final withUser = [...currentMessages, userMsg];

    emit(AiLoaded(messages: withUser, isTyping: true));

    // Call AI
    final result = await _analyze(
      symptoms: e.message,
      history:  currentMessages
          .where((m) => m.role != MessageRole.system)
          .toList(),
    );

    if (emit.isDone) return;

    result.fold(
      (failure) => emit(AiError(
        message:  failure.message,
        messages: withUser,
      )),
      (aiMessage) => emit(AiLoaded(
        messages: [...withUser, aiMessage],
        isTyping: false,
      )),
    );
  }

  void _onChatCleared(AiChatCleared e, Emitter<AiState> emit) {
    emit(AiLoaded(messages: [_greeting]));
  }
}