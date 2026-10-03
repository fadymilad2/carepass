import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/ai_entities.dart';
import '../../domain/usecases/ai_usecases.dart';
import '../../data/models/ai_models.dart';

// ── Events ────────────────────────────────────────────────────────────────────
part 'ai_event.dart';
part 'ai_state.dart';

class AiBloc extends Bloc<AiEvent, AiState> {
  final AnalyzeSymptoms _analyze;
  int _conversationVersion = 0;

  static final _greeting = ChatMessageModel(
    id: const Uuid().v4(),
    content:
        "Hi! I'm your CarePass AI Health Assistant 👋\n\n"
        "Describe your symptoms and I'll help guide you to the right "
        "specialist and suggest relevant tests.\n\n"
        "⚠️ Note: This is for guidance only — not a medical diagnosis.",
    role: MessageRole.assistant,
    timestamp: DateTime.now(),
  );

  AiBloc({required AnalyzeSymptoms analyze})
    : _analyze = analyze,
      super(AiLoaded(messages: [_greeting])) {
    on<AiMessageSent>(_onMessageSent);
    on<AiChatCleared>(_onChatCleared);
  }

  // ✅ Fixed — أدق في شيل الـ JSON block من آخر الرسالة
  // بيدور على آخر "{" وبيتأكد إنه فعلاً JSON صحيح (بيقفل بـ "}"
  // ومحتوي على "specialty") قبل ما يشيله — مش بيعتمد على وجود
  // سطر جديد قبله زي الطريقة القديمة اللي كانت بتفشل أحياناً.
  String _cleanResponse(String content) {
    final trimmed = content.trim();

    // ✅ الخطوة 1 — شيل أي ```json ... ``` fenced block في أي مكان
    final fenced = RegExp(r'```json[\s\S]*?```', multiLine: true);
    var cleaned = trimmed.replaceAll(fenced, '').trim();

    // ✅ الخطوة 2 — شيل الـ JSON الخام {"specialty": ...} من آخر النص
    final lastOpenBrace = cleaned.lastIndexOf('{');
    if (lastOpenBrace != -1) {
      final candidate = cleaned.substring(lastOpenBrace).trim();
      if (candidate.endsWith('}') && candidate.contains('"specialty"')) {
        cleaned = cleaned.substring(0, lastOpenBrace).trim();
      }
    }

    // ✅ لو المسح شال كل حاجة بالغلط، ارجع للنص الأصلي بدل ما يبان فاضي
    return cleaned.isEmpty ? trimmed : cleaned;
  }

  Future<void> _onMessageSent(AiMessageSent e, Emitter<AiState> emit) async {
    if (e.message.trim().isEmpty ||
        (state is AiLoaded && (state as AiLoaded).isTyping)) {
      return;
    }
    final version = _conversationVersion;
    final currentMessages = state is AiLoaded
        ? (state as AiLoaded).messages
        : state is AiError
        ? (state as AiError).messages
        : <ChatMessage>[_greeting];

    // User message
    final userMsg = ChatMessageModel.user(e.message);
    final withUser = [...currentMessages, userMsg];

    // Show typing
    emit(AiLoaded(messages: withUser, isTyping: true));

    // Call usecase
    final result = await _analyze(
      symptoms: e.message,
      history: currentMessages
          .where((m) => m.role != MessageRole.system)
          .toList(),
    );

    if (emit.isDone || version != _conversationVersion) return;

    result.fold(
      (failure) {
        emit(AiError(message: failure.message, messages: withUser));
      },
      (aiMessage) {
        // ✅ نظّف الـ JSON من الرسالة قبل ما تظهر للمستخدم
        final cleanContent = _cleanResponse(aiMessage.content);

        final cleanMessage = ChatMessageModel(
          id: aiMessage.id,
          content: cleanContent,
          role: aiMessage.role,
          timestamp: aiMessage.timestamp,
          suggestion: aiMessage.suggestion,
        );

        emit(AiLoaded(messages: [...withUser, cleanMessage], isTyping: false));
      },
    );
  }

  void _onChatCleared(AiChatCleared e, Emitter<AiState> emit) {
    _conversationVersion++;
    emit(AiLoaded(messages: [_greeting]));
  }
}
