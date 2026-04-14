import 'package:flutter/material.dart';

import '../../core/animation_constants.dart';

class PressableWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;

  const PressableWidget({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.97,
  });

  @override
  State<PressableWidget> createState() => _PressableWidgetState();
}

class _PressableWidgetState extends State<PressableWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.instant,
  );

  late Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: widget.scaleFactor,
  ).animate(CurvedAnimation(parent: _controller, curve: AppCurves.snappy));

  @override
  void didUpdateWidget(covariant PressableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scaleFactor != widget.scaleFactor) {
      _scale = Tween<double>(
        begin: 1.0,
        end: widget.scaleFactor,
      ).animate(CurvedAnimation(parent: _controller, curve: AppCurves.snappy));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canTap = widget.onTap != null;

    return RepaintBoundary(
      child: MouseRegion(
        cursor: canTap ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: canTap ? (_) => _controller.forward() : null,
          onTapUp: canTap
              ? (_) {
                  _controller.reverse();
                  widget.onTap?.call();
                }
              : null,
          onTapCancel: canTap ? () => _controller.reverse() : null,
          child: ScaleTransition(
            scale: _scale,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
