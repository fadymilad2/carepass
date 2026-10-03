import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/payment_entities.dart';

abstract class PaymentRepository {
  Future<Either<Failure, List<SubscriptionPlan>>> getPlans();

  Future<Either<Failure, PaymentCheckout>> initializePayment({
    required String email,
    required String planId,
    required double amount,
    required String currency,
  });

  Future<Either<Failure, PaymentVerification>> verifyPayment(String reference);

  Future<Either<Failure, void>> saveTransaction(PaymentTransaction transaction);
}
