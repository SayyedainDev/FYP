import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';

class AnalyticsStatCard extends StatelessWidget {
  final String label;
  final String value;
  final double delta;

  const AnalyticsStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.delta,
  });

  @override
  Widget build(BuildContext context) {
    final positive = delta >= 0;
    final color = positive ? AppColors.success : AppColors.danger;
    return Semantics(
      label:
          '$label metric, value $value, change ${delta.toStringAsFixed(0)} percent',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    positive ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${delta.toStringAsFixed(0)}%',
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
