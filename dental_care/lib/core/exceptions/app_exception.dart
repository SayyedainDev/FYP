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
  StorageException(super.message, {super.originalError, super.stackTrace})
      : super(prefix: 'Storage Error');
}

class FirestoreException extends AppException {
  FirestoreException(super.message, {super.originalError, super.stackTrace})
      : super(prefix: 'Database Error');
}

class ValidationException extends AppException {
  ValidationException(super.message, {super.originalError, super.stackTrace})
      : super(prefix: 'Validation Error');
}

class AIException extends AppException {
  AIException(super.message, {super.originalError, super.stackTrace})
      : super(prefix: 'AI Processing Error');
}
