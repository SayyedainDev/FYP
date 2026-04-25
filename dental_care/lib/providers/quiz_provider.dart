import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Supabase removed
import 'package:path_provider/path_provider.dart';
import '../service/firebase_service.dart';
import '../models/quiz.dart';
import '../models/quiz_attempt.dart';
import '../service/groq_service.dart';
import '../service/rag_service.dart';

class QuizProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _service = FirebaseService();
  // Supabase removed — file uploads now use Firebase Storage
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const Duration _aiRequestTimeout = Duration(minutes: 3);

  List<Quiz> _quizzes = [];
  List<Quiz> _publishedQuizzes = []; // For students
  bool _isLoading = false;
  String? _errorMessage;
  Quiz? _currentQuiz;
  QuizConfig? _currentConfig;
  File? _uploadedFile;
  String? _uploadedFileName;
  double _uploadProgress = 0.0;
  String? _tempPath;
  Uint8List? _uploadedBytes;
  String? _extractedText; // Extracted text from uploaded file
  bool _isGeneratingWithAI = false;
  String? _groqError;
  bool _isFetchingPublishedQuizzes = false;
  List<QuizAttempt> _quizAttempts = [];

  // Getters
  List<Quiz> get quizzes => _quizzes;
  List<Quiz> get publishedQuizzes => _publishedQuizzes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Quiz? get currentQuiz => _currentQuiz;
  QuizConfig? get currentConfig => _currentConfig;
  File? get uploadedFile => _uploadedFile;
  String? get uploadedFileName => _uploadedFileName;
  double get uploadProgress => _uploadProgress;
  String? get tempPath => _tempPath;
  Uint8List? get uploadedBytes => _uploadedBytes;
  String? get extractedText => _extractedText;
  bool get isGeneratingWithAI => _isGeneratingWithAI;
  String? get groqError => _groqError;
  List<QuizAttempt> get quizAttempts => _quizAttempts;

  Future<T> _withTimeout<T>(Future<T> future) {
    return future.timeout(_requestTimeout);
  }

  Future<T> _withAiTimeout<T>(Future<T> future) {
    return future.timeout(_aiRequestTimeout);
  }

  Future<T> _runAiRequestWithRetry<T>(Future<T> Function() request) async {
    const maxAttempts = 8;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await request();
      } on TimeoutException {
        if (attempt == maxAttempts) rethrow;
        debugPrint(
            '⏱️ Timeout on attempt $attempt/$maxAttempts. Retrying in ${attempt * 3}s...');
        await Future.delayed(Duration(seconds: attempt * 3));
      } on SocketException {
        if (attempt == maxAttempts) rethrow;
        debugPrint(
            '🌐 Network error on attempt $attempt/$maxAttempts. Retrying in ${attempt * 3}s...');
        await Future.delayed(Duration(seconds: attempt * 3));
      } on GroqException catch (e) {
        // Retry if it's a 404 "knowledge base not found" error (document still processing)
        if (e.statusCode == 404 &&
            (e.message.contains('knowledge base') ||
                e.message.contains('not found'))) {
          if (attempt == maxAttempts) rethrow;
          debugPrint(
              '⏳ Knowledge base not ready on attempt $attempt/$maxAttempts. Waiting for indexing... (${attempt * 3}s delay)');
          // Exponential backoff: 3s, 6s, 9s, 12s, 15s, 18s, 21s, 24s
          await Future.delayed(Duration(seconds: attempt * 3));
          continue;
        }
        // For other GroqExceptions, don't retry
        rethrow;
      }
    }

    throw TimeoutException('AI request failed after $maxAttempts retries.');
  }

  String _mapErrorMessage(
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
      if (error.code == 'permission-denied' || error.code == 'forbidden') {
        return 'You do not have permission to perform this action.';
      }
      if (error.code == 'unauthenticated' || error.code == 'invalid-auth') {
        return 'Your session has expired. Please log in again.';
      }
      if (error.code == 'not-found') {
        return 'The requested item could not be found.';
      }
      if (error.code == 'deadline-exceeded') {
        return 'The request timed out. Check your connection and try again.';
      }
    }

    // Handle GroqException (includes backend API errors)
    if (error is GroqException) {
      return error.message;
    }

    final raw = error.toString().toLowerCase();
    if (raw.contains('groqexception')) {
      return 'AI generation failed. Please check your PDF content and try again.';
    }
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
    if (raw.contains('429') || raw.contains('rate limit')) {
      return 'Too many requests. Please wait a moment and try again.';
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

  // Stream of quizzes for a specific dentist/professor
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

  // Save file to a temporary folder
  Future<String?> saveToTemp({
    File? file,
    Uint8List? bytes,
    required String fileName,
  }) async {
    try {
      if (kIsWeb) {
        if (bytes != null) {
          _uploadedBytes = bytes;
          _tempPath = null;
        }
        _uploadedFileName = fileName;
        notifyListeners();
        return null;
      }

      if (file != null) {
        final tmpDir = await _withTimeout(getTemporaryDirectory());
        final target = File(
          '${tmpDir.path}/quiz_notes_${DateTime.now().millisecondsSinceEpoch}_$fileName',
        );
        await _withTimeout(target.create(recursive: true));
        await _withTimeout(file.copy(target.path));
        _tempPath = target.path;
        _uploadedFile = target;
        _uploadedFileName = fileName;
        notifyListeners();
        return _tempPath;
      }

      return null;
    } catch (e) {
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to prepare file for upload. Please try again.',
      );
      notifyListeners();
      return null;
    }
  }

  // Set quiz configuration
  void setQuizConfig(QuizConfig config) {
    _currentConfig = config;
    notifyListeners();
  }

  // Upload note file to Supabase Storage
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
      final path = '$dentistUid/notes/${timestamp}_$fileName';
      final bytes = await _withTimeout(file.readAsBytes());
      final downloadUrl =
          await _withTimeout(_service.uploadImage(dentistUid, path, bytes));

      _isLoading = false;
      _uploadProgress = 1.0;
      notifyListeners();

      return downloadUrl;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to upload file. Please try again.',
      );
      notifyListeners();
      return null;
    }
  }

  // Upload note bytes to Supabase Storage (Web)
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
      final path = '$dentistUid/notes/${timestamp}_$fileName';
      final downloadUrl =
          await _withTimeout(_service.uploadImage(dentistUid, path, bytes));

      _isLoading = false;
      _uploadProgress = 1.0;
      notifyListeners();

      return downloadUrl;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to upload file. Please try again.',
      );
      notifyListeners();
      return null;
    }
  }

  // Create a new quiz (defaults to draft status)
  Future<bool> createQuiz({
    required String dentistUid,
    required String title,
    required String description,
    required QuizConfig config,
    required List<Question> questions,
    String? noteFileUrl,
    String? noteFileName,
    String? sourceText,
    QuizStatus status = QuizStatus.draft,
  }) async {
    try {
      debugPrint('🔄 Starting quiz creation...');
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final totalMarks = questions.fold<int>(0, (sum, q) => sum + q.marks);

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
        id: '',
        title: title,
        description: description,
        dentistUid: dentistUid,
        config: config,
        questions: questions,
        noteFileUrl: noteFileUrl,
        noteFileName: noteFileName,
        sourceText: sourceText,
        status: status,
        createdAt: DateTime.now(),
        totalMarks: totalMarks,
        sectionMarks: sectionMarks,
      );

      final docRef = await _withTimeout(
          _firestore.collection('quizzes').add(quiz.toFirestore()));

      await _withTimeout(docRef.update({'id': docRef.id}));

      _currentQuiz = quiz.copyWith(id: docRef.id);
      _isLoading = false;
      notifyListeners();

      debugPrint(
          '🎉 Quiz created with ID: ${docRef.id} (status: ${status.name})');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating quiz: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      _isLoading = false;
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to create quiz. Please try again.',
      );
      notifyListeners();
      return false;
    }
  }

  /// Publish a quiz (make it available to students)
  Future<bool> publishQuiz(String quizId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _withTimeout(_firestore.collection('quizzes').doc(quizId).update({
        'status': QuizStatus.published.name,
        'lastModified': Timestamp.now(),
      }));

      // Update local list
      final idx = _quizzes.indexWhere((q) => q.id == quizId);
      if (idx >= 0) {
        _quizzes[idx] = _quizzes[idx].copyWith(
          status: QuizStatus.published,
          lastModified: DateTime.now(),
        );
      }

      debugPrint('✅ Quiz $quizId published');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error publishing quiz: $e');
      _isLoading = false;
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to publish quiz. Please try again.',
      );
      notifyListeners();
      return false;
    }
  }

  /// Close a quiz (no longer available to students)
  Future<bool> closeQuiz(String quizId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _withTimeout(_firestore.collection('quizzes').doc(quizId).update({
        'status': QuizStatus.closed.name,
        'lastModified': Timestamp.now(),
      }));

      final idx = _quizzes.indexWhere((q) => q.id == quizId);
      if (idx >= 0) {
        _quizzes[idx] = _quizzes[idx].copyWith(
          status: QuizStatus.closed,
          lastModified: DateTime.now(),
        );
      }

      debugPrint('✅ Quiz $quizId closed');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error closing quiz: $e');
      _isLoading = false;
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to close quiz. Please try again.',
      );
      notifyListeners();
      return false;
    }
  }

  // Set current quiz locally
  void setCurrentQuiz(Quiz quiz) {
    _currentQuiz = quiz;
    notifyListeners();
  }

  // Fetch all quizzes for a dentist/professor
  Future<void> fetchQuizzes(String dentistUid) async {
    try {
      debugPrint('🔍 Fetching quizzes for: $dentistUid');
      _isLoading = true;
      _errorMessage = null;
      Future.microtask(() => notifyListeners());

      final snapshot = await _withTimeout(_firestore
          .collection('quizzes')
          .where('dentistUid', isEqualTo: dentistUid)
          .orderBy('createdAt', descending: true)
          .get());

      _quizzes = snapshot.docs.map((doc) => Quiz.fromFirestore(doc)).toList();

      debugPrint('✅ Fetched ${_quizzes.length} quizzes');
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching quizzes: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      _isLoading = false;
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to fetch quizzes. Please try again.',
      );
      notifyListeners();
    }
  }

  /// Fetch all published quizzes (for students)
  /// Fetch all published quizzes (for students)
  /// If [excludeStudentId] is provided, quizzes that already have an attempt
  /// by that student will be filtered out (so students won't see quizzes they've taken).
  Future<void> fetchPublishedQuizzes({String? excludeStudentId}) async {
    if (_isFetchingPublishedQuizzes) return;

    try {
      _isFetchingPublishedQuizzes = true;
      debugPrint('🔍 Fetching published quizzes for students...');
      _isLoading = true;
      _errorMessage = null;

      // Defer notification until after build phase to avoid "setState during build" error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      final snapshot = await _withTimeout(_firestore
          .collection('quizzes')
          .where('status', isEqualTo: QuizStatus.published.name)
          .orderBy('createdAt', descending: true)
          .get());

      var quizzes =
          snapshot.docs.map((doc) => Quiz.fromFirestore(doc)).toList();

      if (excludeStudentId != null && excludeStudentId.isNotEmpty) {
        // For each quiz, check if an attempt exists for this student. This is
        // moderately expensive but acceptable for small numbers of published quizzes.
        final filtered = <Quiz>[];
        for (final q in quizzes) {
          final attemptsSnap = await _withTimeout(_firestore
              .collection('quizzes')
              .doc(q.id)
              .collection('attempts')
              .where('studentId', isEqualTo: excludeStudentId)
              .limit(1)
              .get());

          if (attemptsSnap.docs.isEmpty) {
            filtered.add(q);
          }
        }
        _publishedQuizzes = filtered;
      } else {
        _publishedQuizzes = quizzes;
      }

      debugPrint('✅ Fetched ${_publishedQuizzes.length} published quizzes');
      _isLoading = false;
      _isFetchingPublishedQuizzes = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error fetching published quizzes: $e');
      _isLoading = false;
      _isFetchingPublishedQuizzes = false;
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to fetch quizzes. Please try again.',
      );
      notifyListeners();
    }
  }

  // Get a single quiz by ID
  Future<Quiz?> getQuizById(String quizId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final doc = await _withTimeout(
        _firestore.collection('quizzes').doc(quizId).get(),
      );

      if (doc.exists) {
        _currentQuiz = Quiz.fromFirestore(doc);
        _isLoading = false;
        notifyListeners();
        return _currentQuiz;
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to fetch quiz. Please try again.',
      );
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

      final updatedQuiz = quiz.copyWith(lastModified: DateTime.now());

      await _withTimeout(_firestore
          .collection('quizzes')
          .doc(quiz.id)
          .update(updatedQuiz.toFirestore()));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to update quiz. Please try again.',
      );
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

      await _withTimeout(_firestore.collection('quizzes').doc(quizId).delete());
      _quizzes.removeWhere((q) => q.id == quizId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to delete quiz. Please try again.',
      );
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
    _extractedText = null;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear Groq error
  void clearGroqError() {
    _groqError = null;
    notifyListeners();
  }

  /// Generate quiz questions using Rag Backend Service
  Future<List<Question>?> generateQuestionsWithAI({
    required QuizConfig config,
    required String topic,
    required String uid,
    String? noteContent,
  }) async {
    try {
      _isLoading = true;
      _isGeneratingWithAI = true;
      _errorMessage = null;
      _groqError = null;
      notifyListeners();

      String content = noteContent ?? '';
      String documentId = '';

      if (content.isEmpty) {
        if (_uploadedBytes != null && _uploadedFileName != null) {
          debugPrint('Uploading PDF bytes to RAG backend...');
          documentId = await _runAiRequestWithRetry(
            () => _withAiTimeout(
              RagService.uploadPdfBytes(_uploadedBytes!, _uploadedFileName!,
                  onProgress: (p) {
                _uploadProgress = p;
                notifyListeners();
              }),
            ),
          );
        } else if (_uploadedFile != null) {
          debugPrint('Uploading PDF file to RAG backend...');
          documentId = await _runAiRequestWithRetry(
            () => _withAiTimeout(
                RagService.uploadPdfFile(_uploadedFile!, onProgress: (p) {
              _uploadProgress = p;
              notifyListeners();
            })),
          );
        } else {
          throw Exception(
              'Please select existing lecture notes or upload a PDF.');
        }
      } else {
        debugPrint('Uploading existing text to RAG backend...');
        documentId = await _runAiRequestWithRetry(
          () => _withAiTimeout(RagService.uploadRawText(content)),
        );
      }

      debugPrint(
          '🤖 Using Backend RAG API for question generation (DocID: $documentId)...');
      try {
        final questions = await _runAiRequestWithRetry(
          () => _withAiTimeout(
            RagService.generateRagQuiz(
              topic: topic,
              documentId: documentId,
              config: config,
              uid: uid,
            ),
          ),
        );

        debugPrint('✅ RagService generated ${questions.length} questions');

        _extractedText =
            "Context processed securely via backend RAG for topic: $topic";
        _isLoading = false;
        _isGeneratingWithAI = false;
        notifyListeners();
        return questions;
      } on GroqException catch (e) {
        debugPrint('❌ RAG API error: ${e.message} (Status: ${e.statusCode})');
        _groqError = e.message; // Show actual error from backend
        _isLoading = false;
        _isGeneratingWithAI = false;
        _errorMessage = e.message; // Use backend error message
        notifyListeners();
        return null;
      } catch (e) {
        debugPrint('❌ RAG parse/unknown error: $e');
        _groqError = _mapErrorMessage(e, fallback: 'AI generation failed.');
        _isLoading = false;
        _isGeneratingWithAI = false;
        _errorMessage = _mapErrorMessage(e,
            fallback: 'AI response parsing failed. Please try again.');
        notifyListeners();
        return null;
      }
    } catch (e) {
      _isLoading = false;
      _isGeneratingWithAI = false;
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to generate quiz. Please try again.',
      );
      _groqError = _mapErrorMessage(e,
          fallback: 'An unexpected error occurred during quiz generation.');
      debugPrint('❌ Error in generateQuestionsWithAI: $e');
      debugPrint('🐛 Stack trace: ${StackTrace.current}');
      notifyListeners();
      return null;
    }
  }

  /// Fetch all quiz attempts for a specific quiz
  Future<void> fetchQuizAttempts(String quizId) async {
    try {
      debugPrint('🔍 Fetching attempts for quiz: $quizId');
      _isLoading = true;
      notifyListeners();

      final snapshot = await _withTimeout(
        _firestore
            .collection('quizzes')
            .doc(quizId)
            .collection('attempts')
            .orderBy('endTime', descending: true)
            .get(),
      );

      _quizAttempts =
          snapshot.docs.map((doc) => QuizAttempt.fromFirestore(doc)).toList();

      debugPrint('✅ Fetched ${_quizAttempts.length} attempts for quiz $quizId');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error fetching quiz attempts: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save a quiz attempt to Firestore
  Future<bool> saveQuizAttempt(String quizId, QuizAttempt attempt) async {
    try {
      debugPrint('💾 Saving quiz attempt for student: ${attempt.studentId}');

      await _withTimeout(
        _firestore
            .collection('quizzes')
            .doc(quizId)
            .collection('attempts')
            .doc(attempt.id)
            .set(attempt.toFirestore()),
      );

      // Add to local list
      final index = _quizAttempts.indexWhere((a) => a.id == attempt.id);
      if (index >= 0) {
        _quizAttempts[index] = attempt;
      } else {
        _quizAttempts.insert(
            0, attempt); // Add to beginning (most recent first)
      }

      debugPrint('✅ Quiz attempt saved successfully');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error saving quiz attempt: $e');
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to save quiz attempt. Please try again.',
      );
      notifyListeners();
      return false;
    }
  }

  /// Fetch all attempts by a specific student across all quizzes
  Future<List<QuizAttempt>> fetchStudentAttempts(String studentId) async {
    try {
      debugPrint('🔍 Fetching attempts for student: $studentId');

      // Query all published quizzes and their attempts for this student
      final quizzesSnapshot = await _withTimeout(
        _firestore
            .collection('quizzes')
            .where('status', isEqualTo: QuizStatus.published.name)
            .get(),
      );

      List<QuizAttempt> allAttempts = [];

      for (var quizDoc in quizzesSnapshot.docs) {
        final attemptsSnapshot = await _withTimeout(
          _firestore
              .collection('quizzes')
              .doc(quizDoc.id)
              .collection('attempts')
              .where('studentId', isEqualTo: studentId)
              .orderBy('endTime', descending: true)
              .get(),
        );

        allAttempts.addAll(
          attemptsSnapshot.docs.map((doc) => QuizAttempt.fromFirestore(doc)),
        );
      }

      debugPrint(
          '✅ Fetched ${allAttempts.length} attempts for student $studentId');
      return allAttempts;
    } catch (e) {
      debugPrint('❌ Error fetching student attempts: $e');
      return [];
    }
  }
}
