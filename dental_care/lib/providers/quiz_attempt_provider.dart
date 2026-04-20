import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/quiz.dart';
import '../models/quiz_attempt.dart';

/// Save status for auto-save indicator
enum SaveStatus { idle, saving, saved, error }

/// Provider for managing student quiz attempts and grading
class QuizAttemptProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Duration _requestTimeout = Duration(seconds: 30);

  List<QuizAttempt> _studentAttempts = [];
  QuizAttempt? _currentAttempt;
  Map<String, int> _currentResponses = {}; // questionId -> selectedOption
  bool _isLoading = false;
  String? _errorMessage;
  SaveStatus _saveStatus = SaveStatus.idle;
  Timer? _debounceTimer;
  Set<String> _visitedQuestions = {};
  bool _isFetchingStudentAttempts = false;

  // Getters
  List<QuizAttempt> get studentAttempts => _studentAttempts;
  QuizAttempt? get currentAttempt => _currentAttempt;
  Map<String, int> get currentResponses => _currentResponses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  SaveStatus get saveStatus => _saveStatus;
  Set<String> get visitedQuestions => _visitedQuestions;

  Future<T> _withTimeout<T>(Future<T> future) {
    return future.timeout(_requestTimeout);
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

  String _mapHttpStatusMessage(int statusCode) {
    if (statusCode == 400) {
      return 'Invalid request. Please check your input.';
    }
    if (statusCode == 401) {
      return 'Your session has expired. Please log in again.';
    }
    if (statusCode == 403) {
      return 'You do not have permission to perform this action.';
    }
    if (statusCode == 404) {
      return 'The requested item could not be found.';
    }
    if (statusCode >= 500) {
      return 'Something went wrong on our end. Please try again.';
    }
    return 'Request failed. Please try again.';
  }

  /// Generate a deterministic question order using attemptId as seed
  List<int> generateQuestionOrder(int questionCount, String attemptId) {
    final seed = attemptId.hashCode;
    final rng = Random(seed);
    final indices = List<int>.generate(questionCount, (i) => i);
    indices.shuffle(rng);
    return indices;
  }

  /// Start a new quiz attempt or resume an existing one
  Future<QuizAttempt?> startAttempt({
    required String quizId,
    required String quizTitle,
    required String studentId,
    required String studentName,
    required int totalMarks,
    required int questionCount,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Check for existing in-progress attempt
      final existing = await _withTimeout(_firestore
          .collection('attempts')
          .where('quizId', isEqualTo: quizId)
          .where('studentId', isEqualTo: studentId)
          .where('isSubmitted', isEqualTo: false)
          .limit(1)
          .get());

      if (existing.docs.isNotEmpty) {
        // Resume existing attempt
        _currentAttempt = QuizAttempt.fromFirestore(existing.docs.first);
        _currentResponses = {};
        _visitedQuestions = {};
        for (var r in _currentAttempt!.responses) {
          if (r.selectedOption != null && r.selectedOption! >= 0) {
            _currentResponses[r.questionId] = r.selectedOption!;
          }
          _visitedQuestions.add(r.questionId);
        }
        debugPrint('📋 Resuming existing attempt: ${_currentAttempt!.id}');
        _isLoading = false;
        notifyListeners();
        return _currentAttempt;
      }

      // Check if already submitted
      final submitted = await _withTimeout(_firestore
          .collection('attempts')
          .where('quizId', isEqualTo: quizId)
          .where('studentId', isEqualTo: studentId)
          .where('isSubmitted', isEqualTo: true)
          .limit(1)
          .get());

      if (submitted.docs.isNotEmpty) {
        _isLoading = false;
        _errorMessage = 'You have already completed this quiz.';
        _currentAttempt = QuizAttempt.fromFirestore(submitted.docs.first);
        notifyListeners();
        return null;
      }

      // Generate question order for new attempt
      // We create the doc first then use docRef.id as seed
      final tempId = _firestore.collection('attempts').doc().id;
      final questionOrder = generateQuestionOrder(questionCount, tempId);

      // Create new attempt
      final attempt = QuizAttempt(
        id: tempId,
        quizId: quizId,
        quizTitle: quizTitle,
        studentId: studentId,
        studentName: studentName,
        startTime: DateTime.now(),
        totalMarks: totalMarks,
        questionOrder: questionOrder,
      );

      await _withTimeout(_firestore
          .collection('attempts')
          .doc(tempId)
          .set(attempt.toFirestore()));

      _currentAttempt = attempt;
      _currentResponses = {};
      _visitedQuestions = {};

      debugPrint('✅ New attempt created: $tempId');

      _isLoading = false;
      notifyListeners();
      return _currentAttempt;
    } catch (e) {
      debugPrint('❌ Error starting attempt: $e');
      _isLoading = false;
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to start quiz. Please try again.',
      );
      notifyListeners();
      return null;
    }
  }

  /// Mark a question as visited
  void markVisited(String questionId) {
    _visitedQuestions.add(questionId);
  }

  /// Save a response for a question (debounced auto-save on selection)
  void saveResponse(String questionId, int selectedOption) {
    if (_currentAttempt == null || _currentAttempt!.isSubmitted) return;

    debugPrint(
        '🧪 LOG: saveResponse triggered -> Q: $questionId, Option: $selectedOption');
    _currentResponses[questionId] = selectedOption;
    _visitedQuestions.add(questionId);
    _saveStatus = SaveStatus.saving;
    notifyListeners();

    // Cancel previous debounce timer
    _debounceTimer?.cancel();
    debugPrint('🧪 LOG: Debounce reset');

    // Debounced persist to Firestore (300ms)
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      debugPrint('🧪 LOG: Firing _persistResponses() after debounce');
      _persistResponses();
    });
  }

  /// Persist current responses to Firestore (for progress saving)
  Future<void> _persistResponses() async {
    if (_currentAttempt == null || _currentAttempt!.isSubmitted) return;

    try {
      final responses = _currentResponses.entries
          .map((e) => QuizResponse(
                questionId: e.key,
                selectedOption: e.value,
              ))
          .toList();

      await _withTimeout(
          _firestore.collection('attempts').doc(_currentAttempt!.id).update({
        'responses': responses.map((r) => r.toFirestore()).toList(),
      }));

      _saveStatus = SaveStatus.saved;
      notifyListeners();

      // Reset to idle after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (_saveStatus == SaveStatus.saved) {
          _saveStatus = SaveStatus.idle;
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('⚠️ Failed to persist responses: $e');
      _saveStatus = SaveStatus.error;
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to save progress. Please try again.',
      );
      notifyListeners();
    }
  }

  /// The live Render.com URL
  final String backendUrl = const String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://fyp-groq.onrender.com',
  );

  /// Increment a violation counter via Node Express API
  Future<void> incrementViolation(String type) async {
    if (_currentAttempt == null) return;

    // Convert local type string to backend format
    String backendViolationType;
    switch (type) {
      case 'tabSwitch':
        backendViolationType = 'tab_switch';
        break;
      case 'fullscreenExit':
        backendViolationType = 'fullscreen_exit';
        break;
      case 'inactivity':
        backendViolationType = 'inactivity';
        break;
      default:
        backendViolationType = 'other';
    }

    try {
      final response = await _withTimeout(http.post(
        Uri.parse('$backendUrl/api/record-violation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'attemptId': _currentAttempt!.id,
          'uid': _currentAttempt!.studentId,
          'violationType': backendViolationType,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final shouldAutoSubmit = data['shouldAutoSubmit'] as bool? ?? false;
        final violationCount = data['violationCount'] as int? ?? 0;
        final warning = data['warning'] as String?;

        if (warning != null && warning.isNotEmpty) {
          debugPrint('⚠️ Server Warning: $warning');
        }

        // We optimistically update the local state to match the server
        if (backendViolationType == 'tab_switch') {
          _currentAttempt =
              _currentAttempt!.copyWith(tabSwitchCount: violationCount);
        } else if (backendViolationType == 'fullscreen_exit') {
          _currentAttempt =
              _currentAttempt!.copyWith(fullscreenExitCount: violationCount);
        } else if (backendViolationType == 'inactivity') {
          _currentAttempt =
              _currentAttempt!.copyWith(inactivityCount: violationCount);
        }

        if (shouldAutoSubmit) {
          _currentAttempt = _currentAttempt!.copyWith(
            isSubmitted: true,
            autoSubmitTriggered: true,
          );
          debugPrint('🚫 AUTO-SUBMIT TRIGGERED FROM SERVER!');
        }

        notifyListeners();
      } else {
        debugPrint(
            '❌ Server returned ${response.statusCode}: ${response.body}');
        _errorMessage = _mapHttpStatusMessage(response.statusCode);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Failed to call record-violation API: $e');
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to sync quiz monitoring data. Please try again.',
      );
      notifyListeners();
    }
  }

  /// Submit the attempt and perform grading
  Future<QuizAttempt?> submitAttempt({
    required Quiz quiz,
  }) async {
    if (_currentAttempt == null) return null;

    _debounceTimer?.cancel();

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint(
          '📝 Submitting attempt (server will grade): ${_currentAttempt!.id}');

      // Gather responses (with client-side grading)
      final rawResponses = <QuizResponse>[];
      int totalScore = 0;

      for (final question in quiz.questions) {
        final selectedOption = _currentResponses[question.id];

        bool isCorrect = false;
        if (selectedOption != null && selectedOption >= 0) {
          isCorrect = selectedOption == question.correctIndex;
          if (isCorrect) {
            totalScore += question.marks;
          }
        }

        rawResponses.add(QuizResponse(
          questionId: question.id,
          selectedOption: selectedOption,
          isCorrect: isCorrect,
        ));
      }

      // Update attempt in Firestore directly with graded results
      final now = DateTime.now();
      await _withTimeout(
          _firestore.collection('attempts').doc(_currentAttempt!.id).update({
        'endTime': Timestamp.fromDate(now),
        'isSubmitted': true,
        'responses': rawResponses.map((r) => r.toFirestore()).toList(),
        'score': totalScore,
      }));

      _currentAttempt = _currentAttempt!.copyWith(
        endTime: now,
        isSubmitted: true,
        responses: rawResponses,
        score: totalScore,
      );

      // No longer polling backend - grading is done
      debugPrint(
          '✅ Attempt graded and submitted successfully: ${_currentAttempt!.id} (Score: $totalScore)');

      _isLoading = false;
      notifyListeners();
      return _currentAttempt;
    } catch (e) {
      debugPrint('❌ Error submitting attempt: $e');
      _isLoading = false;
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to submit quiz. Please try again.',
      );
      notifyListeners();
      return null;
    }
  }

  /// Fetch all attempts for a student
  Future<void> fetchStudentAttempts(String studentId) async {
    if (_isFetchingStudentAttempts) return;

    try {
      _isFetchingStudentAttempts = true;
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final snapshot = await _withTimeout(_firestore
          .collection('attempts')
          .where('studentId', isEqualTo: studentId)
          .orderBy('startTime', descending: true)
          .get());

      _studentAttempts =
          snapshot.docs.map((doc) => QuizAttempt.fromFirestore(doc)).toList();

      debugPrint('✅ Fetched ${_studentAttempts.length} attempts');

      _isLoading = false;
      _isFetchingStudentAttempts = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error fetching attempts: $e');
      _isLoading = false;
      _isFetchingStudentAttempts = false;
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to fetch results. Please try again.',
      );
      notifyListeners();
    }
  }

  // Get attempt for review (read-only access)
  Future<QuizAttempt?> getAttemptForReview({
    required String quizId,
    required String studentId,
  }) async {
    try {
      final snapshot = await _withTimeout(_firestore
          .collection('attempts')
          .where('quizId', isEqualTo: quizId)
          .where('studentId', isEqualTo: studentId)
          .where('isSubmitted', isEqualTo: true)
          .limit(1)
          .get());

      if (snapshot.docs.isEmpty) {
        _errorMessage = 'No submitted attempt found for this quiz.';
        notifyListeners();
        return null;
      }

      final attempt = QuizAttempt.fromFirestore(snapshot.docs.first);
      _currentAttempt = attempt;

      // Load responses for review mode
      _currentResponses = {};
      _visitedQuestions = {};
      for (var r in attempt.responses) {
        if (r.selectedOption != null && r.selectedOption! >= 0) {
          _currentResponses[r.questionId] = r.selectedOption!;
        }
        _visitedQuestions.add(r.questionId);
      }

      debugPrint('📖 Loaded attempt for review: ${attempt.id}');
      notifyListeners();
      return attempt;
    } catch (e) {
      debugPrint('❌ Error getting attempt for review: $e');
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Unable to load attempt. Please try again.',
      );
      notifyListeners();
      return null;
    }
  }

  /// Fetch attempts for a specific quiz (for professors to view student results)
  Future<List<QuizAttempt>> fetchQuizAttempts(String quizId) async {
    try {
      final snapshot = await _withTimeout(_firestore
          .collection('attempts')
          .where('quizId', isEqualTo: quizId)
          .where('isSubmitted', isEqualTo: true)
          .orderBy('score', descending: true)
          .get());

      return snapshot.docs
          .map((doc) => QuizAttempt.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching quiz attempts: $e');
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to fetch quiz attempts. Please try again.',
      );
      notifyListeners();
      return [];
    }
  }

  /// Get a specific attempt result
  Future<QuizAttempt?> getAttemptResult(String attemptId) async {
    try {
      final doc = await _withTimeout(
          _firestore.collection('attempts').doc(attemptId).get());

      if (doc.exists) {
        return QuizAttempt.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching attempt: $e');
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to fetch attempt details. Please try again.',
      );
      notifyListeners();
      return null;
    }
  }

  /// Check if student has already attempted this quiz
  Future<QuizAttempt?> getExistingAttempt(
    String quizId,
    String studentId,
  ) async {
    try {
      final snapshot = await _withTimeout(_firestore
          .collection('attempts')
          .where('quizId', isEqualTo: quizId)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get());

      if (snapshot.docs.isNotEmpty) {
        return QuizAttempt.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error checking existing attempt: $e');
      _errorMessage = _mapErrorMessage(
        e,
        fallback: 'Failed to load existing attempt. Please try again.',
      );
      notifyListeners();
      return null;
    }
  }

  /// Clear current attempt state
  void clearCurrentAttempt() {
    _currentAttempt = null;
    _currentResponses = {};
    _visitedQuestions = {};
    _saveStatus = SaveStatus.idle;
    _debounceTimer?.cancel();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
