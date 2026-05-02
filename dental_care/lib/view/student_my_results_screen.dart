import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/quiz_attempt.dart';
import '../core/theme/app_semantic_colors.dart';
import '../provider/auth_provider.dart';
import '../providers/quiz_attempt_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/loaders/app_loader.dart';

class StudentMyResultsScreen extends StatefulWidget {
  const StudentMyResultsScreen({super.key});

  @override
  State<StudentMyResultsScreen> createState() => _StudentMyResultsScreenState();
}

class _StudentMyResultsScreenState extends State<StudentMyResultsScreen> {
  ColorScheme get _cs => Theme.of(context).colorScheme;
  AppSemanticColors? get _sem =>
      Theme.of(context).extension<AppSemanticColors>();
  bool _isLoadingResults = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadResults();
      }
    });
  }

  Future<void> _loadResults() async {
    if (_isLoadingResults) return;

    final authProvider = context.read<AuthProvider>();
    final attemptProvider = context.read<QuizAttemptProvider>();
    final uid = authProvider.user?.uid ?? '';
    if (uid.isEmpty) return;

    try {
      _isLoadingResults = true;
      await attemptProvider.fetchStudentAttempts(uid);
    } finally {
      _isLoadingResults = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final attemptProvider = Provider.of<QuizAttemptProvider>(context);

    return Scaffold(
      backgroundColor: _cs.surface,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent(attemptProvider)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (_sem?.success ?? _cs.secondary).withValues(alpha: 0.95),
            _sem?.success ?? _cs.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _cs.shadow.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cs.onSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.assignment_turned_in,
                color: _cs.onSecondary,
                size: 30,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Results',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _cs.onSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View your quiz scores and performance',
                    style: TextStyle(
                      fontSize: 14,
                      color: _cs.onSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            // Refresh button
            IconButton(
              onPressed: _loadResults,
              icon: Icon(Icons.refresh, color: _cs.onSecondary),
              tooltip: 'Refresh',
              style: IconButton.styleFrom(
                backgroundColor: _cs.onSecondary.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(QuizAttemptProvider attemptProvider) {
    if (attemptProvider.isLoading) {
      return const Center(
        child: AppLoader(message: 'Loading results...'),
      );
    }

    final submittedAttempts =
        attemptProvider.studentAttempts.where((a) => a.isSubmitted).toList();

    if (submittedAttempts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: _cs.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete a quiz to see your results here',
              style: TextStyle(color: _cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // Calculate statistics
    final totalAttempts = submittedAttempts.length;
    final passedAttempts =
        submittedAttempts.where((a) => a.scorePercentage >= 50).length;
    final avgScore = submittedAttempts.isEmpty
        ? 0.0
        : submittedAttempts
                .map((a) => a.scorePercentage)
                .reduce((a, b) => a + b) /
            submittedAttempts.length;
    final bestScore = submittedAttempts.isEmpty
        ? 0.0
        : submittedAttempts
            .map((a) => a.scorePercentage)
            .reduce((a, b) => a > b ? a : b);
    final passingRate = submittedAttempts.isEmpty
        ? 0.0
        : (passedAttempts / totalAttempts) * 100;

    return RefreshIndicator(
      onRefresh: _loadResults,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Statistics Cards
            Text(
              'Overall Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 1000
                  ? 4
                  : (MediaQuery.of(context).size.width > 600 ? 2 : 2),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.8,
              children: [
                _buildStatisticCard(
                  title: 'Total Attempts',
                  value: totalAttempts.toString(),
                  icon: Icons.assignment_turned_in,
                  color: _sem?.success ?? _cs.secondary,
                ),
                _buildStatisticCard(
                  title: 'Average Score',
                  value: '${avgScore.toStringAsFixed(1)}%',
                  icon: Icons.trending_up,
                  color: Colors.blue,
                ),
                _buildStatisticCard(
                  title: 'Best Score',
                  value: '${bestScore.toStringAsFixed(0)}%',
                  icon: Icons.star,
                  color: Colors.amber.shade600,
                ),
                _buildStatisticCard(
                  title: 'Passing Rate',
                  value: '${passingRate.toStringAsFixed(0)}%',
                  icon: Icons.percent,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Results List
            Text(
              'Quiz Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: submittedAttempts.length,
              itemBuilder: (context, index) {
                return _buildResultCard(submittedAttempts[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _cs.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _cs.onSurface,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: _cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(QuizAttempt attempt) {
    final percentage = attempt.scorePercentage;
    final isPassed = percentage >= 50;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPassed
              ? (_sem?.success ?? _cs.secondary).withValues(alpha: 0.35)
              : (_sem?.danger ?? _cs.error).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _cs.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _viewResult(attempt),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Grade circle
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPassed
                        ? [
                            (_sem?.success ?? _cs.secondary)
                                .withValues(alpha: 0.85),
                            _sem?.success ?? _cs.secondary,
                          ]
                        : [
                            (_sem?.danger ?? _cs.error).withValues(alpha: 0.85),
                            _sem?.danger ?? _cs.error,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    attempt.grade,
                    style: TextStyle(
                      color: _cs.onSecondary,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Quiz info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attempt.quizTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${attempt.score}/${attempt.totalMarks}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isPassed
                                ? _sem?.success ?? _cs.secondary
                                : _sem?.danger ?? _cs.error,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${percentage.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 13,
                            color: _cs.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: _cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          attempt.durationText,
                          style: TextStyle(
                            fontSize: 12,
                            color: _cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: _cs.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _viewResult(QuizAttempt attempt) async {
    final quizProvider = context.read<QuizProvider>();
    final quiz = await quizProvider.getQuizById(attempt.quizId);
    if (quiz != null && mounted) {
      context.push(
        '/student/quiz/result',
        extra: {'quiz': quiz, 'attempt': attempt},
      );
    }
  }
}
