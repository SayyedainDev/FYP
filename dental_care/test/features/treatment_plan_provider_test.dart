import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dental_care/providers/treatment_plan_provider.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late TreatmentPlanProvider provider;
  late MockFirestore mockFirestore;

  setUp(() {
    mockFirestore = MockFirestore();
    provider = TreatmentPlanProvider(firestore: mockFirestore);
  });

  group('TreatmentPlanProvider Unit Tests', () {
    test('initial state is correct', () {
      expect(provider.loading, isFalse);
      expect(provider.error, isNull);
      expect(provider.treatmentPlans, isEmpty);
      expect(provider.activePlans, isEmpty);
    });

    test('getTotalCost returns 0 when no plans', () {
      expect(provider.getTotalCost('p1'), 0.0);
    });

    test('getPatientPlans returns empty list when no plans', () {
      expect(provider.getPatientPlans('p1'), isEmpty);
    });
  });
}
