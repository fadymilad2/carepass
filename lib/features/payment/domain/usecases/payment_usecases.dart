import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/payment_entities.dart';
import '../repositories/payment_repository.dart';

class GetPlans {
  final PaymentRepository repo;
  GetPlans(this.repo);
  Future<Either<Failure, List<SubscriptionPlan>>> call() => repo.getPlans();
}

class InitializePayment {
  final PaymentRepository repo;
  InitializePayment(this.repo);
  Future<Either<Failure, PaymentCheckout>> call({
    required String email,
    required String planId,
    required double amount,
    required String currency,
  }) => repo.initializePayment(
    email: email,
    planId: planId,
    amount: amount,
    currency: currency,
  );
}

class VerifyPayment {
  final PaymentRepository repo;
  VerifyPayment(this.repo);
  Future<Either<Failure, PaymentVerification>> call(String reference) =>
      repo.verifyPayment(reference);
}
