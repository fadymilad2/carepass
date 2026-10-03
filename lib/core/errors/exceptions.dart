class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Network error']);

  @override
  String toString() => message;
}

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException([this.message = 'Server error', this.statusCode]);

  @override
  String toString() => message; // ✅ ده السطر السحري اللي هيظهر الإيرور الحقيقي
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Auth error']);

  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error']);

  @override
  String toString() => message;
}

class PaymentException implements Exception {
  final String message;
  const PaymentException([this.message = 'Payment error']);

  @override
  String toString() => message;
}
