import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/responsive/app_breakpoints.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../providers/quiz_provider.dart';
import '../../../providers/quiz_attempt_provider.dart';
import '../../../models/quiz_attempt.dart';
import '../widgets/analytics_stat_card.dart';
import 'package:intl/intl.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  // Doctor's Quiz Results Dashboard
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  bool _isLoading = true;
  List<QuizAttempt> _attempts = [];
  Map<String, String> _quizNames = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllAttempts());
  }

  Future<void> _loadAllAttempts() async {
    setState(() => _isLoading = true);

    final quizzes = context.read<QuizProvider>().quizzes;
    final attemptProvider = context.read<QuizAttemptProvider>();

    List<QuizAttempt> allAttempts = [];
    Map<String, String> qNames = {};

    for (var quiz in quizzes) {
      qNames[quiz.id] = quiz.title;
      final attemptsForQuiz = await attemptProvider.fetchQuizAttempts(quiz.id);
      allAttempts.addAll(attemptsForQuiz);
    }

    allAttempts.sort((a, b) => b.startTime.compareTo(a.startTime));

    if (mounted) {
      setState(() {
        _attempts = allAttempts;
        _quizNames = qNames;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final contentWidth = AppBreakpoints.contentMaxWidth(context);
    final horizontal = AppBreakpoints.horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllAttempts,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(horizontal),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(context, _attempts, contentWidth),
                const SizedBox(height: AppSpacing.section),
                Text('Student Results',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                _buildResultsTable(_attempts),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
      BuildContext context, List<QuizAttempt> attempts, double contentWidth) {
    final gridColumns = AppBreakpoints.isDesktop(context)
        ? 4
        : (AppBreakpoints.isTablet(context) ? 2 : 1);

    final totalAttempts = attempts.length;
    final submittedAttempts = attempts.where((a) => a.isSubmitted).toList();
    final averageScore = submittedAttempts.isEmpty
        ? 0
        : submittedAttempts.fold(0.0, (sum, a) => sum + a.scorePercentage) /
            submittedAttempts.length;
    final passRate = submittedAttempts.isEmpty
        ? 0
        : (submittedAttempts.where((a) => a.isPassed).length /
                submittedAttempts.length) *
            100;

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.lg,
      children: [
        _buildStatCard(context, gridColumns, contentWidth, 'Total Attempts',
            '$totalAttempts'),
        _buildStatCard(context, gridColumns, contentWidth, 'Completed',
            '${submittedAttempts.length}'),
        _buildStatCard(context, gridColumns, contentWidth, 'Avg Score',
            '${averageScore.toStringAsFixed(1)}%'),
        _buildStatCard(context, gridColumns, contentWidth, 'Pass Rate',
            '${passRate.toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, int columns, double contentWidth,
      String label, String value) {
    double width = MediaQuery.sizeOf(context).width;
    if (columns > 1) {
      final spacing = (columns - 1) * AppSpacing.lg;
      width = (contentWidth - spacing) / columns;
    } else {
      width = width - (AppBreakpoints.horizontalPadding(context) * 2);
    }

    return SizedBox(
      width: width,
      height: 140,
      child: AnalyticsStatCard(label: label, value: value, delta: 0.0),
    );
  }

  Widget _buildResultsTable(List<QuizAttempt> attempts) {
    if (attempts.isEmpty) {
      return const Center(child: Text('No attempts recorded yet.'));
    }

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Student')),
            DataColumn(label: Text('Quiz')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Score')),
            DataColumn(label: Text('Grade')),
            DataColumn(label: Text('Duration')),
            DataColumn(label: Text('Violations')),
          ],
          rows: attempts.map((a) {
            final violationCount =
                a.tabSwitchCount + a.fullscreenExitCount + a.inactivityCount;

            final dateFormat = DateFormat('MMM d, y, h:mm a');

            return DataRow(cells: [
              DataCell(Text(a.studentName)),
              DataCell(Text(_quizNames[a.quizId] ?? a.quizTitle)),
              DataCell(Text(dateFormat.format(a.startTime))),
              DataCell(Text(
                  '${a.score}/${a.totalMarks} (${a.scorePercentage.toStringAsFixed(1)}%)')),
              DataCell(
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: a.isPassed
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(a.grade,
                      style: TextStyle(
                          color: a.isPassed ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              DataCell(Text(a.durationText)),
              DataCell(
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: violationCount > 0
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                      violationCount > 0 ? '$violationCount Flags' : 'None',
                      style: TextStyle(
                          color: violationCount > 0
                              ? Colors.orange.shade800
                              : Colors.green)),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
