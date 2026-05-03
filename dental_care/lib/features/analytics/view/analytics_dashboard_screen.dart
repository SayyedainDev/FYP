import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:html' as html;
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
  String _searchQuery = '';
  String? _selectedQuizId;
  String? _gradeFilter;
  DateTime? _startDate;
  DateTime? _endDate;

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
    final filteredAttempts = _getFilteredAttempts();

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
                _buildFilters(),
                const SizedBox(height: AppSpacing.section),
                Text('Student Results',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                _buildResultsTable(filteredAttempts),
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

  List<QuizAttempt> _getFilteredAttempts() {
    final filtered = _attempts.where((attempt) {
      if (_searchQuery.isNotEmpty &&
          !attempt.studentName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase())) {
        return false;
      }

      if (_selectedQuizId != null && attempt.quizId != _selectedQuizId) {
        return false;
      }

      if (_gradeFilter != null) {
        final passed = attempt.scorePercentage >= 50;
        if (_gradeFilter == 'pass' && !passed) return false;
        if (_gradeFilter == 'fail' && passed) return false;
      }

      if (_startDate != null && attempt.startTime.isBefore(_startDate!)) {
        return false;
      }

      if (_endDate != null) {
        final endOfDay =
            _endDate!.add(const Duration(hours: 23, minutes: 59, seconds: 59));
        if (attempt.startTime.isAfter(endOfDay)) return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) => b.startTime.compareTo(a.startTime));
    return filtered;
  }

  Widget _buildFilters() {
    final hasFilters = _searchQuery.isNotEmpty ||
        _selectedQuizId != null ||
        _gradeFilter != null ||
        _startDate != null ||
        _endDate != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filters', style: Theme.of(context).textTheme.titleMedium),
              Row(
                children: [
                  if (hasFilters)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _selectedQuizId = null;
                          _gradeFilter = null;
                          _startDate = null;
                          _endDate = null;
                        });
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear'),
                    ),
                  TextButton.icon(
                    onPressed: () =>
                        _downloadFilteredCSV(_getFilteredAttempts()),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('CSV'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search student name...',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;
              final children = [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedQuizId,
                    decoration: InputDecoration(
                      labelText: 'Quiz',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All Quizzes')),
                      ..._quizNames.entries.map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          )),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedQuizId = value),
                  ),
                ),
                const SizedBox(width: 12, height: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _gradeFilter,
                    decoration: InputDecoration(
                      labelText: 'Grade',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Grades')),
                      DropdownMenuItem(value: 'pass', child: Text('Pass')),
                      DropdownMenuItem(value: 'fail', child: Text('Fail')),
                    ],
                    onChanged: (value) => setState(() => _gradeFilter = value),
                  ),
                ),
              ];

              return isNarrow
                  ? Column(
                      children: [
                        children[0],
                        const SizedBox(height: 12),
                        children[2],
                      ],
                    )
                  : Row(children: children);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(_startDate == null
                      ? 'Start Date'
                      : DateFormat('MMM d, yyyy').format(_startDate!)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _endDate = picked);
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(_endDate == null
                      ? 'End Date'
                      : DateFormat('MMM d, yyyy').format(_endDate!)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _downloadFilteredCSV(List<QuizAttempt> attempts) {
    final buffer = StringBuffer();
    buffer.writeln('Student,Quiz,Date,Score,Grade,Duration,Violations');
    for (final a in attempts) {
      final violationCount =
          a.tabSwitchCount + a.fullscreenExitCount + a.inactivityCount;
      final safe = (String value) => '"${value.replaceAll('"', '""')}"';
      buffer.writeln([
        safe(a.studentName),
        safe(_quizNames[a.quizId] ?? a.quizTitle),
        safe(DateFormat('MMM d, y, h:mm a').format(a.startTime)),
        safe(
            '${a.score}/${a.totalMarks} (${a.scorePercentage.toStringAsFixed(1)}%)'),
        safe(a.grade),
        safe(a.durationText),
        safe(violationCount > 0 ? '$violationCount Flags' : 'None'),
      ].join(','));
    }

    final blob = html.Blob([utf8.encode(buffer.toString())], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'quiz_results.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
