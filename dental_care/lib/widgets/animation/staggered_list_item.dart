import 'package:flutter/material.dart';

import '../../core/animation_constants.dart';

class StaggeredListItem extends StatelessWidget {
  final int index;
  final Widget child;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final delayIndex = index.clamp(0, 8);
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration:
            AppDurations.normal + Duration(milliseconds: (delayIndex) * 60),
        curve: AppCurves.enter,
        builder: (context, value, animatedChild) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: animatedChild,
            ),
          );
        },
        child: child,
      ),
    );
  }
}
