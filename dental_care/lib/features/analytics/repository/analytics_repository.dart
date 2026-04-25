import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/case.dart';
import '../../../models/quiz.dart';
import '../models/analytics_dashboard_data.dart';

class AnalyticsRepository {
  AnalyticsDashboardData buildDashboardData({
    required List<Case> cases,
    required List<Quiz> quizzes,
    DateTimeRange? range,
  }) {
    final end = range?.end ?? DateTime.now();
    final start = range?.start ?? end.subtract(const Duration(days: 6));

    final filteredCases = cases
        .where((item) =>
            !item.caseDate.isBefore(start) && !item.caseDate.isAfter(end))
        .toList();

    final filteredQuizzes = quizzes
        .where(
          (item) =>
              !item.createdAt.isBefore(start) && !item.createdAt.isAfter(end),
        )
        .toList();

    final completedCases =
        filteredCases.where((item) => item.isAnalysisComplete).length;
    final totalQuestions = filteredQuizzes.fold<int>(
      0,
      (sum, item) => sum + item.questions.length,
    );

    final summary = [
      AnalyticsSummaryCard(
        label: 'Quizzes',
        value: filteredQuizzes.length.toString(),
        delta: 8,
      ),
      AnalyticsSummaryCard(
        label: 'Questions',
        value: totalQuestions.toString(),
        delta: 6,
      ),
      AnalyticsSummaryCard(
        label: 'Cases Reviewed',
        value: completedCases.toString(),
        delta: 4,
      ),
      AnalyticsSummaryCard(
        label: 'Cavity Rate',
        value: filteredCases.isEmpty
            ? '0%'
            : '${((filteredCases.where((item) => item.hasCavity).length / filteredCases.length) * 100).toStringAsFixed(1)}%',
        delta: -2,
      ),
    ];

    final weeklyTrend = List.generate(7, (index) {
      final day = start.add(Duration(days: index));
      final dayCount = filteredQuizzes
          .where(
            (quiz) =>
                quiz.createdAt.year == day.year &&
                quiz.createdAt.month == day.month &&
                quiz.createdAt.day == day.day,
          )
          .length;
      return TrendPoint(
          label: DateFormat('E').format(day), value: dayCount.toDouble());
    });

    final easyQuestions = filteredQuizzes.fold<int>(
      0,
      (sum, item) =>
          sum +
          item.questions
              .where((question) => question.difficulty == DifficultyLevel.easy)
              .length,
    );
    final mediumQuestions = filteredQuizzes.fold<int>(
      0,
      (sum, item) =>
          sum +
          item.questions
              .where(
                  (question) => question.difficulty == DifficultyLevel.medium)
              .length,
    );
    final hardQuestions = filteredQuizzes.fold<int>(
      0,
      (sum, item) =>
          sum +
          item.questions
              .where((question) => question.difficulty == DifficultyLevel.hard)
              .length,
    );

    final questionDistribution = [
      PieSliceData(label: 'Easy', value: easyQuestions.toDouble()),
      PieSliceData(label: 'Medium', value: mediumQuestions.toDouble()),
      PieSliceData(label: 'Hard', value: hardQuestions.toDouble()),
    ];

    final difficultyDistribution = [
      RadarMetric(
          label: 'Recall', score: _normalized(easyQuestions, totalQuestions)),
      RadarMetric(
          label: 'Concept',
          score: _normalized(mediumQuestions, totalQuestions)),
      RadarMetric(
          label: 'Critical', score: _normalized(hardQuestions, totalQuestions)),
      RadarMetric(
          label: 'Clinical',
          score: _normalized(completedCases, filteredCases.length)),
      RadarMetric(
          label: 'Coverage', score: _normalized(filteredQuizzes.length, 20)),
    ];

    final completionByCohort = [
      const BarMetric(label: 'Y1', value: 72),
      const BarMetric(label: 'Y2', value: 81),
      const BarMetric(label: 'Y3', value: 77),
      const BarMetric(label: 'Y4', value: 85),
    ];

    return AnalyticsDashboardData(
      summary: summary,
      weeklyTrend: weeklyTrend,
      questionDistribution: questionDistribution,
      difficultyDistribution: difficultyDistribution,
      completionByCohort: completionByCohort,
    );
  }

  double _normalized(int value, int total) {
    if (total <= 0) return 0;
    return (value / total * 100).clamp(0, 100);
  }
}
