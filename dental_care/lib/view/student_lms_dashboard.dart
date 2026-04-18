import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dental_care/provider/auth_provider.dart';
import 'package:dental_care/providers/quiz_attempt_provider.dart';
import 'package:dental_care/providers/assignment_provider.dart';
import 'package:dental_care/providers/quiz_provider.dart';
// import removed: navigation provider not used
import 'package:dental_care/core/theme/app_tokens.dart';
import 'package:dental_care/core/responsive/app_breakpoints.dart';
import 'student_quiz_available_screen.dart';
import 'student_lecture_notes_screen.dart';
import 'student_assignments_screen.dart';
import 'student_results_screen.dart';
import 'student_profile_screen.dart';
import 'settings_screen.dart';

class StudentLMSDashboard extends StatefulWidget {
  const StudentLMSDashboard({Key? key}) : super(key: key);

  @override
  State<StudentLMSDashboard> createState() => _StudentLMSDashboardState();
}

class _StudentLMSDashboardState extends State<StudentLMSDashboard> {
  late String currentPage = 'Dashboard';
  final List<String> _pageHistory = [];

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
    final assignProv = context.read<AssignmentProvider>();
    final attemptProv = context.read<QuizAttemptProvider>();

    await quizProv.fetchPublishedQuizzes();
    await assignProv.fetchStudentAssignments(uid);
    await attemptProv.fetchStudentAttempts(uid);
  }

  Widget _getContent() {
    switch (currentPage) {
      case 'Dashboard':
        return _buildDashboardContent();
      case 'Available Quizzes':
        return const StudentQuizAvailableScreen(quizId: '');
      case 'My Results':
        return const StudentResultsScreen();
      case 'Lecture Notes':
        return const StudentLectureNotesScreen();
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
          leading: Row(
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
          backgroundColor: AppColors.brandPrimary,
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
        leading: Row(
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
        backgroundColor: AppColors.brandPrimary,
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
                    backgroundColor: AppColors.brandPrimary,
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
                    backgroundColor: AppColors.brandPrimary,
                    child: Text(
                      studentName[0].toUpperCase(),
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
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Student',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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
                    side: BorderSide(color: AppColors.danger),
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
                  ? AppColors.brandPrimary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(color: AppColors.brandPrimary, width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? AppColors.brandPrimary : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? AppColors.brandPrimary : Colors.grey[700],
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
    final assignmentProvider = context.watch<AssignmentProvider>();
    final attemptProvider = context.watch<QuizAttemptProvider>();

    final studentName = auth.user?.displayName ?? 'Student';
    final attempts =
        attemptProvider.studentAttempts.where((a) => a.isSubmitted).toList();
    final quizzes = quizProvider.publishedQuizzes;
    final assignments = assignmentProvider.assignments;

    // Calculate stats from actual quiz attempts
    double avgScore = 0;
    if (attempts.isNotEmpty) {
      avgScore =
          attempts.map((a) => a.scorePercentage).reduce((a, b) => a + b) /
              attempts.length;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $studentName! 👋',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track your progress and ace your courses',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stats Cards - Smaller size
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 1000 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard(
                title: 'Quizzes Completed',
                value: attempts.length.toString(),
                icon: Icons.quiz,
                color: Colors.blue,
                softColor: const Color(0xFFCBE0FF),
              ),
              _buildStatCard(
                title: 'Average Score',
                value: '${avgScore.toStringAsFixed(1)}%',
                icon: Icons.trending_up,
                color: Colors.green,
                softColor: const Color(0xFFD7F1DE),
              ),
              _buildStatCard(
                title: 'Assignments',
                value: assignments.length.toString(),
                icon: Icons.assignment,
                color: Colors.orange,
                softColor: const Color(0xFFF9E6CC),
              ),
              _buildStatCard(
                title: 'Available Quizzes',
                value: quizzes.length.toString(),
                icon: Icons.library_books,
                color: Colors.purple,
                softColor: const Color(0xFFEADCF7),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recent Quizzes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Quiz Attempts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () => setState(() => currentPage = 'My Results'),
                child: const Text('View All →'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (attempts.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.quiz_outlined,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No quiz attempts yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start by taking an available quiz',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: attempts.take(5).map((attempt) {
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _getScoreColor(attempt.scorePercentage)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${attempt.scorePercentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 18,
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
                                'Quiz Attempt',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${attempt.responses.length}/${attempt.totalMarks} Questions',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Completed: ${attempt.startTime.toString().split(' ')[0]}',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _getScoreIcon(attempt.scorePercentage),
                          color: _getScoreColor(attempt.scorePercentage),
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 32),

          // Available Quizzes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Quizzes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () =>
                    setState(() => currentPage = 'Available Quizzes'),
                child: const Text('View All →'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (quizzes.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.library_books_outlined,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No quizzes available yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: quizzes.take(3).map((quiz) {
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.quiz_outlined,
                              color: AppColors.brandPrimary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                quiz.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                quiz.description,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    StudentQuizAvailableScreen(quizId: quiz.id),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          child: const Text('(Start)',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
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
