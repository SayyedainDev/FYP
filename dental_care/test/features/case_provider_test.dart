import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dental_care/providers/case_provider.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  late CaseProvider provider;
  late MockFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    mockFirestore = MockFirestore();
    mockAuth = MockFirebaseAuth();
    when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.empty());
    when(() => mockAuth.currentUser).thenReturn(null);

    provider = CaseProvider(firestore: mockFirestore, auth: mockAuth);
  });

  group('CaseProvider Unit Tests', () {
    test('initial state is correct', () {
      expect(provider.loading, isFalse);
      expect(provider.error, isNull);
      expect(provider.cases, isEmpty);
      expect(provider.allCases, isEmpty);
      expect(provider.recentCases, isEmpty);
      expect(provider.totalCases, 0);
      expect(provider.cavitiesDetected, 0);
      expect(provider.healthyCases, 0);
    });

    test('clearFilters resets all filters', () {
      provider.setPatientFilter('p1');
      provider.setCaseStatusFilter('Completed');
      provider.setSearchQuery('test');

      expect(provider.filterPatientId, 'p1');
      expect(provider.filterCaseStatus, 'Completed');
      expect(provider.searchQuery, 'test');

      provider.clearFilters();

      expect(provider.filterPatientId, isNull);
      expect(provider.filterCaseStatus, isNull);
      expect(provider.searchQuery, isEmpty);
    });
  });
}
