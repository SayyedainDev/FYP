import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';

import 'package:dental_care/view/register.dart';
import 'package:dental_care/provider/auth_provider.dart';
import 'package:dental_care/utils/global_error_handler.dart';
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
    when(() => mockAuthProvider.register(any(), any()))
        .thenAnswer((_) async {});
  });

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Widget createWidgetUnderTest() {
    return MediaQuery(
      data: const MediaQueryData(
        size: Size(1600, 2400),
        textScaler: TextScaler.linear(0.9),
      ),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        ],
        child: MaterialApp(
          navigatorKey: GlobalErrorHandler.instance.navigatorKey,
          home: const RegisterPage(),
        ),
      ),
    );
  }

  group('RegisterPage Tests', () {
    testWidgets('Validation Error - Passwords do not match',
        (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.contains('A RenderFlex overflowed by')) {
          return;
        }
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 900));

      final fields = find.byType(TextFormField);
      expect(fields, findsWidgets);

      await tester.enterText(fields.at(0), 'John');
      await tester.enterText(fields.at(1), 'Doe');
      await tester.enterText(fields.at(2), 'john@example.com');
      await tester.enterText(fields.at(3), 'password123');
      await tester.enterText(fields.at(4), 'different123');
      await tester.enterText(fields.at(5), 'DENT-001');
      await tester.enterText(fields.at(6), '35202-1234567-1');
      await tester.enterText(fields.at(7), 'Clinic Street 1');
      await tester.enterText(fields.at(8), 'BDS');

      await tester.tap(find.text('Submit & Continue'));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Passwords do not match'), findsOneWidget);
      verifyNever(() => mockAuthProvider.register(any(), any()));
    });

    testWidgets('Validation Error - Empty form', (WidgetTester tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.contains('A RenderFlex overflowed by')) {
          return;
        }
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 900));

      await tester.tap(find.text('Submit & Continue'));
      await tester.pump(const Duration(milliseconds: 700));

      // Warning Dialog
      expect(find.text('Missing Fields'), findsOneWidget);
      expect(find.text('Please fill in all required fields.'), findsOneWidget);
    });

    testWidgets('Error Path - SocketException shows No Internet dialog',
        (tester) async {
      when(() => mockAuthProvider.register(any(), any()))
          .thenThrow(const SocketException('No Internet'));

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.contains('A RenderFlex overflowed by')) {
          return;
        }
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 900));

      final fields = find.byType(TextFormField);
      expect(fields, findsWidgets);

      await tester.enterText(fields.at(0), 'John');
      await tester.enterText(fields.at(1), 'Doe');
      await tester.enterText(fields.at(2), 'john@example.com');
      await tester.enterText(fields.at(3), 'password123');
      await tester.enterText(fields.at(4), 'password123');
      await tester.enterText(fields.at(5), 'DENT-001');
      await tester.enterText(fields.at(6), '35202-1234567-1');
      await tester.enterText(fields.at(7), 'Clinic Street 1');
      await tester.enterText(fields.at(8), 'BDS');

      await tester.tap(find.text('Submit & Continue'));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('No Internet'), findsOneWidget);
      expect(
          find.text(
              'No internet connection. Check your network and try again.'),
          findsOneWidget);
    });

    testWidgets('Error Path - TimeoutException shows Timeout dialog',
        (tester) async {
      when(() => mockAuthProvider.register(any(), any()))
          .thenThrow(TimeoutException('Timeout'));

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.contains('A RenderFlex overflowed by')) {
          return;
        }
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 900));

      final fields = find.byType(TextFormField);
      expect(fields, findsWidgets);

      await tester.enterText(fields.at(0), 'John');
      await tester.enterText(fields.at(1), 'Doe');
      await tester.enterText(fields.at(2), 'john@example.com');
      await tester.enterText(fields.at(3), 'password123');
      await tester.enterText(fields.at(4), 'password123');
      await tester.enterText(fields.at(5), 'DENT-001');
      await tester.enterText(fields.at(6), '35202-1234567-1');
      await tester.enterText(fields.at(7), 'Clinic Street 1');
      await tester.enterText(fields.at(8), 'BDS');

      await tester.tap(find.text('Submit & Continue'));
      await tester.pump(const Duration(milliseconds: 700));

      expect(
          find.text(
              'The request timed out. Check your connection and try again.'),
          findsOneWidget);
    });
  });
}
