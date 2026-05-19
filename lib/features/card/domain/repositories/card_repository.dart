import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/card_entities.dart';

abstract class CardRepository {
  Future<Either<Failure, HealthCard>> getUserCard();
  Future<Either<Failure, void>> renewCard(String planId);
}