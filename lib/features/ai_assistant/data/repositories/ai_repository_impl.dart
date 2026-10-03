import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/ai_entities.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_remote_datasource.dart';

class AiAssistantRepositoryImpl implements AiAssistantRepository {
  final AiRemoteDataSource _remote;
  AiAssistantRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, ChatMessage>> analyzeSymptoms({
    required String symptoms,
    required List<ChatMessage> history,
  }) async {
    try {
      final result = await _remote.analyzeSymptoms(
        symptoms: symptoms,
        history: history,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure('AI service unavailable'));
    }
  }

  @override
  Future<Either<Failure, void>> clearHistory() async => const Right(null);
}
