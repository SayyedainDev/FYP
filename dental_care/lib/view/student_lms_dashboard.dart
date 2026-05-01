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
          const SizedBox(height: 24),

          // Key Stats Cards - Only 3 most important
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 1000 ? 3 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                title: 'Completed',
                value: attempts.length.toString(),
                icon: Icons.check_circle_outline,
                color: Colors.blue,
                softColor: const Color(0xFFCBE0FF),
              ),
              _buildStatCard(
                title: 'Avg Score',
                value: '${avgScore.toStringAsFixed(0)}%',
                icon: Icons.trending_up,
                color: Colors.green,
                softColor: const Color(0xFFD7F1DE),
              ),
              _buildStatCard(
                title: 'Available',
                value: quizzes.length.toString(),
                icon: Icons.play_circle,
                color: Colors.purple,
                softColor: const Color(0xFFEADCF7),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Quick Action Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.brandPrimary.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: AppColors.brandPrimary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    quizzes.isEmpty
                        ? 'Check back later for new quizzes!'
                        : 'Ready to challenge yourself? Start a quiz now!',
                    style: const TextStyle(
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (quizzes.isNotEmpty)
                  ElevatedButton(
                    onPressed: () =>
                        setState(() => currentPage = 'Available Quizzes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Start →',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Expandable Recent Attempts Section
          _buildExpandableSection(
            title: 'Recent Attempts',
            itemCount: attempts.length,
            isEmpty: attempts.isEmpty,
            emptyMessage: 'No attempts yet. Take a quiz to get started!',
            emptyIcon: Icons.quiz_outlined,
            viewAllText: 'View All Attempts',
            onViewAll: () => setState(() => currentPage = 'My Results'),
            builder: (context) {
              return Column(
                children: attempts.take(3).map((attempt) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _getScoreColor(attempt.scorePercentage)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${attempt.scorePercentage.toInt()}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _getScoreColor(attempt.scorePercentage),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${attempt.responses.length} of ${attempt.totalMarks} Qs',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  attempt.startTime.toString().split(' ')[0],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _getScoreIcon(attempt.scorePercentage),
                            color: _getScoreColor(attempt.scorePercentage),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),

          // Expandable Available Quizzes Section
          _buildExpandableSection(
            title: 'Available Quizzes',
            itemCount: quizzes.length,
            isEmpty: quizzes.isEmpty,
            emptyMessage: 'No quizzes available at the moment',
            emptyIcon: Icons.library_books_outlined,
            viewAllText: 'View All Quizzes',
            onViewAll: () => setState(() => currentPage = 'Available Quizzes'),
            builder: (context) {
              return Column(
                children: quizzes.take(2).map((quiz) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.quiz,
                                color: AppColors.brandPrimary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quiz.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${quiz.config.totalQuestions} questions',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const StudentQuizAvailableScreenV2(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandPrimary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            child: const Text('Start',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required int itemCount,
    required bool isEmpty,
    required String emptyMessage,
    required IconData emptyIcon,
    required String viewAllText,
    required VoidCallback onViewAll,
    required Widget Function(BuildContext) builder,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 12),
        title: Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                itemCount.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.expand_more, color: Colors.grey[600]),
        children: [
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(emptyIcon, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    emptyMessage,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                builder(context),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onViewAll,
                  child:
                      Text(viewAllText, style: const TextStyle(fontSize: 12)),
                ),
              ],
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
