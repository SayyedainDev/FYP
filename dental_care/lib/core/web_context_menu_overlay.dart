import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'animation_constants.dart';

class WebContextMenuOverlay extends StatefulWidget {
  final Widget child;

  const WebContextMenuOverlay({super.key, required this.child});

  @override
  State<WebContextMenuOverlay> createState() => _WebContextMenuOverlayState();
}

class _WebContextMenuOverlayState extends State<WebContextMenuOverlay> {
  Offset? _menuPosition;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return widget.child;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (event.buttons == 2) {
          setState(() => _menuPosition = event.position);
        } else if (_menuPosition != null) {
          setState(() => _menuPosition = null);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: widget.child),
          if (_menuPosition != null)
            Positioned(
              left: _menuPosition!.dx,
              top: _menuPosition!.dy,
              child: RepaintBoundary(
                child: AnimatedOpacity(
                  duration: AppDurations.fast,
                  curve: AppCurves.enter,
                  opacity: 1,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 170,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _menuItem(Icons.flag_outlined, 'Flag question'),
                          const Divider(height: 1),
                          _menuItem(Icons.report_gmailerrorred, 'Report issue'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label) {
    return InkWell(
      onTap: () => setState(() => _menuPosition = null),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF4A90E2)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
