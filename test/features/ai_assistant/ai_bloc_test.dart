import 'dart:async';
import 'package:carepass/core/errors/failures.dart';
import 'package:carepass/features/ai_assistant/domain/entities/ai_entities.dart';
import 'package:carepass/features/ai_assistant/domain/repositories/ai_repository.dart';
import 'package:carepass/features/ai_assistant/domain/usecases/ai_usecases.dart';
import 'package:carepass/features/ai_assistant/presentation/bloc/ai_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAi implements AiAssistantRepository {
  final pending = Completer<Either<Failure, ChatMessage>>();
  @override
  Future<Either<Failure, ChatMessage>> analyzeSymptoms({
    required String symptoms,
    required List<ChatMessage> history,
  }) => pending.future;
  @override
  Future<Either<Failure, void>> clearHistory() async => const Right(null);
}

void main() {
  test('clearing chat discards a late response', () async {
    final repo = FakeAi();
    final bloc = AiBloc(analyze: AnalyzeSymptoms(repo));
    addTearDown(bloc.close);
    final typing = bloc.stream.firstWhere((s) => s is AiLoaded && s.isTyping);
    bloc.add(AiMessageSent('headache'));
    await typing;
    final cleared = bloc.stream.firstWhere((s) => s is AiLoaded && !s.isTyping);
    bloc.add(AiChatCleared());
    await cleared;
    repo.pending.complete(
      Right(
        ChatMessage(
          id: 'late',
          content: 'Late response',
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect((bloc.state as AiLoaded).messages, hasLength(1));
  });
  test('assistant suggestions survive display cleanup', () async {
    final repo = FakeAi();
    final bloc = AiBloc(analyze: AnalyzeSymptoms(repo));
    addTearDown(bloc.close);
    final done = bloc.stream.firstWhere(
      (s) => s is AiLoaded && s.messages.length == 3,
    );
    bloc.add(AiMessageSent('headache'));
    const suggestion = AiSuggestion(
      suggestedSpecialty: 'General Practitioner',
      suggestedTests: [],
      possibleConditions: [],
      urgencyLevel: 'low',
      disclaimer: 'Consult a doctor.',
    );
    repo.pending.complete(
      Right(
        ChatMessage(
          id: 'reply',
          content: 'Consult a doctor.',
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
          suggestion: suggestion,
        ),
      ),
    );
    final state = await done;
    expect((state as AiLoaded).messages.last.suggestion, suggestion);
  });
}
