import 'package:flutter/material.dart';

const Map<String, Color> kFindingColors = {
  'impacted tooth':          Color(0xFFF59E0B),  // amber
  'filling':                 Color(0xFF22C55E),  // green
  'root canal treatment':    Color(0xFF8B5CF6),  // purple
  'root canal':              Color(0xFF8B5CF6),
  'missing teeth':           Color(0xFF3B82F6),  // blue
  'missing tooth':           Color(0xFF3B82F6),
  'cavity':                  Color(0xFFEF4444),  // red
  'caries':                  Color(0xFFEF4444),
  'bone loss':               Color(0xFFEC4899),  // pink
  'crown':                   Color(0xFF14B8A6),  // teal
  'bridge':                  Color(0xFF06B6D4),  // cyan
};

Color findingColor(String label) =>
  kFindingColors[label.toLowerCase().trim()] ?? const Color(0xFF6B7280);

Color findingBadgeBg(String label) =>
  findingColor(label).withOpacity(0.12);

Color findingBadgeText(String label) =>
  findingColor(label).withOpacity(0.9);
