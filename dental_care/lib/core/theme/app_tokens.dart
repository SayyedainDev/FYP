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
  // Modern balanced colors - professional and popular on modern websites
  // Slightly darker shades, not pastel, not harsh - like Figma, Stripe, Linear
  static const Color brandPrimary =
      Color(0xFF3B82F6); // Modern blue (deeper than pastel, professional)
  static const Color brandSecondary =
      Color(0xFF06B6D4); // Cyan accent (balanced saturation)

  static const Color lightBackground = Color(0xFFF8FAFC); // Clean light gray
  static const Color lightSurface =
      Color(0xFFFFFFFF); // Pure white (better contrast)
  static const Color lightOnSurface =
      Color(0xFF1E293B); // Slate-900 (modern dark text)

  static const Color sidebarDark = Color(0xFF1E293B); // Slate-900 (modern dark)
  static const Color sidebarDarkSoft =
      Color(0xFF334155); // Slate-700 (complementary dark)
  static const Color sidebarOnDark =
      Color(0xFFF1F5F9); // Slate-100 (soft white)
  static const Color sidebarAccent = Color(0xFF3B82F6); // Matching modern blue

  static const Color darkBackground =
      Color(0xFF0F172A); // Slate-950 (very dark)
  static const Color darkSurface = Color(0xFF1E293B); // Slate-900 (dark)
  static const Color darkOnSurface =
      Color(0xFFF1F5F9); // Slate-100 (light text on dark)

  // Modern semantic colors - used in professional UI
  static const Color success = Color(0xFF10B981); // Emerald-500 (vibrant green)
  static const Color warning = Color(0xFFF59E0B); // Amber-500 (warm orange)
  static const Color info = Color(0xFF0EA5E9); // Sky-500 (bright blue)
  static const Color danger = Color(0xFFEF4444); // Red-500 (clear red)
}
