import 'package:flutter/animation.dart';

class AppCurves {
  AppCurves._();

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const spring = Curves.elasticOut;
  static const smooth = Curves.easeInOutCubic;
  static const snappy = Cubic(0.16, 1.0, 0.3, 1.0);
}

class AppDurations {
  AppDurations._();

  static const instant = Duration(milliseconds: 80);
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
  static const pageLoad = Duration(milliseconds: 700);
}
