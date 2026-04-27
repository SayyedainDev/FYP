import 'package:flutter/material.dart';
import '../../../data/models/detection_record.dart';

class DetectionDetailScreen extends StatelessWidget {
  final DetectionRecord record;

  const DetectionDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (record.annotatedImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  record.annotatedImageUrl!,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Conditions Found',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: record.conditionsFound.map((c) => Chip(
                label: Text(c),
                backgroundColor: theme.colorScheme.errorContainer,
                labelStyle: TextStyle(color: theme.colorScheme.onErrorContainer),
              )).toList(),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Statistics',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _StatRow('Total Detections', record.totalDetections.toString()),
                    const Divider(),
                    _StatRow('Highest Confidence', '${(record.highestConfidence * 100).toStringAsFixed(1)}%'),
                    const Divider(),
                    _StatRow('Date', '${record.createdAt.day}/${record.createdAt.month}/${record.createdAt.year}'),
                  ],
                ),
              ),
            ),
            
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Clinical Notes',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(record.notes!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
