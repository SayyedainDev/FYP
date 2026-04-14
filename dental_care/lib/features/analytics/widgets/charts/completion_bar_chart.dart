import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../models/analytics_dashboard_data.dart';

class CompletionBarChart extends StatelessWidget {
  final List<BarMetric> bars;

  const CompletionBarChart({
    super.key,
    required this.bars,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Completion rate by cohort bar chart',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Completion by Cohort',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: true),
                    barGroups: bars.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.value,
                            width: 20,
                            color: AppColors.brandPrimary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 30),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= bars.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(bars[index].label);
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
