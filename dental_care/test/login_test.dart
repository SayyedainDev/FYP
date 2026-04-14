import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';

import 'package:dental_care/view/login.dart';
import 'package:dental_care/provider/auth_provider.dart';
import 'package:dental_care/utils/app_dialogs.dart';

class MockAuthProvider extends Mock
    with ChangeNotifier
    implements AuthProvider {}

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    AppDialogs.resetForTest();
    mockAuthProvider = MockAuthProvider();
    when(() => mockAuthProvider.loading).thenReturn(false);
    when(() => mockAuthProvider.uid).thenReturn(null);
    when(() => mockAuthProvider.login(any(), any())).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const LoginPage()),
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const Scaffold(body: Text('Dashboard Stub')),
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('LoginPage Tests', () {
    testWidgets('Success Path - Navigates to dashboard after login',
        (WidgetTester tester) async {
      when(() => mockAuthProvider.login(any(), any())).thenAnswer((_) async {
        when(() => mockAuthProvider.uid).thenReturn('user_123');
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 900));

      await tester.enterText(
          find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, '12345678');

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard Stub'), findsOneWidget);
    });

    testWidgets('Validation Error - Empty form', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 900));

      await tester.tap(find.text('Sign in'));
      await tester.pump(const Duration(milliseconds: 600));

      // Inline validation
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);

      // Warning Dialog
      expect(find.text('Missing Fields'), findsOneWidget);
      expect(find.text('Please fill in all required fields.'), findsOneWidget);
    });

    testWidgets('Error Path - Exception on login shows dialog', (tester) async {
      when(() => mockAuthProvider.login(any(), any()))
          .thenThrow(Exception('Bad password'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 900));

      // Enter valid input
      await tester.enterText(
          find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, '12345678');

      await tester.tap(find.text('Sign in'));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Bad password'), findsOneWidget);
    });

    testWidgets('Error Path - TimeoutException shows Timeout dialog',
        (tester) async {
      when(() => mockAuthProvider.login(any(), any()))
          .thenThrow(TimeoutException('Timeout'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 900));

      await tester.enterText(
          find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, '12345678');

      await tester.tap(find.text('Sign in'));
      await tester.pump(const Duration(milliseconds: 700));

      expect(
          find.text(
              'The request timed out. Check your connection and try again.'),
          findsOneWidget);
    });

    testWidgets('Error Path - SocketException shows No Internet dialog',
        (tester) async {
      when(() => mockAuthProvider.login(any(), any()))
          .thenThrow(const SocketException('No Internet'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 900));

      await tester.enterText(
          find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, '12345678');

      await tester.tap(find.text('Sign in'));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('No Internet'), findsOneWidget);
      expect(
          find.text(
              'No internet connection. Check your network and try again.'),
          findsOneWidget);
    });
  });
}
