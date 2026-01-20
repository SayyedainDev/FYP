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
      questionTypes:
          (data['questionTypes'] as List<dynamic>?)
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
  final String correctAnswer;
  final String? explanation;
  final int marks;
  final DifficultyLevel difficulty;
  final String? section;

  Question({
    required this.id,
    required this.questionText,
    required this.type,
    this.options,
    required this.correctAnswer,
    this.explanation,
    required this.marks,
    required this.difficulty,
    this.section,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'questionText': questionText,
      'type': type.name,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'marks': marks,
      'difficulty': difficulty.name,
      'section': section,
    };
  }

  factory Question.fromFirestore(Map<String, dynamic> data) {
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
      correctAnswer: data['correctAnswer'] ?? '',
      explanation: data['explanation'],
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
  final String dentistUid;
  final QuizConfig config;
  final List<Question> questions;
  final String? noteFileUrl;
  final String? noteFileName;
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
    required this.createdAt,
    this.lastModified,
    required this.totalMarks,
    this.sectionMarks,
  });

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
      'createdAt': Timestamp.fromDate(createdAt),
      'lastModified': lastModified != null
          ? Timestamp.fromDate(lastModified!)
          : null,
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
      questions:
          (data['questions'] as List<dynamic>?)
              ?.map((q) => Question.fromFirestore(q as Map<String, dynamic>))
              .toList() ??
          [],
      noteFileUrl: data['noteFileUrl'],
      noteFileName: data['noteFileName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastModified: (data['lastModified'] as Timestamp?)?.toDate(),
      totalMarks: data['totalMarks'] ?? 0,
      sectionMarks: data['sectionMarks'] != null
          ? Map<String, int>.from(data['sectionMarks'])
          : null,
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
}
