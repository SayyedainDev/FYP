import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double section = 32;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
}

class AppDurations {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 280);
}

class AppColors {
  // Soft pastel colors - calming and professional
  static const Color brandPrimary = Color(0xFFA8D5FF);     // Soft sky blue (was 0xFF7FB3FF)
  static const Color brandSecondary = Color(0xFF8BB6FF);   // Softer periwinkle blue (was 0xFF3B82F6)

  static const Color lightBackground = Color(0xFFFAFBFC);  // Softer light gray
  static const Color lightSurface = Color(0xFFFCFDFE);     // Almost white with slight tint
  static const Color lightOnSurface = Color(0xFF3D4A5C);   // Soft dark gray (not pure black)

  static const Color sidebarDark = Color(0xFF2C3E50);      // Soft dark blue-gray
  static const Color sidebarDarkSoft = Color(0xFF34495E);  // Slightly lighter dark gray
  static const Color sidebarOnDark = Color(0xFFF0F4F8);    // Soft white
  static const Color sidebarAccent = Color(0xFFA8D5FF);    // Matching soft primary

  static const Color darkBackground = Color(0xFF1A2332);   // Soft dark navy
  static const Color darkSurface = Color(0xFF243447);      // Soft dark slate
  static const Color darkOnSurface = Color(0xFFE8ECF1);    // Soft light gray for text

  static const Color success = Color(0xFF7DD3C0);          // Soft mint green
  static const Color warning = Color(0xFFFFD4A3);          // Soft peach
  static const Color info = Color(0xFF9FC5FF);             // Soft cyan blue
  static const Color danger = Color(0xFFFF9B9B);           // Soft coral red
}
