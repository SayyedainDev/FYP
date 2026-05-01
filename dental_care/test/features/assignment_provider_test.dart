import 'package:flutter_test/flutter_test.dart';
import 'package:dental_care/providers/assignment_provider.dart';

import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late AssignmentProvider provider;
  late MockFirestore mockFirestore;

  setUp(() {
    mockFirestore = MockFirestore();
    provider = AssignmentProvider(firestore: mockFirestore);
  });

  group('AssignmentProvider Unit Tests', () {
    test('initial state is correct', () {
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.assignments, isEmpty);
      expect(provider.submissions, isEmpty);
    });
  });
}
