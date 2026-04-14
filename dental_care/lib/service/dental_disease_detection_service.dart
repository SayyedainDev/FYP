import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../models/detection_response.dart';

/// Service for communicating with the Dental Disease Detection backend.
///
/// Base URL: https://sayyedain-dental-disease-detection.hf.space
/// No authentication required. Plain REST only.
class DentalDetectionApiService {
  static const String baseUrl =
      'https://sayyedain-dental-disease-detection.hf.space';
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration healthPollInterval = Duration(seconds: 15);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 10);
  static const int maxImageEdge = 2048;

  // ---------------------------------------------------------------------------
  // Health Check: GET /
  // ---------------------------------------------------------------------------

  /// Pings the server. Returns `true` if it responds with 200.
  static Future<bool> healthCheck() async {
    try {
      final response =
          await http.get(Uri.parse(baseUrl)).timeout(requestTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Polls `GET /` every [healthPollInterval] until the server is warm.
  /// Calls [onStatusChange] with progress messages.
  /// Returns once the server responds with 200.
  static Future<void> waitForServerReady({
    required void Function(String message) onStatusChange,
  }) async {
    onStatusChange('Checking AI server status...');

    if (await healthCheck()) {
      onStatusChange('AI server is ready.');
      return;
    }

    onStatusChange('Preparing AI model, this may take a few minutes...');

    while (true) {
      await Future.delayed(healthPollInterval);
      if (await healthCheck()) {
        onStatusChange('AI server is ready.');
        return;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Image Resize (client-side, runs in isolate)
  // ---------------------------------------------------------------------------

  /// Resizes [imageBytes] so the longest edge is at most [maxImageEdge] px.
  /// Returns the original bytes if no resize is needed.
  /// Runs in a background isolate via [compute].
  static Future<Uint8List> resizeIfNeeded(Uint8List imageBytes) async {
    return compute(_resizeWorker, imageBytes);
  }

  static Uint8List _resizeWorker(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    final longestEdge =
        decoded.width > decoded.height ? decoded.width : decoded.height;

    if (longestEdge <= maxImageEdge) return bytes;

    final ratio = maxImageEdge / longestEdge;
    final newWidth = (decoded.width * ratio).round();
    final newHeight = (decoded.height * ratio).round();

    final resized = img.copyResize(
      decoded,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );

    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }

  // ---------------------------------------------------------------------------
  // Detection: POST /coordinates
  // ---------------------------------------------------------------------------

  /// Sends [imageBytes] to `POST /coordinates` as multipart form with
  /// field name `"image"`. Returns a parsed [DetectionResponse].
  ///
  /// Implements retry logic: up to [maxRetries] attempts with [retryDelay]
  /// between each on timeout or 503 errors.
  static Future<DetectionResponse> runDetection({
    required Uint8List imageBytes,
    required String filename,
    void Function(String message)? onStatusChange,
  }) async {
    // 1. Resize image if necessary
    onStatusChange?.call('Preparing image...');
    final resizedBytes = await resizeIfNeeded(imageBytes);

    // 2. Attempt upload with retry logic
    int attempt = 0;
    while (true) {
      attempt++;
      onStatusChange?.call(
        attempt == 1
            ? 'Uploading image & running AI detection...'
            : 'Retrying detection (attempt $attempt/$maxRetries)...',
      );

      try {
        final uri = Uri.parse('$baseUrl/coordinates');
        final request = http.MultipartRequest('POST', uri);

        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            resizedBytes,
            filename: filename,
          ),
        );

        final streamResponse = await request.send().timeout(requestTimeout);
        final response = await http.Response.fromStream(streamResponse);

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body) as Map<String, dynamic>;
          // Parse error = data issue, not network — fail immediately, no retry
          try {
            return DetectionResponse.fromJson(jsonData);
          } catch (parseError, st) {
            debugPrint('[Detection] Parse error: $parseError\n$st');
            debugPrint(
              '[Detection] Raw body (first 500): ${response.body.substring(0, response.body.length.clamp(0, 500))}',
            );
            throw DentalApiException(
              'Failed to parse detection results. The server returned '
              'unexpected data. Please contact support.\n\nDetail: $parseError',
              200,
            );
          }
        }

        if (response.statusCode == 400) {
          // Client error — do not retry
          final body = _tryDecodeJson(response.body);
          final msg = body?['error'] ?? body?['message'] ?? response.body;
          throw DentalApiException('Bad request: $msg', response.statusCode);
        }

        if (response.statusCode == 503 && attempt < maxRetries) {
          // Service unavailable — retry after delay
          await Future.delayed(retryDelay);
          continue;
        }

        // Other server errors
        throw DentalApiException(
          'Server error (HTTP ${response.statusCode})',
          response.statusCode,
        );
      } on TimeoutException {
        if (attempt < maxRetries) {
          onStatusChange?.call(
            'Request timed out. Waiting ${retryDelay.inSeconds}s before retry...',
          );
          await Future.delayed(retryDelay);
          continue;
        }
        throw const DentalApiException(
          'Server is unavailable. Please try again in a few minutes.',
          0,
        );
      } on DentalApiException {
        rethrow;
      } catch (e) {
        if (attempt < maxRetries) {
          await Future.delayed(retryDelay);
          continue;
        }
        throw const DentalApiException(
          'Connection failed after $maxRetries attempts. Please try again.',
          0,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static Map<String, dynamic>? _tryDecodeJson(String body) {
    try {
      return json.decode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

/// Custom exception for API errors.
class DentalApiException implements Exception {
  final String message;
  final int statusCode;

  const DentalApiException(this.message, this.statusCode);

  @override
  String toString() => 'DentalApiException($statusCode): $message';
}
