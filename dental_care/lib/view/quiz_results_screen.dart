import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dental_care/providers/quiz_provider.dart';
import 'package:dental_care/models/quiz_attempt.dart';
import 'package:intl/intl.dart';
import 'package:dental_care/utils/csv_export_helper.dart';
import 'dart:html' as html;
import 'dart:convert';

class QuizResultsScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;

  const QuizResultsScreen({
    Key? key,
    required this.quizId,
    required this.quizTitle,
  }) : super(key: key);

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  String _sortBy = 'score'; // score, name, date, percentage
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.blue.shade700,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Quiz Results',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade700, Colors.blue.shade900],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.quizTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Stats Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer<QuizProvider>(
                builder: (context, quizProvider, _) {
                  // Get attempts for this quiz
                  final attempts = quizProvider.quizAttempts
                      .where((a) => a.quizId == widget.quizId)
                      .toList();

                  final submittedAttempts =
                      attempts.where((a) => a.isSubmitted).toList();
                  final totalAttempts = attempts.length;
                  final completedAttempts = submittedAttempts.length;

                  double avgScore = 0;
                  if (submittedAttempts.isNotEmpty) {
                    avgScore = submittedAttempts.fold<double>(
                          0,
                          (sum, attempt) => sum + attempt.scorePercentage,
                        ) /
                        submittedAttempts.length;
                  }

                  int passCount = submittedAttempts
                      .where((a) => a.scorePercentage >= 50)
                      .length;
                  double passRate = completedAttempts > 0
                      ? (passCount / completedAttempts) * 100
                      : 0;

                  return Column(
                    children: [
                      // Statistics Grid
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: [
                          _buildStatCard(
                            title: 'Total Attempts',
                            value: '$totalAttempts',
                            change: '0%',
                            icon: Icons.people,
                            color: Colors.blue,
                          ),
                          _buildStatCard(
                            title: 'Completed',
                            value: '$completedAttempts',
                            change: completedAttempts > 0
                                ? '${((completedAttempts / totalAttempts) * 100).toStringAsFixed(0)}%'
                                : '0%',
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                          _buildStatCard(
                            title: 'Avg Score',
                            value: '${avgScore.toStringAsFixed(1)}%',
                            change: avgScore >= 50 ? '✓' : '✗',
                            icon: Icons.trending_up,
                            color: avgScore >= 50 ? Colors.green : Colors.red,
                          ),
                          _buildStatCard(
                            title: 'Pass Rate',
                            value: '${passRate.toStringAsFixed(1)}%',
                            change: '$passCount/$completedAttempts',
                            icon: Icons.grade,
                            color:
                                passRate >= 50 ? Colors.amber : Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Sort Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Student Results (${submittedAttempts.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              // Download CSV Button
                              Tooltip(
                                message: 'Download Results as CSV',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () => _downloadResultsAsCSV(submittedAttempts),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.download, color: Colors.green),
                                        SizedBox(width: 4),
                                        Text(
                                          'CSV',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              PopupMenuButton<String>(
                                initialValue: _sortBy,
                                onSelected: (value) {
                                  setState(() => _sortBy = value);
                                },
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem(
                                    value: 'score',
                                    child: Text('Sort by Score'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'percentage',
                                    child: Text('Sort by Percentage'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'name',
                                    child: Text('Sort by Name'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'date',
                                    child: Text('Sort by Date'),
                                  ),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.sort, color: Colors.blue),
                                      SizedBox(width: 4),
                                      Text(
                                        'Sort',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Student Results List
                      if (submittedAttempts.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'No attempts recorded yet',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        _buildResultsList(submittedAttempts),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String change,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  change,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green.shade600,
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

  Widget _buildResultsList(List<QuizAttempt> attempts) {
    // Sort attempts
    List<QuizAttempt> sortedAttempts = List.from(attempts);

    switch (_sortBy) {
      case 'score':
        sortedAttempts.sort((a, b) => _sortAscending
            ? a.score.compareTo(b.score)
            : b.score.compareTo(a.score));
        break;
      case 'percentage':
        sortedAttempts.sort((a, b) => _sortAscending
            ? a.scorePercentage.compareTo(b.scorePercentage)
            : b.scorePercentage.compareTo(a.scorePercentage));
        break;
      case 'name':
        sortedAttempts.sort((a, b) => _sortAscending
            ? a.studentName.compareTo(b.studentName)
            : b.studentName.compareTo(a.studentName));
        break;
      case 'date':
        sortedAttempts.sort((a, b) => _sortAscending
            ? a.endTime!.compareTo(b.endTime!)
            : b.endTime!.compareTo(a.endTime!));
        break;
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedAttempts.length,
      itemBuilder: (context, index) {
        final attempt = sortedAttempts[index];
        final percentage = attempt.scorePercentage;
        final isPassed = percentage >= 50;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPassed ? Colors.green.shade200 : Colors.orange.shade200,
            ),
            color: isPassed ? Colors.green.shade50 : Colors.orange.shade50,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _showAttemptDetails(context, attempt);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Student name and result badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                attempt.studentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Student ID: ${attempt.studentId}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
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
                            color: isPassed
                                ? Colors.green.shade600
                                : Colors.orange.shade600,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isPassed ? 'PASSED' : 'FAILED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Score and percentage
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Score',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${attempt.score}/${attempt.totalMarks}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Percentage',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: percentage >= 50
                                    ? Colors.green.shade600
                                    : Colors.orange.shade600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Submitted',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('MMM dd, HH:mm')
                                  .format(attempt.endTime ?? DateTime.now()),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage >= 50
                              ? Colors.green.shade600
                              : Colors.orange.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAttemptDetails(BuildContext context, QuizAttempt attempt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.8,
        minChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attempt.studentName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          attempt.quizTitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
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
                        color: attempt.scorePercentage >= 50
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${attempt.scorePercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: attempt.scorePercentage >= 50
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Details Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _buildDetailCard(
                      title: 'Score',
                      value: '${attempt.score}/${attempt.totalMarks}',
                      icon: Icons.grade,
                    ),
                    _buildDetailCard(
                      title: 'Questions Answered',
                      value:
                          '${attempt.responses.where((r) => r.selectedOption != null).length}/${attempt.responses.length}',
                      icon: Icons.question_answer,
                    ),
                    _buildDetailCard(
                      title: 'Correct Answers',
                      value:
                          '${attempt.responses.where((r) => r.isCorrect == true).length}',
                      icon: Icons.check_circle,
                    ),
                    _buildDetailCard(
                      title: 'Time Taken',
                      value: _formatDuration(
                        attempt.endTime!.difference(attempt.startTime),
                      ),
                      icon: Icons.schedule,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Anti-cheating info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Integrity Check',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tab Switches: ${attempt.tabSwitchCount}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          Text(
                            'Fullscreen Exits: ${attempt.fullscreenExitCount}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Auto Submit: ${attempt.autoSubmitTriggered ? 'Yes' : 'No'}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade600),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _downloadResultsAsCSV(List<QuizAttempt> attempts) {
    try {
      // Generate CSV content
      final csvContent = CSVExportHelper.generateQuizResultsCSV(
        widget.quizTitle,
        attempts,
      );

      // Create a blob and download
      final bytes = utf8.encode(csvContent);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrl(blob);
      final link = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..download = CSVExportHelper.generateFileName(widget.quizTitle);

      link.click();
      html.Url.revokeObjectUrl(url);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Results downloaded successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading file: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours h $minutes m';
    } else if (minutes > 0) {
      return '$minutes m $seconds s';
    } else {
      return '$seconds s';
    }
  }
}
