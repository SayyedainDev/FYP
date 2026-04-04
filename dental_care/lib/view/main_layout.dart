import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../provider/auth_provider.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'dental_detection_screen.dart';
import 'dentist_profile_screen.dart';
import 'patients_screen.dart';
import 'settings_screen.dart';
import 'ai_quiz_screen.dart';
import 'quiz_list_screen.dart';
import 'lecture_notes_screen.dart';
import 'widgets/main_sidebar.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _getCurrentScreen(String page) {
    switch (page) {
      case 'Overview':
        return const DashboardScreen(key: ValueKey('Overview'));
      case 'Patients':
        return const PatientsScreen(key: ValueKey('Patients'));
      case 'Scan History':
        return const HistoryScreen(key: ValueKey('Scan History'));
      case 'Create Quiz':
        return const AIQuizScreen(key: ValueKey('Create Quiz'));
      case 'My Quizzes':
        return const QuizListScreen(key: ValueKey('My Quizzes'));
      case 'Lecture Notes':
        return const LectureNotesScreen(key: ValueKey('Lecture Notes'));
      case 'Settings':
        return const SettingsScreen(key: ValueKey('Settings'));
      case 'Profile':
        return const DentistProfileScreen(key: ValueKey('Profile'));
      case 'Disease Detection':
        return const DentalDetectionScreen(key: ValueKey('Disease Detection'));
      default:
        return const DashboardScreen(key: ValueKey('Overview'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Consumer<NavigationProvider>(
        builder: (context, navProvider, child) {
          final auth = Provider.of<AuthProvider>(context);
          final isDentist = auth.userRole.toLowerCase() != 'student';
          return Row(
            children: [
              SlideTransition(
                position: _slideAnimation,
                child: const MainSidebar(),
              ),

              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          children: [
                            Text(
                              navProvider.currentPage,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                            ),

                            const Spacer(),
                            if (navProvider.currentPage == 'Overview' &&
                                isDentist)
                              ElevatedButton.icon(
                                onPressed: () =>
                                    navProvider.setPage('Disease Detection'),
                                icon: const Icon(Icons.auto_awesome, size: 18),
                                label: const Text('Quick Detection'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A90E2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),

                        // <-- THIS IS THE FIX FOR "THE GAP"
                        // This tells the AnimatedSwitcher to align
                        // its children (your screens) to the TOP,
                        // not the center.
                        layoutBuilder:
                            (
                              Widget? currentChild,
                              List<Widget> previousChildren,
                            ) {
                              return Stack(
                                alignment:
                                    Alignment.topCenter, // Aligns to the top
                                children: [
                                  ...previousChildren,
                                  if (currentChild != null) currentChild,
                                ],
                              );
                            },
                        child: _getCurrentScreen(navProvider.currentPage),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
