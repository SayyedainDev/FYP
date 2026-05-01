import 'package:flutter/material.dart';

class UploadProgressIndicator extends StatelessWidget {
  const UploadProgressIndicator({super.key, required this.progress});

  final double progress; // 0.0 to 1.0

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 4),
        Text(
          'Uploading... ${(progress * 100).toInt()}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
