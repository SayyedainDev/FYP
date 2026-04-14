import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
    final uri = Uri.parse('$baseUrl/api/upload-pdf');
    final request = http.MultipartRequest('POST', uri)
      ..files
          .add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final response = await request.send().timeout(_uploadTimeout);
    final responseData =
        await response.stream.bytesToString().timeout(_uploadTimeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(responseData) as Map<String, dynamic>;
      return json['documentId']?.toString() ?? '';
    }

    throw GroqException(
      'Failed to process PDF. Please try again.',
      statusCode: response.statusCode,
    );
  }

  static Future<String> uploadPdfFile(File file) async {
    final uri = Uri.parse('$baseUrl/api/upload-pdf');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send().timeout(_uploadTimeout);
    final responseData =
        await response.stream.bytesToString().timeout(_uploadTimeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(responseData) as Map<String, dynamic>;
      return json['documentId']?.toString() ?? '';
    }

    throw GroqException(
      'Failed to process PDF. Please try again.',
      statusCode: response.statusCode,
    );
  }

  static Future<String> uploadRawText(String text) async {
    final uri = Uri.parse('$baseUrl/api/upload-pdf');
    final request = http.MultipartRequest('POST', uri)..fields['text'] = text;

    final response = await request.send().timeout(_uploadTimeout);
    final responseData =
        await response.stream.bytesToString().timeout(_uploadTimeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(responseData) as Map<String, dynamic>;
      return json['documentId']?.toString() ?? '';
    }

    throw GroqException(
      'Failed to process text. Please try again.',
      statusCode: response.statusCode,
    );
  }

  static Future<List<Question>> generateRagQuiz({
    required String topic,
    required String documentId,
    required QuizConfig config,
    required String uid,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/generate-rag-quiz'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'topic': topic,
            'documentId': documentId,
            'questionCount': config.totalQuestions,
            'difficulty': config.difficulty.name,
            'uid': uid,
          }),
        )
        .timeout(_generationTimeout);

    if (response.statusCode != 200) {
      throw GroqException(
        'Failed to generate quiz. Please try again.',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final questionsList = (data['questions'] as List<dynamic>? ?? []);

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

    return questions;
  }
}
