// ignore_for_file: no_leading_underscores_for_local_variables, unused_local_variable
import 'package:flutter_test/flutter_test.dart';
import 'package:dental_care/features/lecture_notes/providers/lecture_note_provider.dart';

import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dental_care/service/firebase_service.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}

class MockFirebaseService extends Mock implements FirebaseService {}

void main() {
  late LectureNoteProvider provider;
  late MockFirestore mockFirestore;
  late MockFirebaseService mockFirebaseService;

  setUp(() {
    mockFirestore = MockFirestore();
    mockFirebaseService = MockFirebaseService();
    provider = LectureNoteProvider();
  });

  group('LectureNoteProvider Unit Tests', () {
    test('initial state is correct', () {
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.notes, isEmpty);
    });

    test('clearError resets error message', () {
      provider.clearError();
      expect(provider.errorMessage, isNull);
    });
  });
}
