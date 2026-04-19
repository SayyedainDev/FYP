import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionType {
  mcq,
  trueFalse,
  shortAnswer,
  longAnswer,
  fillInTheBlanks,
  scenarioBased,
}

enum DifficultyLevel { easy, medium, hard, mixed }

enum CognitiveLevel { knowledge, understanding, application, analysis, mixed }

enum QuizMode { exam, practice, adaptive, conceptual, analytical }

enum QuizStatus { draft, published, closed }

class QuizConfig {
  final DifficultyLevel difficulty;
  final int totalQuestions;
  final List<QuestionType> questionTypes;
  final int numberOfSections;
  final String marksDistribution; // 'equal' or 'custom'
  final List<int>? customMarksPerSection;
  final CognitiveLevel cognitiveLevel;
  final String contentCoverage; // 'entire' or specific topics
  final List<String>? specificTopics;
  final int? timeLimitMinutes;
  final bool includeAnswerKey;
  final String explanationLevel; // 'none', 'brief', 'detailed'
  final QuizMode? specialMode;

  QuizConfig({
    required this.difficulty,
    required this.totalQuestions,
    required this.questionTypes,
    this.numberOfSections = 1,
    this.marksDistribution = 'equal',
    this.customMarksPerSection,
    required this.cognitiveLevel,
    this.contentCoverage = 'entire',
    this.specificTopics,
    this.timeLimitMinutes,
    this.includeAnswerKey = true,
    this.explanationLevel = 'brief',
    this.specialMode,
  });

  /// Time limit in seconds (derived from minutes)
  int? get timeLimitSeconds =>
      timeLimitMinutes != null ? timeLimitMinutes! * 60 : null;

  Map<String, dynamic> toFirestore() {
    return {
      'difficulty': difficulty.name,
      'totalQuestions': totalQuestions,
      'questionTypes': questionTypes.map((e) => e.name).toList(),
      'numberOfSections': numberOfSections,
      'marksDistribution': marksDistribution,
      'customMarksPerSection': customMarksPerSection,
      'cognitiveLevel': cognitiveLevel.name,
      'contentCoverage': contentCoverage,
      'specificTopics': specificTopics,
      'timeLimitMinutes': timeLimitMinutes,
      'includeAnswerKey': includeAnswerKey,
      'explanationLevel': explanationLevel,
      'specialMode': specialMode?.name,
    };
  }

  factory QuizConfig.fromFirestore(Map<String, dynamic> data) {
    return QuizConfig(
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => DifficultyLevel.medium,
      ),
      totalQuestions: data['totalQuestions'] ?? 10,
      questionTypes: (data['questionTypes'] as List<dynamic>?)
              ?.map(
                (e) => QuestionType.values.firstWhere(
                  (qt) => qt.name == e,
                  orElse: () => QuestionType.mcq,
                ),
              )
              .toList() ??
          [QuestionType.mcq],
      numberOfSections: data['numberOfSections'] ?? 1,
      marksDistribution: data['marksDistribution'] ?? 'equal',
      customMarksPerSection: (data['customMarksPerSection'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      cognitiveLevel: CognitiveLevel.values.firstWhere(
        (e) => e.name == data['cognitiveLevel'],
        orElse: () => CognitiveLevel.mixed,
      ),
      contentCoverage: data['contentCoverage'] ?? 'entire',
      specificTopics: (data['specificTopics'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      timeLimitMinutes: data['timeLimitMinutes'],
      includeAnswerKey: data['includeAnswerKey'] ?? true,
      explanationLevel: data['explanationLevel'] ?? 'brief',
      specialMode: data['specialMode'] != null
          ? QuizMode.values.firstWhere(
              (e) => e.name == data['specialMode'],
              orElse: () => QuizMode.practice,
            )
          : null,
    );
  }
}

class Question {
  final String id;
  final String questionText;
  final QuestionType type;
  final List<String>? options; // For MCQ
  final int correctIndex; // Index of correct option (secure)
  final String? correctAnswer; // Legacy: kept for backward compat / non-MCQ
  final String? explanation;
  final String? hint;
  final int marks;
  final DifficultyLevel difficulty;
  final String? section;

  Question({
    required this.id,
    required this.questionText,
    required this.type,
    this.options,
    required this.correctIndex,
    this.correctAnswer,
    this.explanation,
    this.hint,
    required this.marks,
    required this.difficulty,
    this.section,
  });

  Question copyWith({
    String? id,
    String? questionText,
    QuestionType? type,
    List<String>? options,
    int? correctIndex,
    String? correctAnswer,
    String? explanation,
    int? marks,
    DifficultyLevel? difficulty,
    String? section,
  }) {
    return Question(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      type: type ?? this.type,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      marks: marks ?? this.marks,
      difficulty: difficulty ?? this.difficulty,
      section: section ?? this.section,
    );
  }

  /// Get the correct answer text (from options using index, or legacy field)
  String get correctAnswerText {
    if (options != null &&
        correctIndex >= 0 &&
        correctIndex < options!.length) {
      return options![correctIndex];
    }
    return correctAnswer ?? '';
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'questionText': questionText,
      'type': type.name,
      'options': options,
      'correctIndex': correctIndex,
      'correctAnswer': correctAnswerText, // Store for backward compat
      'explanation': explanation,
      'hint': hint,
      'marks': marks,
      'difficulty': difficulty.name,
      'section': section,
    };
  }

  /// Firestore data WITHOUT the answer (for student-facing reads)
  Map<String, dynamic> toFirestoreWithoutAnswer() {
    return {
      'id': id,
      'questionText': questionText,
      'type': type.name,
      'options': options,
      'explanation': explanation,
      'hint': hint,
      'marks': marks,
      'difficulty': difficulty.name,
      'section': section,
    };
  }

  factory Question.fromFirestore(Map<String, dynamic> data) {
    // Support both new correctIndex and legacy correctAnswer
    int parsedIndex = data['correctIndex'] ?? -1;

    // Fallback: if correctIndex is missing, try to find it from correctAnswer
    if (parsedIndex < 0 && data['correctAnswer'] != null) {
      final options = (data['options'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();
      if (options != null) {
        parsedIndex = options.indexOf(data['correctAnswer'].toString());
        if (parsedIndex < 0) parsedIndex = 0;
      } else {
        parsedIndex = 0;
      }
    }

    return Question(
      id: data['id'] ?? '',
      questionText: data['questionText'] ?? '',
      type: QuestionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => QuestionType.mcq,
      ),
      options: (data['options'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      correctIndex: parsedIndex >= 0 ? parsedIndex : 0,
      correctAnswer: data['correctAnswer']?.toString(),
      explanation: data['explanation'],
      hint: data['hint'],
      marks: data['marks'] ?? 1,
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => DifficultyLevel.medium,
      ),
      section: data['section'],
    );
  }
}

class Quiz {
  final String id;
  final String title;
  final String description;
  final String dentistUid; // creatorId (professor/dentist UID)
  final QuizConfig config;
  final List<Question> questions;
  final String? noteFileUrl;
  final String? noteFileName;
  final List<String>? lectureNoteIds;
  final String? additionalNotesUrl;
  final String? additionalNotesFileName;
  final String? sourceText; // Extracted text used for AI generation
  final QuizStatus status; // draft, published, closed
  final DateTime createdAt;
  final DateTime? lastModified;
  final int totalMarks;
  final Map<String, int>? sectionMarks;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.dentistUid,
    required this.config,
    required this.questions,
    this.noteFileUrl,
    this.noteFileName,
    this.lectureNoteIds,
    this.additionalNotesUrl,
    this.additionalNotesFileName,
    this.sourceText,
    this.status = QuizStatus.draft,
    required this.createdAt,
    this.lastModified,
    required this.totalMarks,
    this.sectionMarks,
  });

  /// Alias for professor/teacher context
  String get creatorId => dentistUid;

  bool get isDraft => status == QuizStatus.draft;
  bool get isPublished => status == QuizStatus.published;
  bool get isClosed => status == QuizStatus.closed;

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dentistUid': dentistUid,
      'config': config.toFirestore(),
      'questions': questions.map((q) => q.toFirestore()).toList(),
      'noteFileUrl': noteFileUrl,
      'noteFileName': noteFileName,
      'lectureNoteIds': lectureNoteIds,
      'additionalNotesUrl': additionalNotesUrl,
      'additionalNotesFileName': additionalNotesFileName,
      'sourceText': sourceText,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastModified':
          lastModified != null ? Timestamp.fromDate(lastModified!) : null,
      'totalMarks': totalMarks,
      'sectionMarks': sectionMarks,
    };
  }

  factory Quiz.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Quiz(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dentistUid: data['dentistUid'] ?? '',
      config: QuizConfig.fromFirestore(data['config'] ?? {}),
      questions: (data['questions'] as List<dynamic>?)
              ?.map((q) => Question.fromFirestore(q as Map<String, dynamic>))
              .toList() ??
          [],
      noteFileUrl: data['noteFileUrl'],
      noteFileName: data['noteFileName'],
      lectureNoteIds: (data['lectureNoteIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      additionalNotesUrl: data['additionalNotesUrl'],
      additionalNotesFileName: data['additionalNotesFileName'],
      sourceText: data['sourceText'],
      status: QuizStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'draft'),
        orElse: () => QuizStatus.draft,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastModified: (data['lastModified'] as Timestamp?)?.toDate(),
      totalMarks: data['totalMarks'] ?? 0,
      sectionMarks: data['sectionMarks'] != null
          ? Map<String, int>.from(data['sectionMarks'])
          : null,
    );
  }

  /// Create Quiz from raw map (for student-facing reads without doc reference)
  factory Quiz.fromMap(String id, Map<String, dynamic> data) {
    return Quiz(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dentistUid: data['dentistUid'] ?? '',
      config: QuizConfig.fromFirestore(data['config'] ?? {}),
      questions: (data['questions'] as List<dynamic>?)
              ?.map((q) => Question.fromFirestore(q as Map<String, dynamic>))
              .toList() ??
          [],
      noteFileUrl: data['noteFileUrl'],
      noteFileName: data['noteFileName'],
      sourceText: data['sourceText'],
      status: QuizStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'draft'),
        orElse: () => QuizStatus.draft,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastModified: (data['lastModified'] as Timestamp?)?.toDate(),
      totalMarks: data['totalMarks'] ?? 0,
    );
  }

  // Helper methods
  String get difficultyText {
    switch (config.difficulty) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
      case DifficultyLevel.mixed:
        return 'Mixed';
    }
  }

  String get timeText {
    if (config.timeLimitMinutes == null) return 'No time limit';
    final hours = config.timeLimitMinutes! ~/ 60;
    final minutes = config.timeLimitMinutes! % 60;
    if (hours > 0) {
      return minutes > 0 ? '$hours hr $minutes min' : '$hours hr';
    }
    return '$minutes min';
  }

  String get statusText {
    switch (status) {
      case QuizStatus.draft:
        return 'Draft';
      case QuizStatus.published:
        return 'Published';
      case QuizStatus.closed:
        return 'Closed';
    }
  }

  /// Copy quiz with modified fields
  Quiz copyWith({
    String? id,
    String? title,
    String? description,
    String? dentistUid,
    QuizConfig? config,
    List<Question>? questions,
    String? noteFileUrl,
    String? noteFileName,
    String? sourceText,
    QuizStatus? status,
    DateTime? createdAt,
    DateTime? lastModified,
    int? totalMarks,
    Map<String, int>? sectionMarks,
  }) {
    return Quiz(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dentistUid: dentistUid ?? this.dentistUid,
      config: config ?? this.config,
      questions: questions ?? this.questions,
      noteFileUrl: noteFileUrl ?? this.noteFileUrl,
      noteFileName: noteFileName ?? this.noteFileName,
      sourceText: sourceText ?? this.sourceText,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      totalMarks: totalMarks ?? this.totalMarks,
      sectionMarks: sectionMarks ?? this.sectionMarks,
    );
  }
}
