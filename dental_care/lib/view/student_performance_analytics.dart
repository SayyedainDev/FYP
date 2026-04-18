import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dental_care/providers/performance_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class StudentPerformanceAnalytics extends StatefulWidget {
  const StudentPerformanceAnalytics({Key? key}) : super(key: key);

  @override
  State<StudentPerformanceAnalytics> createState() =>
      _StudentPerformanceAnalyticsState();
}

class _StudentPerformanceAnalyticsState
    extends State<StudentPerformanceAnalytics> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Analytics'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Consumer<PerformanceProvider>(
        builder: (context, performanceProvider, _) {
          if (performanceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final performance = performanceProvider.performance;

          if (performance == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No performance data available',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPerformanceSummary(performance),
                const SizedBox(height: 24),
                _buildPerformanceCharts(performance),
                const SizedBox(height: 24),
                _buildDetailedMetrics(performance),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPerformanceSummary(dynamic performance) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade700, Colors.blue.shade900],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${performance.overallPerformanceScore.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      performance.performanceStatus,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Text(
                      '${(performance.overallPerformanceScore / 10).toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCharts(dynamic performance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Breakdown',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: performance.averageQuizScore,
                      title:
                          'Quiz\n${performance.averageQuizScore.toStringAsFixed(0)}%',
                      color: Colors.blue.shade400,
                      radius: 50,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    PieChartSectionData(
                      value: performance.averageAssignmentScore,
                      title:
                          'Assignment\n${performance.averageAssignmentScore.toStringAsFixed(0)}%',
                      color: Colors.orange.shade400,
                      radius: 50,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  centerSpaceRadius: 0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedMetrics(dynamic performance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Metrics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildMetricTile(
          'Quizzes Taken',
          '${performance.totalQuizzesTaken}',
          Icons.quiz,
          Colors.blue,
        ),
        _buildMetricTile(
          'Average Quiz Score',
          '${performance.averageQuizScore.toStringAsFixed(1)}%',
          Icons.trending_up,
          Colors.green,
        ),
        _buildMetricTile(
          'Assignments Submitted',
          '${performance.assignmentsSubmitted}',
          Icons.assignment,
          Colors.orange,
        ),
        _buildMetricTile(
          'Average Assignment Score',
          '${performance.averageAssignmentScore.toStringAsFixed(1)}%',
          Icons.task,
          Colors.purple,
        ),
        _buildMetricTile(
          'Lecture Videos Watched',
          '${performance.lectureVideosWatched}',
          Icons.video_library,
          Colors.red,
        ),
        _buildMetricTile(
          'Last Activity',
          performance.lastActivityDate.toString().split(' ')[0],
          Icons.access_time,
          Colors.grey,
        ),
      ],
    );
  }

  Widget _buildMetricTile(
      String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
