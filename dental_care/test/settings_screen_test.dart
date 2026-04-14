import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dental_care/view/settings_screen.dart';
import 'package:dental_care/utils/app_dialogs.dart';
import 'package:dental_care/utils/global_error_handler.dart';

void main() {
  setUp(() {
    AppDialogs.resetForTest();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      navigatorKey: GlobalErrorHandler.instance.navigatorKey,
      home: const Scaffold(body: SettingsScreen()),
    );
  }

  group('SettingsScreen Tests', () {
    testWidgets('Renders key settings sections', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Profile Information'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Privacy & Security'), findsOneWidget);
      expect(find.text('Update Profile'), findsOneWidget);
    });

    testWidgets('Empty profile name shows validation snack bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Update Profile'));
      await tester.pump();

      expect(find.text('Name cannot be empty'), findsOneWidget);
    });
  });
}
