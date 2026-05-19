import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/card_entities.dart';
import '../repositories/card_repository.dart';

class GetUserCard {
  final CardRepository repo;
  GetUserCard(this.repo);
  Future<Either<Failure, HealthCard>> call() => repo.getUserCard();
}

class RenewCard {
  final CardRepository repo;
  RenewCard(this.repo);
  Future<Either<Failure, void>> call(String planId) =>
      repo.renewCard(planId);
}