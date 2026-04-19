import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/quiz.dart';

// ─── Custom Exceptions ─────────────────────────────────────────────────

class GroqException implements Exception {
  final String message;
  final int? statusCode;
  GroqException(this.message, {this.statusCode});
  @override
  String toString() => 'GroqException: $message';
}

class GroqParseException implements Exception {
  final String message;
  final String rawResponse;
  GroqParseException(this.message, this.rawResponse);
  @override
  String toString() => 'GroqParseException: $message';
}

// ─── Service ────────────────────────────────────────────────────────────

/// Service for generating quiz questions using Groq LLM API
class GroqService {
  // Configured Groq API key for FYP Demo
  static const String _apiKey =
      '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';
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxSourceTextLength = 12000; // Groq context limit safety

  /// Check if the API key is configured
  static bool get isConfigured =>
      _apiKey != 'YOUR_GROQ_API_KEY_HERE' && _apiKey.isNotEmpty;

  /// Test connection to Groq API — verifies the API key works
  static Future<bool> testConnection() async {
    if (!isConfigured) return false;
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'user', 'content': 'Reply with just the word OK.'}
              ],
              'max_tokens': 5,
              'temperature': 0,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        debugPrint('✅ Groq API connection test passed');
        return true;
      }
      debugPrint('❌ Groq API test failed: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Groq API test error: $e');
      return false;
    }
  }

  /// Generate quiz questions from source text using Groq AI
  static Future<List<Question>> generateQuizQuestions({
    required String sourceText,
    required QuizConfig config,
  }) async {
    if (!isConfigured) {
      throw GroqException('Groq API key is not configured');
    }

    // Cap source text to prevent exceeding Groq's context window
    final truncatedText = sourceText.length > _maxSourceTextLength
        ? sourceText.substring(0, _maxSourceTextLength)
        : sourceText;

    final prompt = _buildPrompt(truncatedText, config);
    debugPrint(
        '🤖 Calling Groq API to generate ${config.totalQuestions} questions...');

    // Attempt with 1 retry on timeout
    String content;
    try {
      content = await _callGroqApi(prompt);
    } on TimeoutException {
      debugPrint('⏱️ Groq API timed out, retrying once...');
      try {
        content = await _callGroqApi(prompt);
      } on TimeoutException {
        throw GroqException('Groq API timed out after 2 attempts. '
            'Try reducing the number of questions or text length.');
      }
    }

    debugPrint('✅ Groq API response received, parsing questions...');
    return _parseQuestions(content, config);
  }

  /// Make the actual HTTP call to Groq with timeout
  static Future<String> _callGroqApi(String prompt) async {
    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {
                'role': 'system',
                'content': 'You are an expert dental education professor creating MCQ exam questions. '
                    'Generate high-quality quiz questions in valid JSON format. '
                    'Always respond ONLY with a valid JSON array, no markdown, no explanation.',
              },
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.7,
            'max_tokens': 2500,
            'top_p': 1,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode == 429) {
      throw GroqException(
          'Rate limit exceeded. Please wait a moment and try again.',
          statusCode: 429);
    }
    if (response.statusCode == 401) {
      throw GroqException('Invalid API key. Please check your Groq API key.',
          statusCode: 401);
    }
    if (response.statusCode != 200) {
      String detail = '';
      try {
        final body = jsonDecode(response.body);
        detail = body['error']?['message'] ?? response.body;
      } catch (_) {
        detail = response.body;
      }
      throw GroqException('Groq API error (${response.statusCode}): $detail',
          statusCode: response.statusCode);
    }

    final responseData = jsonDecode(response.body);
    return responseData['choices'][0]['message']['content'] as String;
  }

  /// Build the prompt for Groq API
  static String _buildPrompt(String sourceText, QuizConfig config) {
    final difficultyDesc = _getDifficultyDescription(config.difficulty);
    final cognitiveDesc = _getCognitiveDescription(config.cognitiveLevel);

    return '''
Generate exactly ${config.totalQuestions} multiple-choice questions (MCQs) based on the following dental/medical lecture content.

Requirements:
- Difficulty: $difficultyDesc
- Cognitive Level: $cognitiveDesc
- Each question must have exactly 4 options (A, B, C, D)
- Provide the correct answer as an index (0=A, 1=B, 2=C, 3=D)
- Include a brief explanation for each correct answer
- Questions should test understanding of the material, not just recall
- Make distractors (wrong options) plausible but clearly distinguishable

STRICT JSON RULES:
- Respond ONLY with a valid JSON array, no markdown, no explanation
- Each question object must have exactly these fields:
  {
    "questionText": "string",
    "options": ["option A", "option B", "option C", "option D"],
    "correctIndex": 0,
    "explanation": "string explaining why this answer is correct",
    "difficulty": "easy|medium|hard"
  }
- correctIndex must be 0, 1, 2, or 3
- All 4 options must be plausible, not obviously wrong
- Questions must be directly based on the provided source text

SOURCE CONTENT:
$sourceText
''';
  }

  /// Parse the AI response into Question objects
  static List<Question> _parseQuestions(String content, QuizConfig config) {
    try {
      String jsonStr = content.trim();

      // Remove markdown code blocks if present (```json ... ```)
      if (jsonStr.contains('```')) {
        jsonStr = jsonStr.replaceAll(RegExp(r'```\w*\n?'), '');
        jsonStr = jsonStr.replaceAll(RegExp(r'\n?```'), '');
        jsonStr = jsonStr.trim();
      }

      // Find JSON array boundaries
      final startIdx = jsonStr.indexOf('[');
      final endIdx = jsonStr.lastIndexOf(']');
      if (startIdx >= 0 && endIdx > startIdx) {
        jsonStr = jsonStr.substring(startIdx, endIdx + 1);
      }

      final List<dynamic> questionsJson = jsonDecode(jsonStr);

      final questions = <Question>[];
      for (int i = 0; i < questionsJson.length; i++) {
        final q = questionsJson[i] as Map<String, dynamic>;

        final options =
            (q['options'] as List<dynamic>).map((o) => o.toString()).toList();

        // Validate: must have exactly 4 options
        if (options.length != 4) {
          debugPrint(
              '⚠️ Question $i has ${options.length} options, padding/trimming to 4');
          while (options.length < 4) {
            options.add('Option ${options.length + 1}');
          }
          if (options.length > 4) {
            options.removeRange(4, options.length);
          }
        }

        final correctIndex = (q['correctIndex'] as int? ?? 0).clamp(0, 3);

        final difficulty = DifficultyLevel.values.firstWhere(
          (d) => d.name == (q['difficulty'] ?? config.difficulty.name),
          orElse: () => config.difficulty,
        );

        questions.add(Question(
          id: 'q_${DateTime.now().millisecondsSinceEpoch}_$i',
          questionText: q['questionText'] as String? ?? 'Question ${i + 1}',
          type: QuestionType.mcq,
          options: options,
          correctIndex: correctIndex,
          explanation: q['explanation'] as String?,
          marks: config.marksDistribution == 'equal' ? 1 : (i % 3) + 1,
          difficulty: difficulty,
          section: config.numberOfSections > 1
              ? 'Section ${(i % config.numberOfSections) + 1}'
              : null,
        ));
      }

      debugPrint('✅ Parsed ${questions.length} questions from Groq response');
      return questions;
    } catch (e) {
      debugPrint('❌ Failed to parse Groq response: $e');
      debugPrint('📄 Raw content: $content');
      throw GroqParseException(
        'Failed to parse AI-generated questions. The AI response was not valid JSON. Please try again.',
        content,
      );
    }
  }

  static String _getDifficultyDescription(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 'Easy - basic recall and recognition questions';
      case DifficultyLevel.medium:
        return 'Medium - understanding and application questions';
      case DifficultyLevel.hard:
        return 'Hard - analysis, synthesis, and critical thinking questions';
      case DifficultyLevel.mixed:
        return 'Mixed - a balanced blend of easy, medium, and hard questions';
    }
  }

  static String _getCognitiveDescription(CognitiveLevel level) {
    switch (level) {
      case CognitiveLevel.knowledge:
        return 'Knowledge/Recall - factual recall questions';
      case CognitiveLevel.understanding:
        return 'Understanding - comprehension and interpretation';
      case CognitiveLevel.application:
        return 'Application - applying knowledge to clinical scenarios';
      case CognitiveLevel.analysis:
        return 'Analysis - breaking down complex concepts';
      case CognitiveLevel.mixed:
        return 'Mixed Bloom\'s Taxonomy levels';
    }
  }
}
