import 'package:flutter/material.dart';

import 'animation_constants.dart';

class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required Widget page})
      : super(
          transitionDuration: AppDurations.normal,
          reverseTransitionDuration: AppDurations.fast,
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slide = Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: AppCurves.enter),
            );
            final fade =
                CurvedAnimation(parent: animation, curve: AppCurves.enter);
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
        );
}
