import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────
//  Failures (Domain Layer)
// ─────────────────────────────────────────────
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error, please try again later']);
}

class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Authentication failed, please try again',
  ]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local data error']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Data not found']);
}

class PaymentFailure extends Failure {
  const PaymentFailure([super.message = 'Payment failed, please try again']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([
    super.message = 'Permissions are required to proceed',
  ]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
