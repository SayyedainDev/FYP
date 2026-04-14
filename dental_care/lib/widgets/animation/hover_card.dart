import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/animation_constants.dart';

class HoverCard extends StatefulWidget {
  final Widget child;
  final BorderRadius? borderRadius;

  const HoverCard({
    super.key,
    required this.child,
    this.borderRadius,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);
    final colorScheme = Theme.of(context).colorScheme;

    if (!kIsWeb) {
      return RepaintBoundary(child: widget.child);
    }

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppCurves.smooth,
          transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: _hovered
                  ? colorScheme.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          child: ClipRRect(borderRadius: radius, child: widget.child),
        ),
      ),
    );
  }
}
