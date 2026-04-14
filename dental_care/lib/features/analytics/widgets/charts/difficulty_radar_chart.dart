import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../models/analytics_dashboard_data.dart';

class DifficultyRadarChart extends StatelessWidget {
  final List<RadarMetric> metrics;

  const DifficultyRadarChart({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Difficulty profile radar chart',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Difficulty Profile',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 220,
                child: RadarChart(
                  RadarChartData(
                    radarBorderData:
                        const BorderSide(color: Colors.transparent),
                    tickBorderData: const BorderSide(color: Colors.transparent),
                    titlePositionPercentageOffset: 0.2,
                    radarShape: RadarShape.polygon,
                    ticksTextStyle: const TextStyle(fontSize: 10),
                    getTitle: (index, _) {
                      if (index < 0 || index >= metrics.length) {
                        return const RadarChartTitle(text: '');
                      }
                      return RadarChartTitle(text: metrics[index].label);
                    },
                    dataSets: [
                      RadarDataSet(
                        fillColor:
                            AppColors.brandSecondary.withValues(alpha: 0.2),
                        borderColor: AppColors.brandSecondary,
                        entryRadius: 2.5,
                        borderWidth: 2,
                        dataEntries: metrics
                            .map((item) => RadarEntry(value: item.score))
                            .toList(),
                      ),
                    ],
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
