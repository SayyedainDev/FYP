import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/animation_constants.dart';
import '../providers/navigation_provider.dart';
import '../provider/auth_provider.dart';

// Phase 2.1 Injection Imports: Instead of globals, we inject here into the shell
import '../providers/patient_provider.dart';
import '../providers/scan_provider.dart';
import '../providers/case_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/quiz_attempt_provider.dart';
import '../providers/lecture_notes_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/treatment_plan_provider.dart';
import '../providers/medical_history_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/audit_log_provider.dart';
import '../providers/performance_provider.dart';
import '../providers/assignment_provider.dart';
import '../providers/prescription_provider.dart';
import '../features/lecture_notes/providers/lecture_note_provider.dart'
    as new_ln_provider;

import '../features/analytics/view/analytics_dashboard_screen.dart';
import 'login.dart';
import 'dashboard_screen.dart';
import 'student_lms_dashboard.dart';
import '../screens/scan_history/scan_history_screen.dart';
import 'dental_detection_screen.dart';
import 'dentist_profile_screen.dart';
import 'patients_screen.dart';
import 'settings_screen.dart';
import 'ai_quiz_screen.dart';
import 'quiz_list_screen.dart';
import 'lecture_notes_screen.dart';
import '../features/lecture_notes/screens/doctor/doctor_lecture_notes_screen.dart';
import 'student_quiz_list_screen.dart';
import 'student_my_results_screen.dart';
import 'student_analytics_screen.dart';
import 'student_notifications_screen.dart';
import 'student_assignments_screen.dart';
import 'widgets/adaptive_nav_shell.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const Set<String> _studentPages = {
    'Available Quizzes',
    'My Results',
    'My Analytics',
    'Assignments',
    'Notifications',
    'Settings',
    'Profile',
  };

  static const Set<String> _doctorPages = {
    'Overview',
    'Disease Detection',
    'Patients',
    'Scan History',
    'Create Quiz',
    'My Quizzes',
    'Lecture Notes',
    'Quiz Results',
    'Settings',
    'Profile',
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.normal,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _getCurrentScreen(String page, bool isStudent) {
    if (isStudent && !_studentPages.contains(page)) {
      return const StudentLMSDashboard(key: ValueKey('Student Dashboard'));
    }
    if (!isStudent && !_doctorPages.contains(page)) {
      return const DashboardScreen(key: ValueKey('Dashboard'));
    }

    switch (page) {
      case 'Notifications':
        return const StudentNotificationsScreen();
      case 'Patients':
        if (isStudent) {
          return const StudentLMSDashboard(key: ValueKey('Student Dashboard'));
        }
        return const PatientsScreen(key: ValueKey('Patients'));
      case 'Scan History':
        if (isStudent) {
          return const StudentLMSDashboard(key: ValueKey('Student Dashboard'));
        }
        return const ScanHistoryScreen(key: ValueKey('Scan History'));
      case 'Create Quiz':
        if (isStudent) {
          return const StudentLMSDashboard(key: ValueKey('Student Dashboard'));
        }
        return const AIQuizScreen(key: ValueKey('Create Quiz'));
      case 'My Quizzes':
        if (isStudent) {
          return const StudentLMSDashboard(key: ValueKey('Student Dashboard'));
        }
        return const QuizListScreen(key: ValueKey('My Quizzes'));
      case 'Lecture Notes':
        if (isStudent) {
          return const StudentLMSDashboard(key: ValueKey('Student Dashboard'));
        }
        return const DoctorLectureNotesScreen(key: ValueKey('Lecture Notes'));
      case 'Quiz Results':
        if (isStudent) {
          return const StudentLMSDashboard(key: ValueKey('Student Dashboard'));
        }
        return const AnalyticsDashboardScreen(key: ValueKey('Quiz Results'));
      case 'Settings':
        return const SettingsScreen(key: ValueKey('Settings'));
      case 'Profile':
        return const DentistProfileScreen(key: ValueKey('Profile'));
      case 'Disease Detection':
        if (isStudent) {
          return const StudentLMSDashboard(key: ValueKey('Student Dashboard'));
        }
        return const DentalDetectionScreen(key: ValueKey('Disease Detection'));
      // Student-specific screens
      case 'Available Quizzes':
        return isStudent
            ? const StudentQuizListScreen(key: ValueKey('Available Quizzes'))
            : const DashboardScreen(key: ValueKey('Overview'));
      case 'My Results':
        return isStudent
            ? const StudentMyResultsScreen(key: ValueKey('My Results'))
            : const DashboardScreen(key: ValueKey('Overview'));
      case 'My Analytics':
        return isStudent
            ? const StudentAnalyticsScreen(key: ValueKey('My Analytics'))
            : const DashboardScreen(key: ValueKey('Overview'));
      case 'Assignments':
        return isStudent
            ? const StudentAssignmentsScreen(key: ValueKey('Assignments'))
            : const DashboardScreen(key: ValueKey('Overview'));
      default:
        return isStudent
            ? const StudentLMSDashboard(key: ValueKey('Student Dashboard'))
            : const DashboardScreen(key: ValueKey('Dashboard'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NavigationProvider, AuthProvider>(
      builder: (context, navProvider, auth, _) {
        // Prevent direct refresh/URL entry from opening a portal without a live session.
        if (auth.user == null) {
          return const LoginPage();
        }

        final isStudent = auth.userRole.toLowerCase() == 'student';

        if (isStudent && !_studentPages.contains(navProvider.currentPage)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<NavigationProvider>().setPage('Overview');
            }
          });
        }
        if (!isStudent && !_doctorPages.contains(navProvider.currentPage)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<NavigationProvider>().setPage('Overview');
            }
          });
        }

        final destinations = <NavDestination>[
          const NavDestination(
              label: 'Overview', icon: Icons.dashboard_outlined),
          if (!isStudent)
            const NavDestination(
              label: 'Disease Detection',
              icon: Icons.auto_awesome,
            ),
          if (!isStudent)
            const NavDestination(label: 'Patients', icon: Icons.people_outline),
          if (!isStudent)
            const NavDestination(
              label: 'Scan History',
              icon: Icons.history_outlined,
            ),
          if (!isStudent)
            const NavDestination(
                label: 'Create Quiz', icon: Icons.quiz_outlined),
          if (!isStudent)
            const NavDestination(
              label: 'My Quizzes',
              icon: Icons.list_alt_outlined,
            ),
          if (!isStudent)
            const NavDestination(
              label: 'Lecture Notes',
              icon: Icons.library_books_outlined,
            ),
          if (!isStudent)
            const NavDestination(
                label: 'Quiz Results', icon: Icons.analytics_outlined),
          if (isStudent)
            const NavDestination(
              label: 'Available Quizzes',
              icon: Icons.quiz_outlined,
            ),
          if (isStudent)
            const NavDestination(
              label: 'My Results',
              icon: Icons.assignment_turned_in_outlined,
            ),
          if (isStudent)
            const NavDestination(
              label: 'My Analytics',
              icon: Icons.analytics_outlined,
            ),
          if (isStudent)
            const NavDestination(
              label: 'Assignments',
              icon: Icons.assignment_outlined,
            ),
          if (isStudent)
            const NavDestination(
              label: 'Notifications',
              icon: Icons.notifications_outlined,
            ),
          const NavDestination(
              label: 'Settings', icon: Icons.settings_outlined),
          const NavDestination(label: 'Profile', icon: Icons.person_outline),
        ];

        return AdaptiveNavShell(
          currentPage: navProvider.currentPage,
          destinations: destinations,
          onSelect: navProvider.setPage,
          title: navProvider.currentPage,
          actions: [
            if (navProvider.currentPage == 'Overview' && !isStudent)
              ElevatedButton.icon(
                onPressed: () => navProvider.setPage('Disease Detection'),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Quick Detection'),
              ),
            const SizedBox(width: 12),
          ],
          child: RepaintBoundary(
            child: MultiProvider(
              // Scoped directly beneath the authenticated layout
              // Therefore destroying heavy overhead at the login/app boot level.
              providers: [
                ChangeNotifierProvider(create: (_) => PatientProvider()),
                ChangeNotifierProvider(create: (_) => ScanProvider()),
                ChangeNotifierProvider(create: (_) => CaseProvider()),
                ChangeNotifierProvider(create: (_) => QuizProvider()),
                ChangeNotifierProvider(create: (_) => QuizAttemptProvider()),
                ChangeNotifierProvider(create: (_) => LectureNotesProvider()),
                ChangeNotifierProvider(create: (_) => AppointmentProvider()),
                ChangeNotifierProvider(create: (_) => TreatmentPlanProvider()),
                ChangeNotifierProvider(create: (_) => MedicalHistoryProvider()),
                ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
                ChangeNotifierProvider(create: (_) => AuditLogProvider()),
                ChangeNotifierProvider(create: (_) => PerformanceProvider()),
                ChangeNotifierProvider(create: (_) => AssignmentProvider()),
                ChangeNotifierProvider(create: (_) => PrescriptionProvider()),
                ChangeNotifierProvider(
                    create: (_) => new_ln_provider.LectureNoteProvider()),
              ],
              child: _getCurrentScreen(navProvider.currentPage, isStudent),
            ),
          ),
        );
      },
    );
  }
}
