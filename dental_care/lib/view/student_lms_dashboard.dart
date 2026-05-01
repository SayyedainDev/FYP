import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dental_care/provider/auth_provider.dart';
import 'package:dental_care/providers/quiz_attempt_provider.dart';
import 'package:dental_care/providers/quiz_provider.dart';
// import removed: navigation provider not used
import 'package:dental_care/core/theme/app_tokens.dart';
import 'package:dental_care/core/responsive/app_breakpoints.dart';
import 'package:dental_care/view/student_quiz_available_screen.dart';
import 'package:dental_care/features/lecture_notes/screens/student/student_lecture_notes_screen.dart';
import 'student_assignments_screen.dart';
import 'student_results_screen.dart';
import 'student_profile_screen.dart';
import 'settings_screen.dart';

class StudentLMSDashboard extends StatefulWidget {
  const StudentLMSDashboard({super.key});

  @override
  State<StudentLMSDashboard> createState() => _StudentLMSDashboardState();
}

class _StudentLMSDashboardState extends State<StudentLMSDashboard> {
  late String currentPage = 'Dashboard';
  final List<String> _pageHistory = [];

  ColorScheme get _studentColors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    if (uid == null) return;

    final quizProv = context.read<QuizProvider>();
    final attemptProv = context.read<QuizAttemptProvider>();

    await quizProv.fetchPublishedQuizzes();
    await attemptProv.fetchStudentAttempts(uid);
  }

  Widget _getContent() {
    switch (currentPage) {
      case 'Dashboard':
        return _buildDashboardContent();
      case 'Available Quizzes':
        return const StudentQuizAvailableScreenV2();
      case 'My Results':
        return const StudentResultsScreen();
      case 'Lecture Notes':
        return const StudentLectureNotesScreen(moduleId: 'general');
      case 'Assignments':
        return const StudentAssignmentsScreen();
      case 'Settings':
        return const SettingsScreen();
      case 'Profile':
        return const StudentProfileScreen();
      default:
        return _buildDashboardContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final isDesktop = AppBreakpoints.isDesktop(context);
    final auth = context.watch<AuthProvider>();

    if (isMobile) {
      // Mobile: Bottom navigation + drawer
      return Scaffold(
        appBar: AppBar(
          leading: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sidebar / menu button (three lines)
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                // Back button: show on all screens except Dashboard
                if (currentPage != 'Dashboard' && _pageHistory.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _goBack,
                  ),
              ],
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  currentPage,
                  style: const TextStyle(overflow: TextOverflow.ellipsis),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: _studentColors.primary,
          elevation: 0,
        ),
        drawer: _buildMobileDrawer(),
        body: _getContent(),
      );
    }

    if (isDesktop) {
      // Desktop: Sidebar + content
      return Scaffold(
        body: Row(
          children: [
            // Sidebar
            _buildDesktopSidebar(auth),
            // Content
            Expanded(
              child: _getContent(),
            ),
          ],
        ),
      );
    }

    // Tablet: Drawer + content
    return Scaffold(
      appBar: AppBar(
        leading: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              if (currentPage != 'Dashboard' && _pageHistory.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _goBack,
                ),
            ],
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                currentPage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(),
              ),
            ),
          ],
        ),
        backgroundColor: _studentColors.primary,
      ),
      drawer: _buildMobileDrawer(),
      body: _getContent(),
    );
  }

  Widget _buildMobileDrawer() {
    final auth = context.read<AuthProvider>();
    final studentName = auth.user?.displayName ?? 'Student';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _studentColors.primary,
                    child: Text(
                      studentName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Student',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Navigation Items
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildNavItem('Dashboard', Icons.dashboard_outlined),
                    _buildNavItem('Available Quizzes', Icons.quiz_outlined),
                    _buildNavItem(
                        'My Results', Icons.assignment_turned_in_outlined),
                    _buildNavItem(
                        'Lecture Notes', Icons.library_books_outlined),
                    _buildNavItem('Assignments', Icons.assignment_outlined),
                    const Divider(height: 24),
                    _buildNavItem('Settings', Icons.settings_outlined),
                    _buildNavItem('Profile', Icons.person_outline),
                  ],
                ),
              ),
            ),

            // Logout
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await auth.logout();
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/', (route) => false);
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar(AuthProvider auth) {
    final studentName = auth.user?.displayName ?? 'Student';
    final isMobile = AppBreakpoints.isMobile(context);

    if (isMobile) return const SizedBox.shrink();

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _studentColors.primary,
                    child: Text(
                      studentName.isNotEmpty
                          ? studentName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    studentName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Navigation Items
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    _buildNavItem('Dashboard', Icons.dashboard_outlined),
                    _buildNavItem('Available Quizzes', Icons.quiz_outlined),
                    _buildNavItem(
                        'My Results', Icons.assignment_turned_in_outlined),
                    _buildNavItem(
                        'Lecture Notes', Icons.library_books_outlined),
                    _buildNavItem('Assignments', Icons.assignment_outlined),
                    const SizedBox(height: 24),
                    _buildNavItem('Settings', Icons.settings_outlined),
                    _buildNavItem('Profile', Icons.person_outline),
                  ],
                ),
              ),
            ),

            // Logout
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await auth.logout();
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/', (route) => false);
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String label, IconData icon) {
    final isActive = currentPage == label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _navigateTo(label);
            Navigator.maybePop(context); // Close drawer on mobile
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? _studentColors.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(color: _studentColors.primary, width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? _studentColors.primary : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? _studentColors.primary : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    final auth = context.watch<AuthProvider>();
    final quizProvider = context.watch<QuizProvider>();
    final attemptProvider = context.watch<QuizAttemptProvider>();

    // For students, show userName without "Dr." prefix
    final studentName = auth.userName ??
        auth.user?.displayName?.replaceAll('Dr. ', '') ??
        'Student';
    final attempts =
        attemptProvider.studentAttempts.where((a) => a.isSubmitted).toList();
    final quizzes = quizProvider.publishedQuizzes;

    // Calculate stats from actual quiz attempts
    double avgScore = 0;
    if (attempts.isNotEmpty) {
      avgScore =
          attempts.map((a) => a.scorePercentage).reduce((a, b) => a + b) /
              attempts.length;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _studentColors.primary.withOpacity(0.9),
                  _studentColors.primary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _studentColors.primary.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, $studentName!',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track your progress and ace your courses today.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.school, color: Colors.white, size: 40),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Key Stats Cards
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 1000
                ? 3
                : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.2,
            children: [
              _buildStatCard(
                title: 'Completed Quizzes',
                value: attempts.length.toString(),
                icon: Icons.check_circle_outline,
                color: Colors.blue.shade700,
                softColor: Colors.blue.shade50,
              ),
              _buildStatCard(
                title: 'Average Score',
                value: '${avgScore.toStringAsFixed(0)}%',
                icon: Icons.trending_up,
                color: Colors.green.shade700,
                softColor: Colors.green.shade50,
              ),
              _buildStatCard(
                title: 'Available Quizzes',
                value: quizzes.length.toString(),
                icon: Icons.play_circle_outline,
                color: Colors.purple.shade700,
                softColor: Colors.purple.shade50,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Split Content: Recent Attempts & Available Quizzes
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildRecentAttemptsSection(attempts),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: _buildAvailableQuizzesSection(quizzes),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildRecentAttemptsSection(attempts),
                    const SizedBox(height: 24),
                    _buildAvailableQuizzesSection(quizzes),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAttemptsSection(List attempts) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Attempts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => currentPage = 'My Results'),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          if (attempts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.quiz_outlined,
                        size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'No attempts yet. Take a quiz to get started!',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attempts.length > 3 ? 3 : attempts.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final attempt = attempts[index];
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getScoreColor(attempt.scorePercentage)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${attempt.scorePercentage.toInt()}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(attempt.scorePercentage),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${attempt.responses.length} of ${attempt.totalMarks} Qs',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              attempt.startTime.toString().split(' ')[0],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _getScoreIcon(attempt.scorePercentage),
                        color: _getScoreColor(attempt.scorePercentage),
                        size: 24,
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAvailableQuizzesSection(List quizzes) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Quizzes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => currentPage = 'Available Quizzes'),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          if (quizzes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.library_books_outlined,
                        size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'No quizzes available at the moment',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quizzes.length > 3 ? 3 : quizzes.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _studentColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.quiz,
                            color: _studentColors.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quiz.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${quiz.config.totalQuestions} questions',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            setState(() => currentPage = 'Available Quizzes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _studentColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        child: const Text('Start',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color softColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(double score) {
    if (score >= 80) return Icons.check_circle;
    if (score >= 60) return Icons.help_outline;
    return Icons.cancel_outlined;
  }

  void _navigateTo(String page) {
    if (page == currentPage) return;
    setState(() {
      _pageHistory.add(currentPage);
      currentPage = page;
    });
  }

  void _goBack() {
    if (_pageHistory.isEmpty) return;
    setState(() {
      currentPage = _pageHistory.removeLast();
    });
  }

  // Removed unused placeholder widgets
}
