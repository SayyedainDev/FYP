// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

class WebModelViewer extends StatefulWidget {
  const WebModelViewer({
    super.key,
    this.modelUrl,
    this.viewerUrl,
  }) : assert(modelUrl != null || viewerUrl != null);

  final String? modelUrl;
  final String? viewerUrl;

  @override
  State<WebModelViewer> createState() => _WebModelViewerState();
}

class _WebModelViewerState extends State<WebModelViewer> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'web-model-viewer-${DateTime.now().microsecondsSinceEpoch}';

    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final viewerUrl = widget.viewerUrl;
      final modelUrl = widget.modelUrl;
      final frameUrl = viewerUrl ?? modelUrl ?? 'about:blank';

      final iframe = html.IFrameElement()
        ..src = frameUrl
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow =
            'autoplay; fullscreen; xr-spatial-tracking; gyroscope; accelerometer'
        ..referrerPolicy = 'no-referrer';

      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
