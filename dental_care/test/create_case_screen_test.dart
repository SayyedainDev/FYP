import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:dental_care/provider/auth_provider.dart';
import 'package:dental_care/utils/app_dialogs.dart';
import 'package:dental_care/utils/global_error_handler.dart';
import 'package:dental_care/view/create_case_screen.dart';

class MockAuthProvider extends Mock
    with ChangeNotifier
    implements AuthProvider {}

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    AppDialogs.resetForTest();
    mockAuthProvider = MockAuthProvider();
    when(() => mockAuthProvider.userRole).thenReturn('Student');
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
      ],
      child: MaterialApp(
        navigatorKey: GlobalErrorHandler.instance.navigatorKey,
        home: const Scaffold(body: CreateCaseScreen()),
      ),
    );
  }

  testWidgets('Student role - upload tap shows access denied warning',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();

    expect(find.text('Access Denied'), findsOneWidget);
    expect(
      find.text(
          'Students have view-only access. Upload requires Dentist role.'),
      findsOneWidget,
    );
  });
}
