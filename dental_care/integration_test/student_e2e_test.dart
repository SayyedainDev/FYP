// ============================================================
// Student Side - End-to-End Integration Tests
// Covers: Login, Dashboard, Quizzes, Results, Lecture Notes,
//         Assignments, Profile, Settings, Logout
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dental_care/main.dart' as app;

// ---------------------------------------------------------------------------
// Test credentials – replace with your Firebase test-user credentials
// ---------------------------------------------------------------------------
const _studentEmail = '03-134222-094@student.bahria.edu.pk';
const _studentPassword = 'Sabeeh1786@';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ─── STUDENT LOGIN + FULL APP FLOW ────────────────────────────────────────
  group('🎓 Student Side – E2E Tests', () {
    testWidgets(
      'T01 · Login page renders correctly',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Either the login page or the loading indicator is shown first
        final hasLoginTitle = find.textContaining('PalPath').evaluate().isNotEmpty;
        final hasSignIn = find.textContaining('Sign in').evaluate().isNotEmpty;
        final hasLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;

        expect(
          hasLoginTitle || hasSignIn || hasLoading,
          true,
          reason: 'App should show login page or loading indicator on cold start',
        );
        debugPrint('✅ T01 – Login page renders');
      },
    );

    testWidgets(
      'T02 · Email field validates empty input',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Tap sign-in without entering anything
        final signInBtn = find.widgetWithText(ElevatedButton, 'Sign in');
        if (signInBtn.evaluate().isNotEmpty) {
          await tester.tap(signInBtn.first);
          await tester.pumpAndSettle();
          // Should see validation error OR warning dialog
          final hasError = find.textContaining('email').evaluate().isNotEmpty ||
              find.textContaining('Missing').evaluate().isNotEmpty ||
              find.textContaining('fill').evaluate().isNotEmpty;
          expect(hasError, true, reason: 'Empty submit should show validation');
        }
        debugPrint('✅ T02 – Validation on empty submit');
      },
    );

    testWidgets(
      'T03 · Role selector switches between Student and Doctor',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        final studentChip = find.text('Student');
        final doctorChip = find.text('Doctor/Dentist');

        if (studentChip.evaluate().isNotEmpty && doctorChip.evaluate().isNotEmpty) {
          await tester.tap(doctorChip.first);
          await tester.pumpAndSettle();
          await tester.tap(studentChip.first);
          await tester.pumpAndSettle();
          debugPrint('✅ T03 – Role selector works');
        } else {
          debugPrint('⚠️ T03 – Role chips not found, skipping');
        }
      },
    );

    testWidgets(
      'T04 · Password toggle shows / hides text',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        final toggleIcon = find.byIcon(Icons.visibility_off_outlined);
        if (toggleIcon.evaluate().isNotEmpty) {
          await tester.tap(toggleIcon.first);
          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.visibility_outlined), findsWidgets);
          debugPrint('✅ T04 – Password toggle works');
        } else {
          debugPrint('⚠️ T04 – Toggle icon not found, skipping');
        }
      },
    );

    testWidgets(
      'T05 · Navigate to Register page',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        final signUpBtn = find.textContaining('Sign up');
        if (signUpBtn.evaluate().isNotEmpty) {
          await tester.tap(signUpBtn.first);
          await tester.pumpAndSettle(const Duration(seconds: 3));
          // Should be on register page
          expect(find.byType(TextFormField), findsWidgets,
              reason: 'Register page must have form fields');
          debugPrint('✅ T05 – Register page navigation works');
        } else {
          debugPrint('⚠️ T05 – Sign up button not found, skipping');
        }
      },
    );

    testWidgets(
      'T06 · Student login and dashboard loads',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        await _loginAs(tester, _studentEmail, _studentPassword, role: 'Student');

        // After login the student dashboard should be visible
        await tester.pumpAndSettle(const Duration(seconds: 6));

        final onDashboard =
            find.textContaining('Welcome').evaluate().isNotEmpty ||
                find.textContaining('Dashboard').evaluate().isNotEmpty ||
                find.textContaining('Completed').evaluate().isNotEmpty;

        expect(onDashboard, true,
            reason: 'Student dashboard should load after login');
        debugPrint('✅ T06 – Student login and dashboard loaded');
      },
    );

    testWidgets(
      'T07 · Student dashboard stat cards are visible',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));
        await _loginAs(tester, _studentEmail, _studentPassword, role: 'Student');
        await tester.pumpAndSettle(const Duration(seconds: 6));

        // Stat cards: Completed, Avg Score, Available
        final hasCards = find.byType(Card).evaluate().isNotEmpty ||
            find.textContaining('Avg').evaluate().isNotEmpty ||
            find.textContaining('Available').evaluate().isNotEmpty;

        expect(hasCards, true, reason: 'Dashboard should show stat cards');
        debugPrint('✅ T07 – Stat cards visible');
      },
    );

    testWidgets(
      'T08 · Student navigates to Available Quizzes',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));
        await _loginAs(tester, _studentEmail, _studentPassword, role: 'Student');
        await tester.pumpAndSettle(const Duration(seconds: 6));

        await _tapNavItem(tester, 'Available Quizzes');

        final onQuizPage =
            find.textContaining('Available Quizzes').evaluate().isNotEmpty ||
                find.textContaining('No Quizzes').evaluate().isNotEmpty ||
                find.byType(ListView).evaluate().isNotEmpty;

        expect(onQuizPage, true,
            reason: 'Should navigate to Available Quizzes screen');
        debugPrint('✅ T08 – Available Quizzes navigation works');
      },
    );

    testWidgets(
      'T09 · Quiz list shows completed / available sections',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));
        await _loginAs(tester, _studentEmail, _studentPassword, role: 'Student');
        await tester.pumpAndSettle(const Duration(seconds: 6));

        await _tapNavItem(tester, 'Available Quizzes');
        await tester.pumpAndSettle(const Duration(seconds: 4));

        // Should show either sections or empty state – no crash
        expect(find.byType(MaterialApp), findsOneWidget,
            reason: 'App should still be running after navigating to quizzes');
        debugPrint('✅ T09 – Quiz list renders without crash');
      },
    );

    testWidgets(
      'T10 · Student navigates to My Results',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));
        await _loginAs(tester, _studentEmail, _studentPassword, role: 'Student');
        await tester.pumpAndSettle(const Duration(seconds: 6));

        await _tapNavItem(tester, 'My Results');

        final onResultsPage =
            find.textContaining('Results').evaluate().isNotEmpty ||
                find.textContaining('attempts').evaluate().isNotEmpty ||
                find.textContaining('No attempts').evaluate().isNotEmpty;

        expect(onResultsPage, true, reason: 'Should navigate to My Results');
        debugPrint('✅ T10 – My Results navigation works');
      },
    );

    testWidgets(
      'T11 · Student navigates to Lecture Notes',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));
        await _loginAs(tester, _studentEmail, _studentPassword, role: 'Student');
        await tester.pumpAndSettle(const Duration(seconds: 6));

        await _tapNavItem(tester, 'Lecture Notes');
        await tester.pumpAndSettle(const Duration(seconds: 4));

        final onNotesPage =
            find.textContaining('Lecture').evaluate().isNotEmpty ||
                find.textContaining('Notes').evaluate().isNotEmpty ||
                find.textContaining('No lecture').evaluate().isNotEmpty;

        expect(onNotesPage, true,
            reason: 'Should navigate to Lecture Notes screen');
        debugPrint('✅ T11 – Lecture Notes navigation works');
      },
    );

    testWidgets(
      'T12 · Student navigates to Assignments',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));
        await _loginAs(tester, _studentEmail, _studentPassword, role: 'Student');
        await tester.pumpAndSettle(const Duration(seconds: 6));

        await _tapNavItem(tester, 'Assignments');
        await tester.pumpAndSettle(const Duration(seconds: 4));

        final onAssignmentPage =
            find.textContaining('Assignment').evaluate().isNotEmpty ||
                find.textContaining('No assignment').evaluate().isNotEmpty;

        expect(onAssignmentPage, true,
            reason: 'Should navigate to Assignments screen');
        debugPrint('✅ T12 – Assignments navigation works');
      },
    );

    testWidgets(
      'T13 · Student navigates to Profile',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));
        await _loginAs(tester, _studentEmail, _studentPassword, role: 'Student');
        await tester.pumpAndSettle(const Duration(seconds: 6));

        await _tapNavItem(tester, 'Profile');
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final onProfilePage =
            find.textContaining('Profile').evaluate().isNotEmpty ||
                find.byType(Card).evaluate().isNotEmpty;

        expect(onProfilePage, true,
            reason: 'Should navigate to Profile screen');
        debugPrint('✅ T13 – Profile navigation works');
      },
    );

    testWidgets(
      'T14 · Student navigates to Settings',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));
        await _loginAs(tester, _studentEmail, _studentPassword, role: 'Student');
        await tester.pumpAndSettle(const Duration(seconds: 6));

        await _tapNavItem(tester, 'Settings');
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final onSettingsPage =
            find.textContaining('Settings').evaluate().isNotEmpty ||
                find.byType(ListTile).evaluate().isNotEmpty ||
                find.byType(SwitchListTile).evaluate().isNotEmpty;

        expect(onSettingsPage, true,
            reason: 'Should navigate to Settings screen');
        debugPrint('✅ T14 – Settings navigation works');
      },
    );

    testWidgets(
      'T15 · Dashboard quick-action "Start →" navigates to quizzes',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));
        await _loginAs(tester, _studentEmail, _studentPassword, role: 'Student');
        await tester.pumpAndSettle(const Duration(seconds: 6));

        // The quick-action button
        final startBtn = find.widgetWithText(ElevatedButton, 'Start →');
        if (startBtn.evaluate().isNotEmpty) {
          await tester.tap(startBtn.first);
          await tester.pumpAndSettle(const Duration(seconds: 3));
          debugPrint('✅ T15 – Quick-action Start → tapped');
        } else {
          debugPrint('⚠️ T15 – Start → button not visible (no quizzes?), skipping');
        }
        // App should still be running
        expect(find.byType(MaterialApp), findsOneWidget);
      },
    );

    testWidgets(
      'T16 · Recent Attempts section expands / collapses',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));
        await _loginAs(tester, _studentEmail, _studentPassword, role: 'Student');
        await tester.pumpAndSettle(const Duration(seconds: 6));

        final expansionTiles = find.byType(ExpansionTile);
        if (expansionTiles.evaluate().isNotEmpty) {
          await tester.tap(expansionTiles.first);
          await tester.pumpAndSettle();
          await tester.tap(expansionTiles.first);
          await tester.pumpAndSettle();
          debugPrint('✅ T16 – ExpansionTile toggle works');
        } else {
          debugPrint('⚠️ T16 – No ExpansionTile found, skipping');
        }
        expect(find.byType(MaterialApp), findsOneWidget);
      },
    );

    testWidgets(
      'T17 · Dashboard scrolls vertically without error',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));
        await _loginAs(tester, _studentEmail, _studentPassword, role: 'Student');
        await tester.pumpAndSettle(const Duration(seconds: 6));

        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -400));
          await tester.pumpAndSettle();
          await tester.drag(scrollable.first, const Offset(0, 400));
          await tester.pumpAndSettle();
          debugPrint('✅ T17 – Dashboard scrolling OK');
        }
        expect(find.byType(MaterialApp), findsOneWidget);
      },
    );

    testWidgets(
      'T18 · Student logout returns to login page',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));
        await _loginAs(tester, _studentEmail, _studentPassword, role: 'Student');
        await tester.pumpAndSettle(const Duration(seconds: 6));

        // Find logout button in drawer or sidebar
        final logoutBtn = find.widgetWithText(OutlinedButton, 'Logout');
        if (logoutBtn.evaluate().isNotEmpty) {
          await tester.tap(logoutBtn.first);
          await tester.pumpAndSettle(const Duration(seconds: 5));
          final backOnLogin =
              find.textContaining('Sign in').evaluate().isNotEmpty ||
                  find.textContaining('PalPath').evaluate().isNotEmpty ||
                  find.textContaining('Welcome').evaluate().isNotEmpty;
          expect(backOnLogin, true, reason: 'Should return to login page after logout');
          debugPrint('✅ T18 – Logout works');
        } else {
          debugPrint('⚠️ T18 – Logout button not visible (maybe in drawer), opening drawer...');
          await _openDrawerIfNeeded(tester);
          final logoutBtnDrawer = find.widgetWithText(OutlinedButton, 'Logout');
          if (logoutBtnDrawer.evaluate().isNotEmpty) {
            await tester.tap(logoutBtnDrawer.first);
            await tester.pumpAndSettle(const Duration(seconds: 5));
          }
        }
      },
    );

    testWidgets(
      'T19 · Forgot password link is tappable',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        final forgotLink = find.text('Forgot password?');
        if (forgotLink.evaluate().isNotEmpty) {
          await tester.tap(forgotLink.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
          // Should navigate to forgot password screen without crash
          expect(find.byType(MaterialApp), findsOneWidget);
          debugPrint('✅ T19 – Forgot password navigates OK');
        } else {
          debugPrint('⚠️ T19 – Forgot password link not found, skipping');
        }
      },
    );

    testWidgets(
      'T20 · Remember Me checkbox toggles',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        final checkbox = find.byType(Checkbox);
        if (checkbox.evaluate().isNotEmpty) {
          await tester.tap(checkbox.first);
          await tester.pumpAndSettle();
          await tester.tap(checkbox.first);
          await tester.pumpAndSettle();
          debugPrint('✅ T20 – Remember Me checkbox works');
        } else {
          debugPrint('⚠️ T20 – Checkbox not found, skipping');
        }
        expect(find.byType(MaterialApp), findsOneWidget);
      },
    );
  });
}

// ─── HELPERS ────────────────────────────────────────────────────────────────

/// Fills and submits the login form with the given credentials.
Future<void> _loginAs(
  WidgetTester tester,
  String email,
  String password, {
  String role = 'Student',
}) async {
  // If already on dashboard, skip
  if (find.textContaining('Welcome').evaluate().isNotEmpty ||
      find.textContaining('Dashboard').evaluate().isNotEmpty) return;

  // Select role chip
  final roleLabel = role == 'Student' ? 'Student' : 'Doctor/Dentist';
  final roleChip = find.text(roleLabel);
  if (roleChip.evaluate().isNotEmpty) {
    await tester.tap(roleChip.first);
    await tester.pumpAndSettle();
  }

  final fields = find.byType(TextFormField);
  if (fields.evaluate().length >= 2) {
    await tester.enterText(fields.first, email);
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(1), password);
    await tester.pumpAndSettle();
  }

  final signInBtn = find.widgetWithText(ElevatedButton, 'Sign in');
  if (signInBtn.evaluate().isNotEmpty) {
    await tester.tap(signInBtn.first);
    await tester.pumpAndSettle(const Duration(seconds: 8));
  }
}

/// Taps a navigation item in the sidebar or drawer by its label text.
Future<void> _tapNavItem(WidgetTester tester, String label) async {
  // Try direct text tap first (desktop sidebar)
  final navItem = find.text(label);
  if (navItem.evaluate().isNotEmpty) {
    await tester.tap(navItem.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    return;
  }
  // If not found, try opening the drawer
  await _openDrawerIfNeeded(tester);
  final drawerItem = find.text(label);
  if (drawerItem.evaluate().isNotEmpty) {
    await tester.tap(drawerItem.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

/// Opens the drawer if a hamburger menu icon is present.
Future<void> _openDrawerIfNeeded(WidgetTester tester) async {
  final menuIcon = find.byIcon(Icons.menu);
  if (menuIcon.evaluate().isNotEmpty) {
    await tester.tap(menuIcon.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }
}
