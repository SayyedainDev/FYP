abstract class AppException implements Exception {
  final String message;
  final String? prefix;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException(this.message, {this.prefix, this.originalError, this.stackTrace});

  @override
  String toString() {
    return "${prefix ?? 'Error'}: $message";
  }
}

class StorageException extends AppException {
  StorageException(String message, {dynamic originalError, StackTrace? stackTrace})
      : super(message, prefix: 'Storage Error', originalError: originalError, stackTrace: stackTrace);
}

class FirestoreException extends AppException {
  FirestoreException(String message, {dynamic originalError, StackTrace? stackTrace})
      : super(message, prefix: 'Database Error', originalError: originalError, stackTrace: stackTrace);
}

class ValidationException extends AppException {
  ValidationException(String message, {dynamic originalError, StackTrace? stackTrace})
      : super(message, prefix: 'Validation Error', originalError: originalError, stackTrace: stackTrace);
}

class AIException extends AppException {
  AIException(String message, {dynamic originalError, StackTrace? stackTrace})
      : super(message, prefix: 'AI Processing Error', originalError: originalError, stackTrace: stackTrace);
}
