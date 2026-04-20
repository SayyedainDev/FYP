import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single question response from a student
class QuizResponse {
  final String questionId;
  final int? selectedOption; // Index of selected option, null if unanswered
  final bool? isCorrect; // Populated after grading

  QuizResponse({
    required this.questionId,
    this.selectedOption,
    this.isCorrect,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'questionId': questionId,
      'selectedOption': selectedOption ?? -1,
      'isCorrect': isCorrect,
    };
  }

  factory QuizResponse.fromFirestore(Map<String, dynamic> data) {
    final sel = data['selectedOption'];
    return QuizResponse(
      questionId: data['questionId'] ?? '',
      selectedOption: (sel != null && sel is int && sel >= 0) ? sel : null,
      isCorrect: data['isCorrect'],
    );
  }
}

/// Represents a student's attempt at a quiz
class QuizAttempt {
  final String id;
  final String quizId;
  final String quizTitle;
  final String studentId;
  final String studentName;
  final DateTime startTime;
  final DateTime? endTime;
  final int score;
  final int totalMarks;
  final bool isSubmitted;
  final List<QuizResponse> responses;

  // Anti-cheating tracking
  final int tabSwitchCount;
  final int fullscreenExitCount;
  final int inactivityCount;
  final bool autoSubmitTriggered;

  // Question order (shuffled indices for deterministic randomization)
  final List<int> questionOrder;

  QuizAttempt({
    required this.id,
    required this.quizId,
    required this.quizTitle,
    required this.studentId,
    required this.studentName,
    required this.startTime,
    this.endTime,
    this.score = 0,
    required this.totalMarks,
    this.isSubmitted = false,
    this.responses = const [],
    this.tabSwitchCount = 0,
    this.fullscreenExitCount = 0,
    this.inactivityCount = 0,
    this.autoSubmitTriggered = false,
    this.questionOrder = const [],
  });

  /// Percentage score (0-100)
  double get scorePercentage => totalMarks > 0 ? (score / totalMarks) * 100 : 0;

  /// Duration of the attempt
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  /// Human-readable duration text
  String get durationText {
    final d = duration;
    if (d == null) return 'In progress';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes min $seconds sec';
    }
    return '$seconds sec';
  }

  /// Grade letter based on percentage
  String get grade {
    final pct = scorePercentage;
    if (pct >= 90) return 'A+';
    if (pct >= 85) return 'A';
    if (pct >= 80) return 'A-';
    if (pct >= 75) return 'B+';
    if (pct >= 70) return 'B';
    if (pct >= 65) return 'B-';
    if (pct >= 60) return 'C+';
    if (pct >= 55) return 'C';
    if (pct >= 50) return 'C-';
    if (pct >= 45) return 'D';
    return 'F';
  }

  /// Whether the student passed (>= 60%)
  bool get isPassed => scorePercentage >= 60;

  /// Total violation count
  int get totalViolations =>
      tabSwitchCount + fullscreenExitCount + inactivityCount;

  /// Whether the attempt has been fully graded
  bool get isGraded {
    if (!isSubmitted) return false;
    if (responses.isEmpty) return false;
    return responses.every((r) => r.isCorrect != null);
  }

  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
      'quizId': quizId,
      'quizTitle': quizTitle,
      'studentId': studentId,
      'studentName': studentName,
      'startTime': Timestamp.fromDate(startTime),
      'score': score,
      'totalMarks': totalMarks,
      'isSubmitted': isSubmitted,
      'responses': responses.map((r) => r.toFirestore()).toList(),
      'tabSwitchCount': tabSwitchCount,
      'fullscreenExitCount': fullscreenExitCount,
      'inactivityCount': inactivityCount,
      'autoSubmitTriggered': autoSubmitTriggered,
      'questionOrder': questionOrder,
    };

    // Only include optional fields if they're not null
    if (endTime != null) {
      data['endTime'] = Timestamp.fromDate(endTime!);
    }

    return data;
  }

  factory QuizAttempt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('Document data is null for attempt ${doc.id}');
    }

    List<QuizResponse> parseResponses(dynamic responsesData) {
      if (responsesData == null) return [];
      if (responsesData is! List) return [];

      return responsesData
          .whereType<Map<String, dynamic>>() // Filter out nulls
          .map((r) => QuizResponse.fromFirestore(r))
          .toList();
    }

    List<int> parseQuestionOrder(dynamic orderData) {
      if (orderData == null) return [];
      if (orderData is! List) return [];

      return orderData
          .whereType<int>() // Only keep integers
          .toList();
    }

    return QuizAttempt(
      id: doc.id,
      quizId: (data['quizId'] as String?) ?? '',
      quizTitle: (data['quizTitle'] as String?) ?? '',
      studentId: (data['studentId'] as String?) ?? '',
      studentName: (data['studentName'] as String?) ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      score: (data['score'] as int?) ?? 0,
      totalMarks: (data['totalMarks'] as int?) ?? 0,
      isSubmitted: (data['isSubmitted'] as bool?) ?? false,
      responses: parseResponses(data['responses']),
      tabSwitchCount: (data['tabSwitchCount'] as int?) ?? 0,
      fullscreenExitCount: (data['fullscreenExitCount'] as int?) ?? 0,
      inactivityCount: (data['inactivityCount'] as int?) ?? 0,
      autoSubmitTriggered: (data['autoSubmitTriggered'] as bool?) ?? false,
      questionOrder: parseQuestionOrder(data['questionOrder']),
    );
  }

  /// Create a copy with modified fields
  QuizAttempt copyWith({
    String? id,
    String? quizId,
    String? quizTitle,
    String? studentId,
    String? studentName,
    DateTime? startTime,
    DateTime? endTime,
    int? score,
    int? totalMarks,
    bool? isSubmitted,
    List<QuizResponse>? responses,
    int? tabSwitchCount,
    int? fullscreenExitCount,
    int? inactivityCount,
    bool? autoSubmitTriggered,
    List<int>? questionOrder,
  }) {
    return QuizAttempt(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      quizTitle: quizTitle ?? this.quizTitle,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      score: score ?? this.score,
      totalMarks: totalMarks ?? this.totalMarks,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      responses: responses ?? this.responses,
      tabSwitchCount: tabSwitchCount ?? this.tabSwitchCount,
      fullscreenExitCount: fullscreenExitCount ?? this.fullscreenExitCount,
      inactivityCount: inactivityCount ?? this.inactivityCount,
      autoSubmitTriggered: autoSubmitTriggered ?? this.autoSubmitTriggered,
      questionOrder: questionOrder ?? this.questionOrder,
    );
  }
}
