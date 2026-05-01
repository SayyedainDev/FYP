import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const sidebar      = Color(0xFF1A1F2E);
  static const surface      = Color(0xFFFFFFFF);
  static const pageBg       = Color(0xFFF8FAFC);
  static const cardBorder   = Color(0xFFE2E8F0);
  static const textPrimary  = Color(0xFF0F172A);
  static const textSecondary= Color(0xFF64748B);
  static const textMuted    = Color(0xFF94A3B8);
  static const accentBlue   = Color(0xFF3B82F6);

  // Radii
  static const radiusSm = 6.0;
  static const radiusMd = 8.0;
  static const radiusLg = 12.0;
  static const radiusPill = 20.0;

  // Card decoration
  static BoxDecoration card = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: cardBorder, width: 0.5),
  );

  // Text styles
  static const labelSmall = TextStyle(fontSize: 11, color: textMuted, letterSpacing: 0.04);
  static const bodySmall  = TextStyle(fontSize: 12, color: textSecondary);
  static const bodyMd     = TextStyle(fontSize: 13, color: textPrimary);
  static const heading    = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary);

  // Scroll physics
  static const scrollPhysics = BouncingScrollPhysics();
}
