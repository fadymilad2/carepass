import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ai_entities.dart';

abstract class AiAssistantRepository {
  Future<Either<Failure, ChatMessage>> analyzeSymptoms({
    required String symptoms,
    required List<ChatMessage> history,
  });

  Future<Either<Failure, void>> clearHistory();
}