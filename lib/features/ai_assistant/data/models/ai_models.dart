import 'dart:convert';
import '../../domain/entities/ai_entities.dart';
import 'package:uuid/uuid.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.content,
    required super.role,
    required super.timestamp,
    super.suggestion,
  });

  factory ChatMessageModel.user(String content) => ChatMessageModel(
    id: const Uuid().v4(),
    content: content,
    role: MessageRole.user,
    timestamp: DateTime.now(),
  );

  factory ChatMessageModel.fromApiResponse(String rawContent) {
    AiSuggestion? suggestion;
    String readableContent = rawContent; // بنبدأ بالنص كامل زي ما جه

    try {
      // 1. بندور على الـ JSON اللي فيه كلمة specialty
      final jsonMatch = RegExp(
        r'\{[\s\S]*"specialty"[\s\S]*\}',
        multiLine: true,
      ).firstMatch(rawContent);

      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;

        suggestion = AiSuggestion(
          suggestedSpecialty: data['specialty'] ?? '',
          suggestedTests: List<String>.from(data['tests'] ?? []),
          possibleConditions: List<String>.from(data['conditions'] ?? []),
          urgencyLevel: data['urgency'] ?? 'low',
          disclaimer:
              data['disclaimer'] ??
              'This is a preliminary assessment only. Please consult a licensed physician.',
        );

        // 2. التعديل السحري: نمسح كتلة الـ JSON دي بالتحديد من النص الأصلي
        readableContent = readableContent.replaceFirst(jsonStr, '');
      }
    } catch (_) {}

    // 3. ننظف أي علامات Markdown باقية
    readableContent = readableContent
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    return ChatMessageModel(
      id: const Uuid().v4(),
      content: readableContent.isNotEmpty ? readableContent : rawContent,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      suggestion: suggestion,
    );
  } 

  Map<String, dynamic> toApiFormat() => {
    'role': role == MessageRole.user ? 'user' : 'assistant',
    'content': content,
  };
}
