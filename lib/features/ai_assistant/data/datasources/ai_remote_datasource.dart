import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/ai_models.dart';
import '../../domain/entities/ai_entities.dart';

abstract class AiRemoteDataSource {
  Future<ChatMessageModel> analyzeSymptoms({
    required String symptoms,
    required List<ChatMessage> history,
  });
}

class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  final FirebaseFunctions _functions;

  AiRemoteDataSourceImpl({required FirebaseFunctions functions})
    : _functions = functions;

  @override
  Future<ChatMessageModel> analyzeSymptoms({
    required String symptoms,
    required List<ChatMessage> history,
  }) async {
    try {
      // ── 1. Check auth ──────────────────────────────────────────────────
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw const ServerException('Session expired. Please login again.');
      }

      // ── 2. Refresh token ───────────────────────────────────────────────
      await user.getIdToken(true);

      // ── 3. Build message ───────────────────────────────────────────────
      final buffer = StringBuffer();

      if (history.isNotEmpty) {
        buffer.writeln('--- Chat History ---');
        for (final msg in history) {
          // Skip greeting message
          if (msg.content.contains("CarePass AI Health Assistant")) {
            continue;
          }
          final role = msg.isUser ? 'Patient' : 'AI Assistant';
          buffer.writeln('$role: ${msg.content}');
        }
        buffer.writeln('--- End History ---\n');
      }

      buffer.writeln('Patient (current message): $symptoms');

      // ── 4. Call Cloud Function ─────────────────────────────────────────
      final callable = _functions.httpsCallable(
        'aiHealthAssistant',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );

      final result = await callable.call<Map<String, dynamic>>({
        'message': buffer.toString(),
        'userId': user.uid,
      });

      // ── 5. Parse response ──────────────────────────────────────────────
      final data = result.data;
      final content = data['content'] as String? ?? '';

      if (content.isEmpty) {
        throw const ServerException('Empty response from AI');
      }

      return ChatMessageModel.fromApiResponse(content);
    } on FirebaseFunctionsException catch (e) {
      // ✅ Map error codes to readable messages
      final msg = _mapFunctionError(e);
      throw ServerException(msg);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('AI service error: $e');
    }
  }

  String _mapFunctionError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Session expired. Please login again.';
      case 'not-found':
        return 'AI model unavailable. Please try again later.';
      case 'deadline-exceeded':
        return 'Request timed out. Please try again.';
      case 'resource-exhausted':
        return 'Too many requests. Please wait a moment.';
      case 'internal':
        // Check if it's a model error
        if (e.message?.contains('not found') == true ||
            e.message?.contains('404') == true) {
          return 'AI model configuration error. Contact support.';
        }
        return e.message ?? 'AI service unavailable.';
      default:
        return e.message ?? 'Something went wrong.';
    }
  }
}
