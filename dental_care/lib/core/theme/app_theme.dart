import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_semantic_colors.dart';
import 'app_tokens.dart';

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: Brightness.light,
      primary: AppColors.brandPrimary,
      secondary: AppColors.brandSecondary,
      tertiary: const Color(0xFF1D4ED8),
      surface: AppColors.lightSurface,
      surfaceContainerLowest: const Color(0xFFF5F6F8),
      surfaceContainerLow: const Color(0xFFF1F3F6),
      surfaceContainer: const Color(0xFFECEFF3),
      surfaceContainerHigh: const Color(0xFFE6EAF0),
      surfaceContainerHighest: const Color(0xFFE0E5EC),
      onSurface: AppColors.lightOnSurface,
      onSurfaceVariant: const Color(0xFF4B5563),
      outline: const Color(0xFF8B95A5),
      outlineVariant: const Color(0xFFC7CED8),
    );

    final textTheme = GoogleFonts.dmSansTextTheme().copyWith(
      headlineLarge: GoogleFonts.sora(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      headlineMedium: GoogleFonts.sora(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      titleLarge: GoogleFonts.sora(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      splashColor: colorScheme.primary.withValues(alpha: 0.14),
      highlightColor: colorScheme.primary.withValues(alpha: 0.08),
      hoverColor: colorScheme.primary.withValues(alpha: 0.06),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      extensions: const [
        AppSemanticColors(
          success: AppColors.success,
          warning: AppColors.warning,
          info: AppColors.info,
          danger: AppColors.danger,
          surfaceTintSoft: Color(0xFFEFF6FF),
        ),
      ],
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: Brightness.dark,
      primary: const Color(0xFF60A5FA),
      secondary: const Color(0xFF818CF8),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
    );

    final textTheme =
        GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineLarge: GoogleFonts.sora(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      headlineMedium: GoogleFonts.sora(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      titleLarge: GoogleFonts.sora(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      splashColor: colorScheme.primary.withValues(alpha: 0.2),
      highlightColor: colorScheme.primary.withValues(alpha: 0.12),
      hoverColor: colorScheme.primary.withValues(alpha: 0.1),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface.withValues(alpha: 0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      extensions: const [
        AppSemanticColors(
          success: Color(0xFF4ADE80),
          warning: Color(0xFFFBBF24),
          info: Color(0xFF38BDF8),
          danger: Color(0xFFF87171),
          surfaceTintSoft: Color(0xFF172554),
        ),
      ],
    );
  }
}
