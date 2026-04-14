import 'package:flutter/material.dart';
import 'app_breakpoints.dart';

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, AppDeviceType deviceType) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final deviceType = AppBreakpoints.fromWidth(width);
    return builder(context, deviceType);
  }
}
