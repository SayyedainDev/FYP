import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderErrorUtils {
  static const Duration requestTimeout = Duration(seconds: 30);

  static Future<T> withTimeout<T>(Future<T> future) {
    return future.timeout(requestTimeout);
  }

  static String mapErrorMessage(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    if (error is TimeoutException) {
      return 'The request timed out. Check your connection and try again.';
    }

    if (error is SocketException) {
      return 'No internet connection. Check your network and try again.';
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
        case 'forbidden':
          return 'You do not have permission to perform this action.';
        case 'unauthenticated':
        case 'invalid-auth':
          return 'Your session has expired. Please log in again.';
        case 'not-found':
          return 'The requested item could not be found.';
        case 'deadline-exceeded':
          return 'The request timed out. Check your connection and try again.';
      }
    }

    final raw = error.toString().toLowerCase();
    if (raw.contains('401') ||
        raw.contains('unauthorized') ||
        raw.contains('token')) {
      return 'Your session has expired. Please log in again.';
    }
    if (raw.contains('403') ||
        raw.contains('forbidden') ||
        raw.contains('permission')) {
      return 'You do not have permission to perform this action.';
    }
    if (raw.contains('404') || raw.contains('not found')) {
      return 'The requested item could not be found.';
    }
    if (raw.contains('socketexception') || raw.contains('network')) {
      return 'No internet connection. Check your network and try again.';
    }
    if (raw.contains('timeout') || raw.contains('deadline')) {
      return 'The request timed out. Check your connection and try again.';
    }
    if (raw.contains('500') || raw.contains('internal server')) {
      return 'Something went wrong on our end. Please try again.';
    }

    return fallback;
  }
}
