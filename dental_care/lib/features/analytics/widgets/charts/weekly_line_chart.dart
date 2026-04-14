import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../models/analytics_dashboard_data.dart';

class WeeklyLineChart extends StatelessWidget {
  final List<TrendPoint> points;

  const WeeklyLineChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: 'Weekly quiz trend line chart',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Weekly Quiz Trend', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: AppColors.brandPrimary,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        spots: points
                            .asMap()
                            .entries
                            .map(
                              (entry) => FlSpot(
                                entry.key.toDouble(),
                                entry.value.value,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 30),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= points.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(points[index].label);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
