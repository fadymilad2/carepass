class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Network error']);
}

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException([this.message = 'Server error', this.statusCode]);
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Auth error']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error']);
}

class PaymentException implements Exception {
  final String message;
  const PaymentException([this.message = 'Payment error']);
}