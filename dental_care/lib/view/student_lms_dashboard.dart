import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dental_care/provider/auth_provider.dart';
import 'package:dental_care/providers/performance_provider.dart';
import 'package:dental_care/providers/assignment_provider.dart';
import 'package:dental_care/providers/quiz_provider.dart';
import 'student_lecture_notes_screen.dart';
import 'student_quiz_available_screen.dart';
import 'student_assignments_screen.dart';
import 'student_performance_analytics.dart';
import 'student_profile_lms_screen.dart';
import 'student_results_screen.dart';

class StudentLMSDashboard extends StatefulWidget {
  const StudentLMSDashboard({Key? key}) : super(key: key);

  @override
  State<StudentLMSDashboard> createState() => _StudentLMSDashboardState();
}

class _StudentLMSDashboardState extends State<StudentLMSDashboard>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final studentName = authProvider.user?.displayName ?? 'Student';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Premium Header with Profile
          SliverAppBar(
            expandedHeight: 240,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade600,
                      Colors.blue.shade800,
                      Colors.indigo.shade900,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  studentName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const StudentProfileLMSScreen(),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Performance Overview
                        Consumer<PerformanceProvider>(
                          builder: (context, performanceProvider, _) {
                            final performance = performanceProvider.performance;
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Overall Performance',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${performance?.overallPerformanceScore.toStringAsFixed(1) ?? '0'}%',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getPerformanceColor(
                                        performance?.performanceStatus ?? '',
                                      ).withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _getPerformanceColor(
                                          performance?.performanceStatus ?? '',
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      performance?.performanceStatus ?? 'N/A',
                                      style: TextStyle(
                                        color: _getPerformanceColor(
                                          performance?.performanceStatus ?? '',
                                        ),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => _showLogoutDialog(context),
              ),
            ],
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Stats Grid
                  _buildStatsGrid(),
                  const SizedBox(height: 28),

                  // Quick Access Sections
                  _buildSectionsHeader('Quick Access'),
                  const SizedBox(height: 12),
                  _buildQuickAccessCards(context),
                  const SizedBox(height: 28),

                  // Recent Quizzes Section
                  _buildSectionTitle('Recent Quizzes', context),
                  const SizedBox(height: 12),
                  _buildRecentQuizzesSection(),
                  const SizedBox(height: 28),

                  // Pending Assignments Section
                  _buildSectionTitle('Pending Assignments', context),
                  const SizedBox(height: 12),
                  _buildPendingAssignmentsSection(),
                  const SizedBox(height: 28),

                  // Lecture Materials Section
                  _buildSectionTitle('Latest Lecture Materials', context),
                  const SizedBox(height: 12),
                  _buildLectureSection(),
                  const SizedBox(height: 28),

                  // Performance Highlights
                  _buildPerformanceSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildStatsGrid() {
    return Consumer2<PerformanceProvider, AssignmentProvider>(
      builder: (context, performanceProvider, assignmentProvider, _) {
        final performance = performanceProvider.performance;
        final pendingAssignments =
            assignmentProvider.assignments.where((a) => !a.isOverdue).length;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildStatCard(
              title: 'Quizzes',
              value: '${performance?.totalQuizzesTaken ?? 0}',
              subtitle: 'Completed',
              icon: Icons.quiz,
              color: Colors.blue,
            ),
            _buildStatCard(
              title: 'Avg Score',
              value:
                  '${performance?.averageQuizScore.toStringAsFixed(0) ?? '0'}%',
              subtitle: 'Quiz Score',
              icon: Icons.trending_up,
              color: Colors.green,
            ),
            _buildStatCard(
              title: 'Assignments',
              value: '${performance?.assignmentsSubmitted ?? 0}',
              subtitle: 'Submitted',
              icon: Icons.assignment,
              color: Colors.orange,
            ),
            _buildStatCard(
              title: 'Pending',
              value: '$pendingAssignments',
              subtitle: 'Tasks',
              icon: Icons.pending_actions,
              color: Colors.red,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
          ),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionsHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessCards(BuildContext context) {
    final cards = [
      {
        'title': 'Quiz',
        'icon': Icons.quiz,
        'color': Colors.blue,
        'screen': const StudentQuizAvailableScreen(),
      },
      {
        'title': 'Assignments',
        'icon': Icons.assignment,
        'color': Colors.orange,
        'screen': const StudentAssignmentsScreen(),
      },
      {
        'title': 'Notes',
        'icon': Icons.library_books,
        'color': Colors.purple,
        'screen': const StudentLectureNotesScreen(),
      },
      {
        'title': 'Results',
        'icon': Icons.bar_chart,
        'color': Colors.green,
        'screen': const StudentResultsScreen(),
      },
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: cards.map((card) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => card['screen'] as Widget,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (card['color'] as Color).withOpacity(0.3),
                  (card['color'] as Color).withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: (card['color'] as Color).withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  card['icon'] as IconData,
                  color: card['color'] as Color,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  card['title'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: card['color'] as Color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () {
            if (title.contains('Quiz')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentQuizAvailableScreen(),
                ),
              );
            } else if (title.contains('Assignment')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentAssignmentsScreen(),
                ),
              );
            } else if (title.contains('Lecture')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentLectureNotesScreen(),
                ),
              );
            }
          },
          child: Text(
            'View All',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentQuizzesSection() {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, _) {
        final quizzes = quizProvider.quizzes.take(3).toList();

        if (quizzes.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                'No quizzes available yet',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        }

        return Column(
          children: quizzes.map((quiz) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.blue.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${quiz.totalMarks} marks',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Start',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPendingAssignmentsSection() {
    return Consumer<AssignmentProvider>(
      builder: (context, assignmentProvider, _) {
        final pending =
            assignmentProvider.assignments.where((a) => !a.isOverdue).take(3);

        if (pending.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                'No pending assignments',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        }

        return Column(
          children: pending.map((assignment) {
            final daysLeft =
                assignment.dueDate.difference(DateTime.now()).inDays;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.orange.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          assignment.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: daysLeft <= 3
                              ? Colors.red.shade200
                              : Colors.orange.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$daysLeft days left',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: daysLeft <= 3
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    assignment.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLectureSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.shade600,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.library_books,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Latest Learning Materials',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Access course lecture notes and study materials',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentLectureNotesScreen(),
                ),
              );
            },
            child: Icon(
              Icons.arrow_forward,
              color: Colors.purple.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Consumer<PerformanceProvider>(
      builder: (context, performanceProvider, _) {
        final performance = performanceProvider.performance;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade400,
                Colors.green.shade600,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Performance Highlights',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudentPerformanceAnalytics(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPerformanceHighlight(
                    'Overall Score',
                    '${performance?.overallPerformanceScore.toStringAsFixed(1) ?? '0'}%',
                  ),
                  _buildPerformanceHighlight(
                    'Activity',
                    '${performance?.totalQuizzesTaken ?? 0} quizzes',
                  ),
                  _buildPerformanceHighlight(
                    'Submissions',
                    '${performance?.assignmentsSubmitted ?? 0} tasks',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceHighlight(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);

          final screens = [
            const StudentLMSDashboard(),
            const StudentQuizAvailableScreen(),
            const StudentAssignmentsScreen(),
            const StudentResultsScreen(),
            const StudentProfileLMSScreen(),
          ];

          if (index != 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => screens[index]),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Quizzes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Assignments',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Results',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Color _getPerformanceColor(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'average':
        return Colors.orange;
      case 'needsimprovement':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
