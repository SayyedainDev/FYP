import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WebModelViewer extends StatelessWidget {
  const WebModelViewer({
    super.key,
    this.modelUrl,
    this.viewerUrl,
  }) : assert(modelUrl != null || viewerUrl != null);

  final String? modelUrl;
  final String? viewerUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      alignment: Alignment.center,
      child: ElevatedButton.icon(
        onPressed: () async {
          final uri = Uri.parse(modelUrl ?? viewerUrl!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        icon: const Icon(Icons.open_in_new),
        label: const Text('Open 3D Model'),
      ),
    );
  }
}
