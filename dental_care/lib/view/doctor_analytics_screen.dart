import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dental_care/providers/performance_provider.dart';
import 'package:dental_care/provider/auth_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class DoctorAnalyticsScreen extends StatefulWidget {
  const DoctorAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<DoctorAnalyticsScreen> createState() => _DoctorAnalyticsScreenState();
}

class _DoctorAnalyticsScreenState extends State<DoctorAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      context
          .read<PerformanceProvider>()
          .fetchInstructorStudentsPerformance(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Analytics'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Consumer<PerformanceProvider>(
        builder: (context, performanceProvider, _) {
          if (performanceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = performanceProvider.allStudentsPerformance;
          final averageScore = performanceProvider.getAveragePerformanceScore();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCards(students, averageScore),
                const SizedBox(height: 24),
                _buildPerformanceChart(students),
                const SizedBox(height: 24),
                _buildClassStatistics(students),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCards(List students, double averageScore) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatCard(
          title: 'Total Students',
          value: '${students.length}',
          icon: Icons.group,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'Avg Class Score',
          value: '${averageScore.toStringAsFixed(1)}%',
          icon: Icons.trending_up,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'Excellent Performers',
          value:
              '${students.where((s) => s.performanceStatus == 'Excellent').length}',
          icon: Icons.star,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'Needs Improvement',
          value:
              '${students.where((s) => s.performanceStatus == 'Needs Improvement').length}',
          icon: Icons.warning,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
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
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart(List students) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Distribution',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
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
                      value: students
                          .where((s) => s.performanceStatus == 'Excellent')
                          .length
                          .toDouble(),
                      title:
                          'Excellent\n${students.where((s) => s.performanceStatus == 'Excellent').length}',
                      color: Colors.green.shade400,
                      radius: 50,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    PieChartSectionData(
                      value: students
                          .where((s) => s.performanceStatus == 'Good')
                          .length
                          .toDouble(),
                      title:
                          'Good\n${students.where((s) => s.performanceStatus == 'Good').length}',
                      color: Colors.blue.shade400,
                      radius: 50,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    PieChartSectionData(
                      value: students
                          .where((s) => s.performanceStatus == 'Average')
                          .length
                          .toDouble(),
                      title:
                          'Average\n${students.where((s) => s.performanceStatus == 'Average').length}',
                      color: Colors.orange.shade400,
                      radius: 50,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
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

  Widget _buildClassStatistics(List students) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text('Avg Quizzes per Student'),
            trailing: Text(
              '${(students.isEmpty ? 0 : (students.fold<double>(0.0, (sum, s) => sum + s.totalQuizzesTaken) / students.length)).toStringAsFixed(1)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Avg Assignments per Student'),
            trailing: Text(
              '${(students.isEmpty ? 0 : (students.fold<double>(0.0, (sum, s) => sum + s.assignmentsSubmitted) / students.length)).toStringAsFixed(1)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
