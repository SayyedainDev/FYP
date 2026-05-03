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
    return Semantics(
      label: '$label metric, value $value',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
