class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkException extends ApiException {
  NetworkException() : super('No internet connection.');
}

class UnauthorizedException extends ApiException {
  UnauthorizedException() : super('Session expired. Please log in again.', statusCode: 401);
}

class ServerException extends ApiException {
  ServerException(String msg) : super(msg, statusCode: 500);
}
