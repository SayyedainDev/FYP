import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dental_care/providers/quiz_attempt_provider.dart';
import 'package:dental_care/provider/auth_provider.dart';
import 'package:dental_care/core/theme/app_tokens.dart';
import 'package:dental_care/widgets/student_screen_header.dart';

class StudentResultsScreen extends StatefulWidget {
  const StudentResultsScreen({super.key});

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = 'date';

  ColorScheme get _studentColors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null && uid.isNotEmpty) {
        context.read<QuizAttemptProvider>().fetchStudentAttempts(uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _studentColors.primary.withValues(alpha: 0.08),
              _studentColors.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: StudentScreenHeader(
                  title: 'My Results',
                  subtitle: 'Track your quiz performance and statistics',
                  iconData: Icons.assessment,
                  colorScheme: _studentColors,
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_studentColors.primary, _studentColors.tertiary],
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.white,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: const [
                      Tab(icon: Icon(Icons.history), text: 'All Attempts'),
                      Tab(icon: Icon(Icons.bar_chart), text: 'Statistics'),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAttemptsTab(),
                    _buildStatisticsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _selectedQuizTitle = 'All Quizzes';

  Widget _buildAttemptsTab() {
    return Consumer<QuizAttemptProvider>(
      builder: (context, attemptsProvider, _) {
        var attempts = attemptsProvider.studentAttempts
            .where((a) => a.isSubmitted)
            .toList(growable: false);

        // Get unique titles for filter
        final uniqueTitles = ['All Quizzes'];
        uniqueTitles.addAll(attempts
            .map((e) => e.quizTitle.isEmpty ? 'Quiz Attempt' : e.quizTitle)
            .toSet()
            .toList()
          ..sort());

        if (_selectedQuizTitle != 'All Quizzes') {
          attempts = attempts
              .where((a) =>
                  (a.quizTitle.isEmpty ? 'Quiz Attempt' : a.quizTitle) ==
                  _selectedQuizTitle)
              .toList();
        }

        if (_sortBy == 'score') {
          attempts.sort((a, b) => b.score.compareTo(a.score));
        } else if (_sortBy == 'title') {
          attempts.sort((a, b) => a.quizTitle.compareTo(b.quizTitle));
        } else {
          attempts.sort((a, b) => b.startTime.compareTo(a.startTime));
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter/Sort controls
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _studentColors.primary
                                  .withValues(alpha: 0.2)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedQuizTitle,
                            icon: Icon(Icons.filter_list,
                                color: _studentColors.primary, size: 20),
                            items: uniqueTitles.map((title) {
                              return DropdownMenuItem(
                                  value: title,
                                  child: Text(title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13)));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null)
                                setState(() => _selectedQuizTitle = value);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: PopupMenuButton<String>(
                        initialValue: _sortBy,
                        onSelected: (value) {
                          setState(() => _sortBy = value);
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem(
                            value: 'date',
                            child: Text('Sort by Date'),
                          ),
                          const PopupMenuItem(
                            value: 'score',
                            child: Text('Sort by Score'),
                          ),
                          const PopupMenuItem(
                            value: 'title',
                            child: Text('Sort by Quiz'),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  _studentColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.sort,
                                  color: _studentColors.primary, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Sort',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (attempts.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Icon(
                          Icons.quiz,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No quiz attempts match',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try changing your filters',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...attempts.map((attempt) {
                    final color = _getScoreColor(attempt.scorePercentage);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Text(
                            '${attempt.scorePercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(
                          attempt.quizTitle.isEmpty
                              ? 'Quiz Attempt'
                              : attempt.quizTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Score: ${attempt.score}/${attempt.totalMarks} • Date: ${attempt.startTime.toString().split(' ')[0]}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            attempt.isPassed
                                ? Icons.check_circle
                                : Icons.warning_amber_rounded,
                            color: color,
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return Consumer<QuizAttemptProvider>(
        builder: (context, attemptsProvider, _) {
      final attempts = attemptsProvider.studentAttempts
          .where((a) => a.isSubmitted)
          .toList(growable: false);
      final total = attempts.length;
      final passed = attempts.where((a) => a.isPassed).length;
      final avg = total == 0
          ? 0.0
          : attempts.map((a) => a.scorePercentage).reduce((a, b) => a + b) /
              total;
      final best = total == 0
          ? 0.0
          : attempts
              .map((a) => a.scorePercentage)
              .reduce((a, b) => a > b ? a : b);

      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Total Quizzes',
                      value: '$total',
                      icon: Icons.quiz,
                      color: _studentColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Passed',
                      value: '$passed',
                      icon: Icons.check_circle,
                      color: const Color(0xFF49A36E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Average Score',
                      value: '${avg.toStringAsFixed(0)}%',
                      icon: Icons.trending_up,
                      color: const Color(0xFFF09A36),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Best Score',
                      value: '${best.toStringAsFixed(0)}%',
                      icon: Icons.star,
                      color: const Color(0xFFE1AC1D),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF3FA66B);
    if (score >= 60) return const Color(0xFFF09A36);
    return const Color(0xFFE05A5A);
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
