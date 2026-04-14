import 'package:dental_care/models/lecture_note.dart';
import 'package:dental_care/provider/auth_provider.dart';
import 'package:dental_care/providers/lecture_notes_provider.dart';
import 'package:dental_care/utils/app_dialogs.dart';
import 'package:dental_care/utils/global_error_handler.dart';
import 'package:dental_care/view/lecture_notes_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockAuthProvider extends Mock
    with ChangeNotifier
    implements AuthProvider {}

class MockLectureNotesProvider extends Mock
    with ChangeNotifier
    implements LectureNotesProvider {}

class MockUser extends Mock implements User {}

void main() {
  late MockAuthProvider mockAuthProvider;
  late MockLectureNotesProvider mockNotesProvider;
  late MockUser mockUser;

  setUp(() {
    AppDialogs.resetForTest();

    mockAuthProvider = MockAuthProvider();
    mockNotesProvider = MockLectureNotesProvider();
    mockUser = MockUser();

    when(() => mockUser.uid).thenReturn('dentist_1');
    when(() => mockAuthProvider.user).thenReturn(mockUser);

    when(() => mockNotesProvider.isLoading).thenReturn(false);
    when(() => mockNotesProvider.uploadProgress).thenReturn(0.0);
    when(() => mockNotesProvider.errorMessage).thenReturn(null);
    when(() => mockNotesProvider.getLectureNotesStream(any()))
        .thenAnswer((_) => Stream.value([]));
    when(() => mockNotesProvider.deleteLectureNote(
          noteId: any(named: 'noteId'),
          dentistUid: any(named: 'dentistUid'),
          fileName: any(named: 'fileName'),
        )).thenAnswer((_) async => true);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        ChangeNotifierProvider<LectureNotesProvider>.value(
            value: mockNotesProvider),
      ],
      child: MaterialApp(
        navigatorKey: GlobalErrorHandler.instance.navigatorKey,
        home: const LectureNotesScreen(),
      ),
    );
  }

  testWidgets('Unauthenticated user sees login prompt',
      (WidgetTester tester) async {
    when(() => mockAuthProvider.user).thenReturn(null);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Please log in'), findsOneWidget);
  });

  testWidgets('My Notes tab shows stream error state',
      (WidgetTester tester) async {
    when(() => mockNotesProvider.getLectureNotesStream(any()))
        .thenAnswer((_) => Stream<List<LectureNote>>.error('stream failure'));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('My Notes'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Error: stream failure'), findsOneWidget);
  });

  testWidgets('Delete note confirms and shows success snackbar',
      (WidgetTester tester) async {
    final note = LectureNote(
      id: 'n1',
      dentistUid: 'dentist_1',
      title: 'Ortho Basics',
      description: 'Chapter 1 notes',
      type: NoteType.pdf,
      fileName: 'ortho.pdf',
      fileSizeBytes: 2048,
      createdAt: DateTime(2026, 1, 1),
    );

    when(() => mockNotesProvider.getLectureNotesStream(any()))
        .thenAnswer((_) => Stream.value([note]));
    when(() => mockNotesProvider.deleteLectureNote(
          noteId: 'n1',
          dentistUid: 'dentist_1',
          fileName: 'ortho.pdf',
        )).thenAnswer((_) async => true);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('My Notes'));
    await tester.pumpAndSettle();

    expect(find.text('Ortho Basics'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();

    expect(find.text('Delete Note?'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();

    verify(() => mockNotesProvider.deleteLectureNote(
          noteId: 'n1',
          dentistUid: 'dentist_1',
          fileName: 'ortho.pdf',
        )).called(1);

    expect(find.text('Note deleted successfully.'), findsOneWidget);
  });

  testWidgets('Upload validation - button disabled when file is not selected',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final uploadButton = find.widgetWithText(
      ElevatedButton,
      'Select File & Enter Title',
    );
    expect(uploadButton, findsOneWidget);

    final initialButtonWidget = tester.widget<ElevatedButton>(uploadButton);
    expect(initialButtonWidget.onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'Operative Dentistry');
    await tester.pump();

    final updatedButtonWidget = tester.widget<ElevatedButton>(uploadButton);
    expect(updatedButtonWidget.onPressed, isNull);
  });
}
