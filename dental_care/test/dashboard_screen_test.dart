import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:dental_care/view/dashboard_screen.dart';
import 'package:dental_care/providers/patient_provider.dart';
import 'package:dental_care/providers/case_provider.dart';
import 'package:dental_care/utils/global_error_handler.dart';

class MockPatientProvider extends Mock implements PatientProvider {}
class MockCaseProvider extends Mock implements CaseProvider {}

void main() {
  late MockPatientProvider mockPatientProvider;
  late MockCaseProvider mockCaseProvider;

  setUp(() {
    mockPatientProvider = MockPatientProvider();
    mockCaseProvider = MockCaseProvider();

    when(() => mockPatientProvider.totalPatients).thenReturn(10);
    when(() => mockPatientProvider.getRecentPatients(limit: any(named: 'limit'))).thenReturn([]);
    
    when(() => mockCaseProvider.totalCases).thenReturn(5);
    when(() => mockCaseProvider.cavitiesDetected).thenReturn(2);
    when(() => mockCaseProvider.healthyCases).thenReturn(3);
    when(() => mockCaseProvider.recentCases).thenReturn([]);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PatientProvider>.value(value: mockPatientProvider),
        ChangeNotifierProvider<CaseProvider>.value(value: mockCaseProvider),
      ],
      child: MaterialApp(
        navigatorKey: GlobalErrorHandler.instance.navigatorKey,
        home: const Scaffold(body: DashboardScreen()),
      ),
    );
  }

  group('DashboardScreen Tests', () {
    testWidgets('Renders dashboard insights properly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Patients'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('Scans'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('Empty states are shown when there is no recent data', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('No recent activity'), findsOneWidget);
      expect(find.text('No patients yet'), findsOneWidget);
    });
  });
}
