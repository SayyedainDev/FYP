import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dental_care/providers/appointment_provider.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late AppointmentProvider provider;
  late MockFirestore mockFirestore;

  setUp(() {
    mockFirestore = MockFirestore();
    provider = AppointmentProvider(firestore: mockFirestore);
  });

  group('AppointmentProvider Unit Tests', () {
    test('initial state is correct', () {
      expect(provider.loading, isFalse);
      expect(provider.error, isNull);
      expect(provider.appointments, isEmpty);
      expect(provider.upcomingAppointments, isEmpty);
      expect(provider.completedAppointments, isEmpty);
      expect(provider.completionRate, 0);
    });
  });
}
