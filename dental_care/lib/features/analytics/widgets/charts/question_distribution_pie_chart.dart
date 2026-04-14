import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../models/analytics_dashboard_data.dart';

class QuestionDistributionPieChart extends StatelessWidget {
  final List<PieSliceData> slices;

  const QuestionDistributionPieChart({
    super.key,
    required this.slices,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.success,
      AppColors.warning,
      AppColors.danger,
    ];

    return Semantics(
      label: 'Question difficulty distribution pie chart',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question Distribution',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 38,
                    sections: slices.asMap().entries.map((entry) {
                      final item = entry.value;
                      return PieChartSectionData(
                        value: item.value,
                        color: colors[entry.key % colors.length],
                        title: item.value.toStringAsFixed(0),
                        radius: 54,
                      );
                    }).toList(),
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
