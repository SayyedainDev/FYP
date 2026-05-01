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
  // More prominent colors - better contrast
  static const Color brandPrimary =
      Color(0xFF3482F6); // Prominent blue
  static const Color brandSecondary =
      Color(0xFF2B5BE3); // Deeper secondary blue

  static const Color lightBackground = Color(0xFFF1F4F9); // Slightly deeper light gray
  static const Color lightSurface =
      Color(0xFFFFFFFF); // Pure white for better contrast
  static const Color lightOnSurface =
      Color(0xFF1E293B); // Darker slate for readability

  static const Color sidebarDark = Color(0xFF1E293B); // Deeper navy-slate
  static const Color sidebarDarkSoft =
      Color(0xFF334155); // Prominent slate
  static const Color sidebarOnDark = Color(0xFFF8FAFC); // Brighter white
  static const Color sidebarAccent = Color(0xFF3482F6); // Matching prominent primary

  static const Color darkBackground = Color(0xFF0F172A); // Deeper dark background
  static const Color darkSurface = Color(0xFF1E293B); // Deeper dark surface
  static const Color darkOnSurface =
      Color(0xFFF1F5F9); // Crisp light gray for text

  static const Color success = Color(0xFF10B981); // Prominent emerald green
  static const Color warning = Color(0xFFF59E0B); // Prominent amber
  static const Color info = Color(0xFF0EA5E9); // Prominent sky blue
  static const Color danger = Color(0xFFEF4444); // Prominent red
}
