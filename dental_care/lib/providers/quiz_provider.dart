import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/quiz.dart';
import '../service/file_parser_service.dart';

class QuizProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final supabase = Supabase.instance.client;

  List<Quiz> _quizzes = [];
  bool _isLoading = false;
  String? _errorMessage;
  Quiz? _currentQuiz;
  QuizConfig? _currentConfig;
  File? _uploadedFile;
  String? _uploadedFileName;
  double _uploadProgress = 0.0;
  String? _tempPath; // Local temp path for non-web
  Uint8List? _uploadedBytes; // In-memory bytes for web

  // Getters
  List<Quiz> get quizzes => _quizzes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Quiz? get currentQuiz => _currentQuiz;
  QuizConfig? get currentConfig => _currentConfig;
  File? get uploadedFile => _uploadedFile;
  String? get uploadedFileName => _uploadedFileName;
  double get uploadProgress => _uploadProgress;
  String? get tempPath => _tempPath;
  Uint8List? get uploadedBytes => _uploadedBytes;

  // Stream of quizzes for a specific dentist
  Stream<List<Quiz>> getQuizzesStream(String dentistUid) {
    if (dentistUid.trim().isEmpty) {
      return Stream.value(<Quiz>[]);
    }

    try {
      return _firestore
          .collection('quizzes')
          .where('dentistUid', isEqualTo: dentistUid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) => Quiz.fromFirestore(doc)).toList(),
          );
    } catch (e) {
      debugPrint('Failed to create quizzes stream: $e');
      return Stream.value(<Quiz>[]);
    }
  }

  // Set uploaded file
  void setUploadedFile(File? file, String? fileName) {
    _uploadedFile = file;
    _uploadedFileName = fileName;
    notifyListeners();
  }

  // Set uploaded bytes (for Web)
  void setUploadedBytes(Uint8List? bytes, String? fileName) {
    _uploadedBytes = bytes;
    _uploadedFile = null;
    _uploadedFileName = fileName;
    notifyListeners();
  }

  // Save file to a temporary folder (non-web). For Web, hold bytes in memory.
  Future<String?> saveToTemp({
    File? file,
    Uint8List? bytes,
    required String fileName,
  }) async {
    try {
      if (kIsWeb) {
        // On web we can't write to disk; keep bytes in memory
        if (bytes != null) {
          _uploadedBytes = bytes;
          _tempPath = null;
        }
        _uploadedFileName = fileName;
        notifyListeners();
        return null;
      }

      // Mobile/Desktop: copy to temp directory
      if (file != null) {
        final tmpDir = await getTemporaryDirectory();
        final target = File(
          '${tmpDir.path}/quiz_notes_${DateTime.now().millisecondsSinceEpoch}_$fileName',
        );
        await target.create(recursive: true);
        await file.copy(target.path);
        _tempPath = target.path;
        _uploadedFile = target;
        _uploadedFileName = fileName;
        notifyListeners();
        return _tempPath;
      }

      return null;
    } catch (e) {
      _errorMessage = 'Failed to save temp file: $e';
      notifyListeners();
      return null;
    }
  }

  // Set quiz configuration
  void setQuizConfig(QuizConfig config) {
    _currentConfig = config;
    notifyListeners();
  }

  // Upload note file to Firebase Storage
  Future<String?> uploadNoteFile(
    String dentistUid,
    File file,
    String fileName,
  ) async {
    try {
      _isLoading = true;
      _uploadProgress = 0.0;
      notifyListeners();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final bucket = 'quizzes';
      final path = '$dentistUid/notes/${timestamp}_$fileName';
      final bytes = await file.readAsBytes();

      await supabase.storage.from(bucket).uploadBinary(path, bytes);
      final downloadUrl = supabase.storage.from(bucket).getPublicUrl(path);

      _isLoading = false;
      _uploadProgress = 1.0;
      notifyListeners();

      return downloadUrl;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to upload file: $e';
      notifyListeners();
      return null;
    }
  }

  // Upload note bytes to Firebase Storage (Web)
  Future<String?> uploadNoteBytes(
    String dentistUid,
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      _isLoading = true;
      _uploadProgress = 0.0;
      notifyListeners();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final bucket = 'quizzes';
      final path = '$dentistUid/notes/${timestamp}_$fileName';

      await supabase.storage.from(bucket).uploadBinary(path, bytes);
      final downloadUrl = supabase.storage.from(bucket).getPublicUrl(path);

      _isLoading = false;
      _uploadProgress = 1.0;
      notifyListeners();

      return downloadUrl;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to upload file: $e';
      notifyListeners();
      return null;
    }
  }

  // Create a new quiz
  Future<bool> createQuiz({
    required String dentistUid,
    required String title,
    required String description,
    required QuizConfig config,
    required List<Question> questions,
    String? noteFileUrl,
    String? noteFileName,
  }) async {
    try {
      debugPrint('🔄 Starting quiz creation...');
      debugPrint('👤 Dentist UID: $dentistUid');
      debugPrint('📝 Title: $title');
      debugPrint('❓ Questions count: ${questions.length}');

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Calculate total marks
      final totalMarks = questions.fold<int>(0, (sum, q) => sum + q.marks);
      debugPrint('📊 Total marks: $totalMarks');

      // Calculate section marks
      Map<String, int>? sectionMarks;
      if (config.numberOfSections > 1) {
        sectionMarks = {};
        for (var question in questions) {
          if (question.section != null) {
            sectionMarks[question.section!] =
                (sectionMarks[question.section!] ?? 0) + question.marks;
          }
        }
      }

      final quiz = Quiz(
        id: '', // Firestore will generate
        title: title,
        description: description,
        dentistUid: dentistUid,
        config: config,
        questions: questions,
        noteFileUrl: noteFileUrl,
        noteFileName: noteFileName,
        createdAt: DateTime.now(),
        totalMarks: totalMarks,
        sectionMarks: sectionMarks,
      );

      debugPrint('📤 Attempting to save quiz to Firestore...');
      final docRef = await _firestore
          .collection('quizzes')
          .add(quiz.toFirestore());

      debugPrint('✅ Quiz saved with ID: ${docRef.id}');

      // Update with generated ID
      await docRef.update({'id': docRef.id});
      debugPrint('✅ Quiz ID updated in document');

      // Create a new quiz instance with the correct ID
      _currentQuiz = Quiz(
        id: docRef.id,
        title: title,
        description: description,
        dentistUid: dentistUid,
        config: config,
        questions: questions,
        noteFileUrl: noteFileUrl,
        noteFileName: noteFileName,
        createdAt: quiz.createdAt,
        totalMarks: totalMarks,
        sectionMarks: sectionMarks,
      );
      _isLoading = false;
      notifyListeners();

      debugPrint('🎉 Quiz creation completed successfully!');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating quiz: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      _isLoading = false;
      _errorMessage = 'Failed to create quiz: $e';
      notifyListeners();
      return false;
    }
  }

  // Set current quiz locally (e.g., when offline/Firebase fails)
  void setCurrentQuiz(Quiz quiz) {
    _currentQuiz = quiz;
    notifyListeners();
  }

  // Fetch all quizzes for a dentist
  Future<void> fetchQuizzes(String dentistUid) async {
    try {
      debugPrint('🔍 Fetching quizzes for dentist: $dentistUid');
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('quizzes')
          .where('dentistUid', isEqualTo: dentistUid)
          .orderBy('createdAt', descending: true)
          .get();

      _quizzes = snapshot.docs.map((doc) => Quiz.fromFirestore(doc)).toList();

      debugPrint('✅ Fetched ${_quizzes.length} quizzes');
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching quizzes: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      _isLoading = false;
      _errorMessage = 'Failed to fetch quizzes: $e';
      notifyListeners();
    }
  }

  // Get a single quiz by ID
  Future<Quiz?> getQuizById(String quizId) async {
    try {
      debugPrint('🔍 Fetching quiz with ID: $quizId');
      _isLoading = true;
      notifyListeners();

      final doc = await _firestore.collection('quizzes').doc(quizId).get();

      if (doc.exists) {
        _currentQuiz = Quiz.fromFirestore(doc);
        debugPrint('✅ Quiz fetched successfully');
        _isLoading = false;
        notifyListeners();
        return _currentQuiz;
      }

      debugPrint('⚠️ Quiz not found');
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching quiz: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      _isLoading = false;
      _errorMessage = 'Failed to fetch quiz: $e';
      notifyListeners();
      return null;
    }
  }

  // Update a quiz
  Future<bool> updateQuiz(Quiz quiz) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updatedQuiz = Quiz(
        id: quiz.id,
        title: quiz.title,
        description: quiz.description,
        dentistUid: quiz.dentistUid,
        config: quiz.config,
        questions: quiz.questions,
        noteFileUrl: quiz.noteFileUrl,
        noteFileName: quiz.noteFileName,
        createdAt: quiz.createdAt,
        lastModified: DateTime.now(),
        totalMarks: quiz.totalMarks,
        sectionMarks: quiz.sectionMarks,
      );

      await _firestore
          .collection('quizzes')
          .doc(quiz.id)
          .update(updatedQuiz.toFirestore());

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update quiz: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete a quiz
  Future<bool> deleteQuiz(String quizId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Delete the quiz document
      await _firestore.collection('quizzes').doc(quizId).delete();

      // Remove from local list
      _quizzes.removeWhere((q) => q.id == quizId);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete quiz: $e';
      notifyListeners();
      return false;
    }
  }

  // Clear current quiz
  void clearCurrentQuiz() {
    _currentQuiz = null;
    _currentConfig = null;
    _uploadedFile = null;
    _uploadedFileName = null;
    _uploadProgress = 0.0;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Generate quiz questions locally without OpenAI
  Future<List<Question>?> generateQuestionsWithAI({
    required QuizConfig config,
    String? noteContent,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      String content = noteContent ?? '';

      // If no content provided, try to extract from uploaded file
      if (content.isEmpty) {
        debugPrint('📄 Extracting content from uploaded file...');
        content = await _extractNoteContent();
        debugPrint('📄 Extracted content length: ${content.length} characters');
      }

      debugPrint('🎯 Generating ${config.totalQuestions} questions locally...');

      // Generate questions locally
      final questions = _generateIntelligentQuestions(content, config);

      debugPrint('✅ Generated ${questions.length} questions');

      _isLoading = false;
      notifyListeners();

      return questions;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to generate quiz: $e';
      debugPrint('❌ Error in generateQuestionsWithAI: $e');
      notifyListeners();
      return null;
    }
  }

  /// Extract text content from uploaded note file
  Future<String> _extractNoteContent() async {
    try {
      if (_uploadedBytes != null && _uploadedFileName != null) {
        debugPrint('🔍 Extracting content from: $_uploadedFileName');

        // Use FileParserService for multi-format support
        final content = await FileParserService.extractTextFromBytes(
          _uploadedBytes!,
          _uploadedFileName!,
        );

        if (content.isEmpty) {
          throw Exception(
            'Unable to extract text from file. The file may be empty or in an unsupported format.',
          );
        }

        return content;
      } else if (_uploadedFile != null) {
        debugPrint(
          '🔍 Extracting content from file path: ${_uploadedFile!.path}',
        );

        // Use FileParserService for multi-format support
        final content = await FileParserService.extractTextFromFile(
          _uploadedFile!,
        );

        if (content.isEmpty) {
          throw Exception(
            'Unable to extract text from file. The file may be empty or in an unsupported format.',
          );
        }

        return content;
      }
      return '';
    } catch (e) {
      debugPrint('Error extracting note content: $e');
      return '';
    }
  }

  /// Generate intelligent questions based on content and configuration
  List<Question> _generateIntelligentQuestions(
    String content,
    QuizConfig config,
  ) {
    final questions = <Question>[];
    final types = config.questionTypes.toList();

    // Extract meaningful sentences from content
    List<String> extractedContent = [];
    if (content.isNotEmpty && content.length > 50) {
      final sentences = content
          .replaceAll('\n', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .split(RegExp(r'[.!?]'))
          .map((s) => s.trim())
          .where(
            (s) =>
                s.split(' ').length >= 6 &&
                s.split(' ').length <= 40 &&
                !s.toLowerCase().contains('generate') &&
                !s.toLowerCase().contains('sample'),
          )
          .toList();

      extractedContent = sentences.take(config.totalQuestions * 3).toList();
    }

    // Only show error if truly no content
    if (extractedContent.isEmpty) {
      throw Exception(
        'Unable to generate quiz: The lecture notes appear to be empty or contain insufficient content. '
        'Supported formats: ${FileParserService.getSupportedFormatsString()}. '
        'Please upload a file with at least 50 words of content.',
      );
    }

    for (int i = 0; i < config.totalQuestions; i++) {
      final contentIndex = i % extractedContent.length;
      final topic = extractedContent[contentIndex];
      final type = types[i % types.length];
      final marks = config.marksDistribution == 'equal' ? 1 : (i % 3) + 1;
      final section = config.numberOfSections > 1
          ? 'Section ${(i % config.numberOfSections) + 1}'
          : null;
      final difficulty = config.difficulty == DifficultyLevel.mixed
          ? DifficultyLevel.values[i % 3]
          : config.difficulty;

      questions.add(
        _createQuestion(i, topic, type, marks, difficulty, section, config),
      );
    }

    return questions;
  }

  Question _createQuestion(
    int index,
    String topic,
    QuestionType type,
    int marks,
    DifficultyLevel difficulty,
    String? section,
    QuizConfig config,
  ) {
    // Extract key terms from topic for better question generation
    final words = topic.split(' ').where((w) => w.length > 3).toList();
    final keyTerm = words.isNotEmpty ? words[0] : topic.split(' ')[0];

    switch (type) {
      case QuestionType.mcq:
        // Create distractor options from the content
        final mainConcept = _extractMainConcept(topic);
        final otherWords = words.length > 3 ? words.sublist(1, 4) : words;

        return Question(
          id: 'q_${DateTime.now().millisecondsSinceEpoch}_$index',
          questionText:
              'According to the lecture notes, what is stated about $keyTerm?',
          type: type,
          options: [
            mainConcept,
            otherWords.isNotEmpty
                ? otherWords.join(' ')
                : 'Alternative concept',
            'It is not mentioned in the notes',
            'Opposite of the stated information',
          ]..shuffle(),
          correctAnswer: mainConcept,
          explanation: config.includeAnswerKey
              ? 'From the notes: "$topic"'
              : null,
          marks: marks,
          difficulty: difficulty,
          section: section,
        );

      case QuestionType.trueFalse:
        return Question(
          id: 'q_${DateTime.now().millisecondsSinceEpoch}_$index',
          questionText: 'Based on the lecture material: $topic',
          type: type,
          options: ['True', 'False'],
          correctAnswer: 'True',
          explanation: config.includeAnswerKey
              ? 'This information is directly stated in the uploaded notes.'
              : null,
          marks: marks,
          difficulty: difficulty,
          section: section,
        );

      case QuestionType.shortAnswer:
        return Question(
          id: 'q_${DateTime.now().millisecondsSinceEpoch}_$index',
          questionText: 'Explain what the lecture notes state about: $keyTerm',
          type: type,
          options: null,
          correctAnswer: topic,
          explanation: config.includeAnswerKey
              ? 'Expected answer: $topic'
              : null,
          marks: marks,
          difficulty: difficulty,
          section: section,
        );

      case QuestionType.longAnswer:
        return Question(
          id: 'q_${DateTime.now().millisecondsSinceEpoch}_$index',
          questionText: 'Discuss the concepts related to: $topic',
          type: type,
          options: null,
          correctAnswer: 'A comprehensive answer covering: $topic',
          explanation: config.includeAnswerKey
              ? 'Answer should reference the concepts from the lecture notes and demonstrate understanding.'
              : null,
          marks: marks,
          difficulty: difficulty,
          section: section,
        );

      case QuestionType.fillInTheBlanks:
        // Find a significant word to blank out (noun, verb, adjective)
        final words = topic.split(' ');
        var blankIndex = words.indexWhere(
          (w) =>
              w.length > 4 &&
              !['the', 'and', 'or', 'but', 'with'].contains(w.toLowerCase()),
        );
        if (blankIndex == -1) blankIndex = words.length > 3 ? 1 : 0;

        final answer = words[blankIndex];
        final questionWords = List<String>.from(words);
        questionWords[blankIndex] = '______';

        return Question(
          id: 'q_${DateTime.now().millisecondsSinceEpoch}_$index',
          questionText:
              'Complete the statement from the lecture: ${questionWords.join(' ')}',
          type: type,
          options: null,
          correctAnswer: answer,
          explanation: config.includeAnswerKey
              ? 'The complete statement: $topic'
              : null,
          marks: marks,
          difficulty: difficulty,
          section: section,
        );

      case QuestionType.scenarioBased:
        return Question(
          id: 'q_${DateTime.now().millisecondsSinceEpoch}_$index',
          questionText:
              'Based on the lecture material about "$keyTerm", how would you apply this knowledge in practice: $topic',
          type: type,
          options: null,
          correctAnswer: 'Application of concepts: $topic',
          explanation: config.includeAnswerKey
              ? 'Consider how the information from the notes applies to clinical/practical situations.'
              : null,
          marks: marks,
          difficulty: difficulty,
          section: section,
        );
    }
  }

  String _extractMainConcept(String text) {
    final words = text.split(' ');
    if (words.length > 3) {
      return words.take(4).join(' ');
    }
    return text;
  }
}
