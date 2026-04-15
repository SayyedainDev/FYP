import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/quiz.dart';
import 'groq_service.dart';

class RagService {
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://fyp-groq.onrender.com',
  );
  static const Duration _uploadTimeout = Duration(minutes: 3);
  static const Duration _generationTimeout = Duration(minutes: 2);

  static Future<String> uploadPdfBytes(Uint8List bytes, String filename) async {
    try {
      debugPrintSynchronously(
          '📤 Uploading PDF bytes ($filename, ${bytes.length} bytes)...');
      final uri = Uri.parse('$baseUrl/api/upload-pdf');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: filename));

      debugPrintSynchronously('⏳ Waiting for upload response...');
      final response = await request.send().timeout(_uploadTimeout);
      final responseData =
          await response.stream.bytesToString().timeout(_uploadTimeout);

      debugPrintSynchronously(
          '📡 Upload response status: ${response.statusCode}');
      debugPrintSynchronously('📋 Full upload response: $responseData');

      if (response.statusCode == 200) {
        final json = jsonDecode(responseData) as Map<String, dynamic>;
        debugPrintSynchronously('🔍 Response JSON keys: ${json.keys.toList()}');
        final docId = json['documentId']?.toString() ?? '';
        debugPrintSynchronously('✅ PDF uploaded successfully (DocID: $docId)');
        if (docId.isEmpty) {
          debugPrintSynchronously(
              '⚠️ WARNING: documentId is empty in response!');
        }
        return docId;
      }

      debugPrintSynchronously('❌ Upload failed. Response: $responseData');

      // Try to extract error from backend
      String errorMsg = 'Failed to process PDF. Please try again.';
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
          'PDF upload timed out. The file may be too large or your connection is slow.');
    } catch (e) {
      if (e is GroqException) rethrow;
      throw GroqException('Failed to upload PDF: ${e.toString()}');
    }
  }

  static Future<String> uploadPdfFile(File file) async {
    try {
      debugPrintSynchronously('📤 Uploading PDF file (${file.path})...');
      final fileSize = await file.length();
      debugPrintSynchronously('📏 File size: $fileSize bytes');

      final uri = Uri.parse('$baseUrl/api/upload-pdf');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      debugPrintSynchronously('⏳ Waiting for upload response...');
      final response = await request.send().timeout(_uploadTimeout);
      final responseData =
          await response.stream.bytesToString().timeout(_uploadTimeout);

      debugPrintSynchronously(
          '📡 Upload response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(responseData) as Map<String, dynamic>;
        final docId = json['documentId']?.toString() ?? '';
        debugPrintSynchronously('✅ PDF uploaded successfully (DocID: $docId)');
        return docId;
      }

      debugPrintSynchronously('❌ Upload failed. Response: $responseData');

      String errorMsg = 'Failed to process PDF. Please try again.';
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
          'PDF upload timed out. The file may be too large or your connection is slow.');
    } catch (e) {
      if (e is GroqException) rethrow;
      throw GroqException('Failed to upload PDF: ${e.toString()}');
    }
  }

  static Future<String> uploadRawText(String text) async {
    try {
      debugPrintSynchronously(
          '📤 Uploading raw text (${text.length} characters)...');
      final uri = Uri.parse('$baseUrl/api/upload-pdf');
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
      // Wait for document to be ready (with retry logic)
      debugPrintSynchronously(
          '⏳ Waiting for document to be indexed ($documentId)...');
      await _waitForDocumentReady(documentId);

      debugPrintSynchronously(
          '🤖 Document ready. Generating quiz from $documentId...');

      final requestBody = {
        'topic': topic,
        'documentId': documentId,
        'questionCount': config.totalQuestions,
        'difficulty': config.difficulty.name,
        'cognitiveLevel': config.cognitiveLevel.name,
        'uid': uid,
      };
      debugPrintSynchronously(
          '📤 Generation request body: ${jsonEncode(requestBody)}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/generate-rag-quiz'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(_generationTimeout);

      // Log response details for debugging
      debugPrintSynchronously(
          '📡 Backend response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrintSynchronously('📄 Response body: ${response.body}');
      }

      if (response.statusCode != 200) {
        // Try to extract error message from backend
        String errorMessage = 'Failed to generate quiz. Please try again.';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorData['error'] ??
              errorData['message'] ??
              'Backend error occurred';
        } catch (_) {
          // If parsing fails, use generic message with status code
          errorMessage =
              'Backend error (${response.statusCode}): ${response.body.isNotEmpty ? response.body.substring(0, 100) : "No details"}';
        }
        throw GroqException(
          errorMessage,
          statusCode: response.statusCode,
        );
      }

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
            marks: config.marksDistribution == 'equal' ? 1 : (index % 3) + 1,
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
    } on TimeoutException {
      throw GroqException(
        'Quiz generation timed out. The backend took too long to process your PDF. Try with a smaller file or fewer questions.',
      );
    } catch (e) {
      // Re-throw GroqExceptions as-is
      if (e is GroqException) rethrow;
      // For other errors, wrap them
      throw GroqException('Failed to generate quiz: ${e.toString()}');
    }
  }

  /// Wait for document to be ready with simple delays
  /// The actual generation will retry if document isn't ready
  static Future<void> _waitForDocumentReady(String documentId,
      {int initialDelayMs = 3000}) async {
    // Give the backend time to start processing the document
    // Don't poll excessively - let the generation call handle retries
    debugPrintSynchronously(
        '⏳ Giving backend time to index PDF (${initialDelayMs}ms)...');
    await Future.delayed(Duration(milliseconds: initialDelayMs));

    debugPrintSynchronously(
        '✅ Initial wait complete. Starting quiz generation...');
  }
}
