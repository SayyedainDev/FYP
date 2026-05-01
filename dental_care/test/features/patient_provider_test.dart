import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dental_care/providers/patient_provider.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late PatientProvider provider;
  late MockFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    mockFirestore = MockFirestore();
    mockAuth = MockFirebaseAuth();
    when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.empty());

    provider = PatientProvider(firestore: mockFirestore, auth: mockAuth);
  });

  group('PatientProvider Unit Tests', () {
    test('initial state is correct', () {
      expect(provider.loading, isFalse);
      expect(provider.error, isNull);
      expect(provider.patients, isEmpty);
      expect(provider.totalPatients, 0);
    });
  });
}
