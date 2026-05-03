import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/quiz.dart';
import 'groq_service.dart';

Uint8List processPDF(Uint8List bytes) {
  // Add any intensive PDF processing logic here if needed.
  // Running in an async isolate via `compute` prevents UI blocks.
  return bytes;
}

class RagService {
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://fyp-groq.onrender.com',
  );
  static const Duration _uploadTimeout = Duration(seconds: 120);
  static const Duration _generationTimeout = Duration(seconds: 90);

  static const List<String> _uploadEndpoints = [
    '/api/upload-pdf',
    '/upload-pdf',
    '/api/upload',
  ];

  static const List<String> _generateEndpoints = [
    '/api/generate-rag-quiz',
    '/generate-rag-quiz',
    '/api/generate-quiz-from-kb',
    '/api/generate-from-kb',
  ];

  static const List<String> _attachEndpoints = [
    '/api/attach-document',
    '/api/attach-kb',
    '/api/index-document',
    '/api/build-knowledge-base',
    '/api/prepare-rag',
    '/api/process-document',
  ];

  static bool _looksLikeKnowledgeBaseMissing(String body) {
    final lower = body.toLowerCase();
    return lower.contains('knowledge base') ||
        lower.contains('upload first') ||
        lower.contains('not indexed') ||
        lower.contains('indexing');
  }

  static Future<String> _uploadToAnyEndpoint(
      Uint8List bytes, String filename) async {
    String? lastError;

    for (final endpoint in _uploadEndpoints) {
      try {
        final uri = Uri.parse('$baseUrl$endpoint');
        final request = http.MultipartRequest('POST', uri)
          ..files.add(
              http.MultipartFile.fromBytes('file', bytes, filename: filename));

        final response = await request.send().timeout(_uploadTimeout);
        final responseData =
            await response.stream.bytesToString().timeout(_uploadTimeout);

        if (response.statusCode == 200) {
          final json = jsonDecode(responseData) as Map<String, dynamic>;
          final docId = json['documentId']?.toString() ??
              json['docId']?.toString() ??
              json['id']?.toString() ??
              '';
          if (docId.isNotEmpty) {
            debugPrintSynchronously(
                '✅ PDF uploaded via $endpoint (DocID: $docId)');
            return docId;
          }
          lastError = 'Upload succeeded but no documentId returned';
          continue;
        }

        lastError = 'Upload failed at $endpoint (${response.statusCode})';
      } catch (e) {
        lastError = 'Upload exception at $endpoint: $e';
      }
    }

    throw GroqException(lastError ?? 'Failed to upload PDF.');
  }

  static Future<void> _attachKnowledgeBaseIfSupported(
      Map<String, dynamic> requestBody) async {
    for (final endpoint in _attachEndpoints) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl$endpoint'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestBody),
            )
            .timeout(_generationTimeout);

        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrintSynchronously(
              '🔗 Knowledge base attached/indexed via $endpoint');
          return;
        }
      } catch (_) {
        // Ignore endpoint mismatch and try the next attach path.
      }
    }
  }

  static Future<String> uploadPdfBytes(Uint8List bytes, String filename,
      {void Function(double)? onProgress}) async {
    if (bytes.length > 10 * 1024 * 1024) {
      throw GroqException('File too large. Please upload a PDF under 10MB.');
    } else if (bytes.length > 2 * 1024 * 1024) {
      debugPrintSynchronously(
          'Large file detected, compressing... (Warning only)');
    }

    final processedBytes = await compute(processPDF, bytes);

    Future<String> attemptUpload() async {
      debugPrintSynchronously(
          '📤 Uploading PDF bytes ($filename, ${processedBytes.length} bytes)...');
      return _uploadToAnyEndpoint(processedBytes, filename);
    }

    int maxAttempts = 3;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await attemptUpload();
      } catch (e) {
        if (attempt == maxAttempts - 1) {
          if (e is GroqException) rethrow;
          throw GroqException('Upload failed after retries: ${e.toString()}');
        }
        int delaySeconds = pow(2, attempt).toInt() * 5;
        debugPrintSynchronously(
            '⏱️ Upload failed. Retrying in $delaySeconds s...');
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
    throw GroqException('Upload failed completely.');
  }

  static Future<String> uploadPdfFile(File file,
      {void Function(double)? onProgress}) async {
    final rawBytes = await file.readAsBytes();
    if (rawBytes.length > 10 * 1024 * 1024) {
      throw GroqException('File too large. Please upload a PDF under 10MB.');
    } else if (rawBytes.length > 2 * 1024 * 1024) {
      debugPrintSynchronously(
          'Large file detected, compressing... (Warning only)');
    }

    final processedBytes = await compute(processPDF, rawBytes);

    Future<String> attemptUpload() async {
      debugPrintSynchronously('📤 Uploading PDF file (${file.path})...');
      return _uploadToAnyEndpoint(processedBytes, file.uri.pathSegments.last);
    }

    int maxAttempts = 3;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await attemptUpload();
      } catch (e) {
        if (attempt == maxAttempts - 1) {
          if (e is GroqException) rethrow;
          throw GroqException('Upload failed after retries: ${e.toString()}');
        }
        int delaySeconds = pow(2, attempt).toInt() * 5;
        debugPrintSynchronously(
            '⏱️ Upload failed. Retrying in $delaySeconds s...');
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
    throw GroqException('Upload failed completely.');
  }

  static Future<String> uploadRawText(String text) async {
    try {
      debugPrintSynchronously(
          '📤 Uploading raw text (${text.length} characters)...');
      final uri = Uri.parse('$baseUrl${_uploadEndpoints.first}');
      final request = http.MultipartRequest('POST', uri)..fields['text'] = text;

      debugPrintSynchronously('⏳ Waiting for upload response...');
      final response = await request.send().timeout(_uploadTimeout);
      final responseData =
          await response.stream.bytesToString().timeout(_uploadTimeout);

      debugPrintSynchronously(
          '📡 Upload response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(responseData) as Map<String, dynamic>;
        final docId = json['documentId']?.toString() ?? '';
        debugPrintSynchronously('✅ Text uploaded successfully (DocID: $docId)');
        return docId;
      }

      debugPrintSynchronously('❌ Upload failed. Response: $responseData');

      String errorMsg = 'Failed to process text. Please try again.';
      try {
        final errorData = jsonDecode(responseData) as Map<String, dynamic>;
        errorMsg = errorData['error'] ?? errorData['message'] ?? errorMsg;
      } catch (_) {
        errorMsg =
            'Backend error (${response.statusCode}): ${responseData.isEmpty ? 'No details' : responseData.substring(0, 100)}';
      }

      throw GroqException(errorMsg, statusCode: response.statusCode);
    } on TimeoutException {
      throw GroqException(
          'Text upload timed out. Please check your connection and try again.');
    } catch (e) {
      if (e is GroqException) rethrow;
      throw GroqException('Failed to upload text: ${e.toString()}');
    }
  }

  static Future<List<Question>> generateRagQuiz({
    required String topic,
    required String documentId,
    required QuizConfig config,
    required String uid,
  }) async {
    try {
      debugPrintSynchronously(
          '🤖 Requesting quiz generation from $documentId...');

      final requestBody = {
        'topic': topic,
        'documentId': documentId,
        'questionCount': config.totalQuestions,
        'difficulty': config.difficulty.name,
        'cognitiveLevel': config.cognitiveLevel.name,
        'uid': uid,
        'questionTypes': config.questionTypes.map((t) => t.name).toList(),
        'quizMode': 'practice',
        'explanationStyle': 'detailed'
      };
      debugPrintSynchronously(
          '📤 Generation request body: ${jsonEncode(requestBody)}');

      // Retry logic for transient server errors (e.g., 500)
      const int maxAttempts = 3;
      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        http.Response? response;
        String? activeEndpoint;

        for (final endpoint in _generateEndpoints) {
          try {
            final candidate = await http
                .post(
                  Uri.parse('$baseUrl$endpoint'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(requestBody),
                )
                .timeout(_generationTimeout);

            response = candidate;
            activeEndpoint = endpoint;
            if (candidate.statusCode != 404) {
              break;
            }
          } catch (_) {
            // Try next endpoint.
          }
        }

        if (response == null) {
          throw GroqException('Backend is unreachable for quiz generation.');
        }

        debugPrintSynchronously(
            '📡 Backend response status: ${response.statusCode} (attempt ${attempt + 1}/$maxAttempts) at ${activeEndpoint ?? 'unknown endpoint'}');

        if (response.statusCode == 200) {
          // proceed to parse below
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final questionsList = (data['questions'] as List<dynamic>? ?? []);

          if (questionsList.isEmpty) {
            throw GroqException(
              'No questions were generated. The PDF may not contain sufficient content.',
            );
          }

          final questions = <Question>[];
          for (int index = 0; index < questionsList.length; index++) {
            final questionData = questionsList[index] as Map<String, dynamic>;

            final options = (questionData['options'] as List<dynamic>?)
                    ?.map((option) => option.toString())
                    .toList() ??
                ['Option A', 'Option B', 'Option C', 'Option D'];

            while (options.length < 4) {
              options.add('Option ${options.length + 1}');
            }
            if (options.length > 4) {
              options.removeRange(4, options.length);
            }

            final correctIndex =
                (questionData['correctIndex'] as int? ?? 0).clamp(0, 3);
            final difficultyEnum = DifficultyLevel.values.firstWhere(
              (difficulty) =>
                  difficulty.name ==
                  (questionData['difficulty'] ?? config.difficulty.name),
              orElse: () => config.difficulty,
            );

            questions.add(
              Question(
                id: 'q_${DateTime.now().millisecondsSinceEpoch}_$index',
                questionText: questionData['questionText'] as String? ??
                    'Question ${index + 1}',
                type: QuestionType.mcq,
                options: options,
                correctIndex: correctIndex,
                explanation: questionData['explanation'] as String?,
                hint: questionData['hint'] as String?,
                marks:
                    config.marksDistribution == 'equal' ? 1 : (index % 3) + 1,
                difficulty: difficultyEnum,
                section: config.numberOfSections > 1
                    ? 'Section ${(index % config.numberOfSections) + 1}'
                    : null,
              ),
            );
          }

          debugPrintSynchronously(
              '✅ Successfully generated ${questions.length} questions');
          return questions;
        }

        // Non-200 response: log and decide whether to retry
        debugPrintSynchronously('📄 Response body: ${response.body}');

        // Some deployed backends require a separate indexing/attach step
        // before generation can find the uploaded document.
        if (response.statusCode == 404 &&
            _looksLikeKnowledgeBaseMissing(response.body)) {
          await _attachKnowledgeBaseIfSupported(requestBody);
        }

        String errorMessage = 'Failed to generate quiz. Please try again.';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage =
              errorData['error'] ?? errorData['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Backend error (${response.statusCode})';
        }

        // If this was the last attempt, throw a GroqException with details
        if (attempt == maxAttempts - 1) {
          throw GroqException(errorMessage, statusCode: response.statusCode);
        }

        // Otherwise, wait with exponential backoff and retry
        final waitSeconds = pow(2, attempt).toInt() * 2 + 1;
        debugPrintSynchronously(
            '⏱️ Generation failed, retrying in $waitSeconds s...');
        await Future.delayed(Duration(seconds: waitSeconds));
      }

      // Shouldn't reach here
      throw GroqException('Quiz generation failed after retries.');
    } on TimeoutException {
      throw GroqException(
          'Upload is taking too long. Check your internet or try a smaller PDF.');
    } catch (e) {
      // Re-throw GroqExceptions as-is
      if (e is GroqException) rethrow;
      // For other errors, wrap them
      throw GroqException('Quiz generation failed. Please try again.');
    }
  }
}
