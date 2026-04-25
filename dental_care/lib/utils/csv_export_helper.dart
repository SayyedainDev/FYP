import 'package:intl/intl.dart';
import '../models/quiz_attempt.dart';

class CSVExportHelper {
  /// Generate CSV content for quiz results
  static String generateQuizResultsCSV(
    String quizTitle,
    List<QuizAttempt> attempts,
  ) {
    final List<List<String>> rows = [];

    // Header
    rows.add([
      'Quiz Title',
      'Student Name',
      'Student ID',
      'Score',
      'Total Points',
      'Percentage',
      'Status',
      'Attempt Date',
      'Duration (seconds)',
      'Grade',
    ]);

    // Data rows
    for (final attempt in attempts) {
      final percentage = attempt.scorePercentage;
      final grade = _getGrade(percentage);

      rows.add([
        quizTitle,
        attempt.studentName.isNotEmpty ? attempt.studentName : 'Unknown',
        attempt.studentId,
        attempt.score.toString(),
        attempt.totalMarks.toString(),
        '${percentage.toStringAsFixed(2)}%',
        attempt.isSubmitted ? 'Submitted' : 'In Progress',
        _formatDate(attempt.startTime),
        _calculateDuration(attempt).toString(),
        grade,
      ]);
    }

    // Summary rows
    if (attempts.isNotEmpty) {
      rows.add([]); // Empty row for spacing
      rows.add(['Summary Statistics', '', '', '', '', '', '', '', '', '']);

      final submittedAttempts = attempts.where((a) => a.isSubmitted).toList();
      if (submittedAttempts.isNotEmpty) {
        final avgScore = submittedAttempts.fold<double>(
              0,
              (sum, attempt) => sum + attempt.scorePercentage,
            ) /
            submittedAttempts.length;

        final passCount =
            submittedAttempts.where((a) => a.scorePercentage >= 60).length;
        final passRate = (passCount / submittedAttempts.length) * 100;

        final maxScore = submittedAttempts
            .map((a) => a.scorePercentage)
            .reduce((a, b) => a > b ? a : b);
        final minScore = submittedAttempts
            .map((a) => a.scorePercentage)
            .reduce((a, b) => a < b ? a : b);

        rows.add(['Total Attempts', submittedAttempts.length.toString()]);
        rows.add(['Average Score', '${avgScore.toStringAsFixed(2)}%']);
        rows.add(['Pass Rate', '${passRate.toStringAsFixed(2)}%']);
        rows.add(['Highest Score', '${maxScore.toStringAsFixed(2)}%']);
        rows.add(['Lowest Score', '${minScore.toStringAsFixed(2)}%']);
      }
    }

    // Convert to CSV format
    return rows
        .map((row) => row.map((field) => _escapeCSV(field)).join(','))
        .join('\n');
  }

  /// Escape CSV fields that contain special characters
  static String _escapeCSV(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Get letter grade based on percentage
  static String _getGrade(double percentage) {
    if (percentage >= 90) return 'A (Excellent)';
    if (percentage >= 80) return 'B (Good)';
    if (percentage >= 70) return 'C (Satisfactory)';
    if (percentage >= 60) return 'D (Passing)';
    return 'F (Failing)';
  }

  /// Format date for CSV
  static String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  /// Calculate duration in seconds for an attempt
  static int _calculateDuration(QuizAttempt attempt) {
    if (attempt.endTime == null) {
      return 0;
    }
    return attempt.endTime!.difference(attempt.startTime).inSeconds;
  }

  /// Generate filename for CSV export
  static String generateFileName(String quizTitle) {
    final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    final sanitizedTitle = quizTitle
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^\w\-]'), '')
        .toLowerCase();
    return '${sanitizedTitle}_results_$timestamp.csv';
  }
}
