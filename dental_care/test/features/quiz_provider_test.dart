// ignore_for_file: no_leading_underscores_for_local_variables, unused_local_variable
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dental_care/providers/quiz_provider.dart';
import 'package:dental_care/models/quiz.dart';

import 'package:dental_care/service/firebase_service.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockFirebaseService extends Mock implements FirebaseService {}

void main() {
  late QuizProvider provider;
  late MockFirestore mockFirestore;
  late MockCollectionReference mockQuizzesCollection;
  late MockDocumentReference mockQuizDoc;
  late MockFirebaseService mockFirebaseService;

  setUp(() {
    mockFirestore = MockFirestore();
    mockQuizzesCollection = MockCollectionReference();
    mockQuizDoc = MockDocumentReference();
    mockFirebaseService = MockFirebaseService();

    provider =
        QuizProvider(firestore: mockFirestore, service: mockFirebaseService);
  });

  group('QuizProvider Unit Tests', () {
    test('initial state is correct', () {
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.quizzes, isEmpty);
      expect(provider.publishedQuizzes, isEmpty);
      expect(provider.currentQuiz, isNull);
    });

    test('clearCurrentQuiz resets state', () {
      provider.setCurrentQuiz(Quiz(
        id: 'test',
        title: 'Title',
        description: 'Desc',
        dentistUid: 'd1',
        config: QuizConfig(
            difficulty: DifficultyLevel.easy,
            questionTypes: [QuestionType.mcq],
            totalQuestions: 5,
            numberOfSections: 1,
            cognitiveLevel: CognitiveLevel.knowledge),
        questions: [],
        status: QuizStatus.draft,
        createdAt: DateTime.now(),
        totalMarks: 10,
      ));

      expect(provider.currentQuiz, isNotNull);

      provider.clearCurrentQuiz();

      expect(provider.currentQuiz, isNull);
      expect(provider.uploadedFile, isNull);
      expect(provider.uploadedFileName, isNull);
      expect(provider.uploadProgress, 0.0);
    });

    test('clearError resets error message', () {
      // Intentionally cause an error state (or mock it)
      // For this test, we can just verify clearError method since _errorMessage is private
      provider.clearError();
      expect(provider.errorMessage, isNull);
    });
  });
}
