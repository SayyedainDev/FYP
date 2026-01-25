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
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Advanced Analytics',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comprehensive insights into your dental practice',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            Consumer<AnalyticsProvider>(
              builder: (context, analyticsProvider, _) {
                if (analyticsProvider.loading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(64.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final analytics = analyticsProvider.analyticsData;
                if (analytics == null) {
                  return Container(
                    padding: const EdgeInsets.all(64),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No analytics data available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Key Metrics Grid
                    GridView.count(
                      crossAxisCount: 4,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.3,
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
                          Colors.orange,
                          Icons.warning_amber,
                        ),
                        _buildMetricCard(
                          'Healthy Cases',
                          analytics.healthyCases.toString(),
                          Colors.teal,
                          Icons.check_circle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Detection Rate Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.trending_up,
                                  color: Colors.orange.shade700,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'Cavity Detection Rate',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF212121),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${analytics.cavityDetectionRate.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_upward,
                                      size: 16,
                                      color: Colors.orange.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${analytics.cavitiesDetected} of ${analytics.totalCases}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: analytics.cavityDetectionRate / 100,
                              minHeight: 12,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.orange.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
