import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/case_provider.dart';

class AdvancedAnalyticsScreen extends StatefulWidget {
  const AdvancedAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AdvancedAnalyticsScreen> createState() =>
      _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState extends State<AdvancedAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final cases = context.read<CaseProvider>().cases;
      context.read<AnalyticsProvider>().generateAnalytics(
        'current_user_id', // Replace with actual user ID
        cases,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Analytics'), elevation: 0),
      body: Consumer<AnalyticsProvider>(
        builder: (context, analyticsProvider, _) {
          if (analyticsProvider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final analytics = analyticsProvider.analyticsData;
          if (analytics == null) {
            return const Center(child: Text('No analytics data available'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Key Metrics
                const Text(
                  'Key Metrics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMetricCard(
                      'Total Patients',
                      analytics.totalPatients.toString(),
                      Colors.blue,
                      Icons.people,
                    ),
                    _buildMetricCard(
                      'Total Cases',
                      analytics.totalCases.toString(),
                      Colors.green,
                      Icons.folder,
                    ),
                    _buildMetricCard(
                      'Cavities Detected',
                      analytics.cavitiesDetected.toString(),
                      Colors.red,
                      Icons.warning,
                    ),
                    _buildMetricCard(
                      'Healthy Cases',
                      analytics.healthyCases.toString(),
                      Colors.teal,
                      Icons.check_circle,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Detection Rate
                const Text(
                  'Cavity Detection Rate',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${analytics.cavityDetectionRate.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: analytics.cavityDetectionRate / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Appointment Statistics
                const Text(
                  'Appointment Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatRow(
                        'This Month',
                        analytics.appointmentsThisMonth.toString(),
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        'Completed',
                        analytics.appointmentsCompleted.toString(),
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        'Completion Rate',
                        '${analytics.appointmentCompletionRate.toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Top Affected Teeth
                if (analytics.toothWiseAnalysis.isNotEmpty) ...[
                  const Text(
                    'Top Affected Teeth',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: analytics.toothWiseAnalysis.length,
                    itemBuilder: (context, index) {
                      final tooth = analytics.toothWiseAnalysis[index];
                      return ListTile(
                        title: Text(tooth.toothName),
                        subtitle: Text(
                          '${tooth.casesFound} cases - ${tooth.detectionFrequency.toStringAsFixed(1)}%',
                        ),
                        trailing: Text(
                          '${tooth.treatmentSuccessRate.toStringAsFixed(0)}% Success',
                          style: const TextStyle(color: Colors.green),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}
