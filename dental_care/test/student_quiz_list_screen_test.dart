import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';

import 'package:dental_care/view/student_quiz_list_screen.dart';
import 'package:dental_care/providers/quiz_provider.dart';
import 'package:dental_care/providers/quiz_attempt_provider.dart';
import 'package:dental_care/provider/auth_provider.dart';
import 'package:dental_care/utils/global_error_handler.dart';
import 'package:dental_care/utils/app_dialogs.dart';
import 'package:dental_care/widgets/loaders/app_loader.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockQuizProvider extends Mock
    with ChangeNotifier
    implements QuizProvider {}

class MockQuizAttemptProvider extends Mock
    with ChangeNotifier
    implements QuizAttemptProvider {}

class MockAuthProvider extends Mock
    with ChangeNotifier
    implements AuthProvider {}

class MockUser extends Mock implements User {}

void main() {
  late MockQuizProvider mockQuizProvider;
  late MockQuizAttemptProvider mockQuizAttemptProvider;
  late MockAuthProvider mockAuthProvider;
  late MockUser mockUser;

  setUp(() {
    AppDialogs.resetForTest();
    mockQuizProvider = MockQuizProvider();
    mockQuizAttemptProvider = MockQuizAttemptProvider();
    mockAuthProvider = MockAuthProvider();
    mockUser = MockUser();

    when(() => mockUser.uid).thenReturn('test_uid');
    when(() => mockAuthProvider.user).thenReturn(mockUser);

    when(() => mockQuizProvider.isLoading).thenReturn(false);
    when(() => mockQuizProvider.publishedQuizzes).thenReturn([]);

    when(() => mockQuizAttemptProvider.studentAttempts).thenReturn([]);
    when(() => mockQuizProvider.fetchPublishedQuizzes())
        .thenAnswer((_) async {});
    when(() => mockQuizAttemptProvider.fetchStudentAttempts(any()))
        .thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<QuizProvider>.value(value: mockQuizProvider),
        ChangeNotifierProvider<QuizAttemptProvider>.value(
            value: mockQuizAttemptProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
      ],
      child: MaterialApp(
        navigatorKey: GlobalErrorHandler.instance.navigatorKey,
        home: const StudentQuizListScreen(),
      ),
    );
  }

  group('StudentQuizListScreen Tests', () {
    testWidgets('Loading state - shows spinner and loading text',
        (WidgetTester tester) async {
      when(() => mockQuizProvider.isLoading).thenReturn(true);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(AppLoader), findsOneWidget);
      expect(find.text('Loading quizzes...'), findsOneWidget);
    });

    testWidgets('Happy Path - No quizzes shows empty state',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('No Quizzes Available'), findsOneWidget);
    });

    testWidgets('Error Path - SocketException shows No Internet dialog',
        (tester) async {
      when(() => mockQuizProvider.fetchPublishedQuizzes())
          .thenThrow(const SocketException('No Internet'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('No Internet'), findsOneWidget);
      expect(
          find.text(
              'No internet connection. Check your network and try again.'),
          findsOneWidget);
    });

    testWidgets('Error Path - TimeoutException shows Timeout dialog',
        (tester) async {
      when(() => mockQuizProvider.fetchPublishedQuizzes())
          .thenThrow(TimeoutException('Timeout'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(
          find.text(
              'The request timed out. Check your connection and try again.'),
          findsOneWidget);
    });

    testWidgets('Session Check - Null user shows session expired dialog',
        (tester) async {
      when(() => mockAuthProvider.user).thenReturn(null);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Session Expired'), findsOneWidget);
      expect(find.text('Your session has expired. Please log in again.'),
          findsOneWidget);
      expect(find.text('Log in again'), findsOneWidget);
    });
  });
}
