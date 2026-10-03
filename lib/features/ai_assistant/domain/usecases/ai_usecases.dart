import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ai_entities.dart';
import '../repositories/ai_repository.dart';

class AnalyzeSymptoms {
  final AiAssistantRepository repo;
  AnalyzeSymptoms(this.repo);

  Future<Either<Failure, ChatMessage>> call({
    required String symptoms,
    required List<ChatMessage> history,
  }) => repo.analyzeSymptoms(symptoms: symptoms, history: history);
}
