import 'package:flutter/material.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color warning;
  final Color info;
  final Color danger;
  final Color surfaceTintSoft;

  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.danger,
    required this.surfaceTintSoft,
  });

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? danger,
    Color? surfaceTintSoft,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      danger: danger ?? this.danger,
      surfaceTintSoft: surfaceTintSoft ?? this.surfaceTintSoft,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      surfaceTintSoft: Color.lerp(surfaceTintSoft, other.surfaceTintSoft, t) ??
          surfaceTintSoft,
    );
  }
}
