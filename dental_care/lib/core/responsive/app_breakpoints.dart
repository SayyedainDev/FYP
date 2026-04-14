import 'package:flutter/material.dart';

enum AppDeviceType { mobile, tablet, desktop, largeDesktop }

class AppBreakpoints {
  static const double mobileMax = 599;
  static const double tabletMax = 1023;
  static const double desktopMax = 1439;

  static AppDeviceType fromWidth(double width) {
    if (width <= mobileMax) return AppDeviceType.mobile;
    if (width <= tabletMax) return AppDeviceType.tablet;
    if (width <= desktopMax) return AppDeviceType.desktop;
    return AppDeviceType.largeDesktop;
  }

  static bool isMobile(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width) == AppDeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width) == AppDeviceType.tablet;

  static bool isDesktop(BuildContext context) {
    final type = fromWidth(MediaQuery.sizeOf(context).width);
    return type == AppDeviceType.desktop || type == AppDeviceType.largeDesktop;
  }

  static double horizontalPadding(BuildContext context) {
    final type = fromWidth(MediaQuery.sizeOf(context).width);
    switch (type) {
      case AppDeviceType.mobile:
        return 16;
      case AppDeviceType.tablet:
        return 20;
      case AppDeviceType.desktop:
        return 24;
      case AppDeviceType.largeDesktop:
        return 32;
    }
  }

  static double contentMaxWidth(BuildContext context) {
    final type = fromWidth(MediaQuery.sizeOf(context).width);
    switch (type) {
      case AppDeviceType.mobile:
        return double.infinity;
      case AppDeviceType.tablet:
        return 920;
      case AppDeviceType.desktop:
        return 1200;
      case AppDeviceType.largeDesktop:
        return 1320;
    }
  }
}
