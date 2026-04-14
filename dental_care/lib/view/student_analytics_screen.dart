import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/quiz_attempt_provider.dart';

class StudentAnalyticsScreen extends StatelessWidget {
  const StudentAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final attempts = context
        .watch<QuizAttemptProvider>()
        .studentAttempts
        .where((a) => a.isSubmitted)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final trend = attempts.take(10).toList();
    final correctPct = attempts.isEmpty
        ? 0.0
        : (attempts.map((a) => a.scorePercentage).reduce((a, b) => a + b) /
                attempts.length)
            .clamp(0, 100);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Analytics',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Container(
            height: 260,
            padding: const EdgeInsets.all(16),
            decoration: _box(context),
            child: LineChart(
              LineChartData(
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true),
                titlesData: const FlTitlesData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    spots: List.generate(
                      trend.length,
                      (i) => FlSpot(i.toDouble(), trend[i].scorePercentage),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 260,
            padding: const EdgeInsets.all(16),
            decoration: _box(context),
            child: PieChart(
              PieChartData(sectionsSpace: 2, centerSpaceRadius: 38, sections: [
                PieChartSectionData(
                    value: correctPct.toDouble(), title: 'Correct'),
                PieChartSectionData(
                    value: (100 - correctPct).toDouble(),
                    title: 'Wrong/Skipped'),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _box(BuildContext context) => BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      );
}
