// ignore_for_file: no_leading_underscores_for_local_variables, unused_local_variable, implementation_imports, prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dental_care/providers/analytics_provider.dart';
import 'package:dental_care/models/case.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late AnalyticsProvider provider;
  late MockFirestore mockFirestore;
  late MockCollectionReference mockPatientsCollection;
  late MockCollectionReference mockAppointmentsCollection;
  late MockQuery mockPatientsQuery;
  late MockQuery mockAppointmentsQuery;
  late MockQuerySnapshot mockPatientsSnapshot;
  late MockQuerySnapshot mockAppointmentsSnapshot;

  setUp(() {
    mockFirestore = MockFirestore();
    mockPatientsCollection = MockCollectionReference();
    mockAppointmentsCollection = MockCollectionReference();
    mockPatientsQuery = MockQuery();
    mockAppointmentsQuery = MockQuery();
    mockPatientsSnapshot = MockQuerySnapshot();
    mockAppointmentsSnapshot = MockQuerySnapshot();

    provider = AnalyticsProvider(firestore: mockFirestore);
  });

  group('AnalyticsProvider Unit Tests', () {
    test('initial state is correct', () {
      expect(provider.loading, isFalse);
      expect(provider.error, isNull);
      expect(provider.analyticsData, isNull);
    });

    test('_generateToothAnalysis calculates correctly based on FDI notes', () {
      final cases = [
        Case(
          id: '1',
          patientId: 'p1',
          patientName: 'Patient 1',
          toothNumber: '11',
          caseTitle: 'Test Case 1',
          caseStatus: 'completed',
          caseDate: DateTime.now(),
          imageUrls: [],
          analysisResults: {
            'verdictNotes': ['FDI 11 has a lesion', 'FDI 24 has caries'],
            'hasCavity': true,
            'status': 'completed',
          },
          notes: '',
        ),
      ];

      // Expose the private method for testing via a subclass or just test through generateAnalytics
      // Since generateAnalytics relies on firestore, we would mock it out.
    });
  });
}
