import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Enum for user role
enum UserRole { doctor, student, unknown }

/// Provider for managing app theme based on user role
class ThemeProvider extends ChangeNotifier {
  UserRole _userRole = UserRole.unknown;
  ThemeMode _themeMode = ThemeMode.light;

  UserRole get userRole => _userRole;
  ThemeMode get themeMode => _themeMode;

  /// Get the current theme based on user role
  ThemeData get currentTheme {
    if (_themeMode == ThemeMode.dark) {
      return currentDarkTheme;
    }

    return switch (_userRole) {
      UserRole.doctor => AppTheme.doctorLightTheme(),
      UserRole.student => AppTheme.studentLightTheme(),
      UserRole.unknown => AppTheme.light(),
    };
  }

  /// Get the current dark theme
  ThemeData get currentDarkTheme {
    return switch (_userRole) {
      UserRole.doctor => AppTheme.doctorDarkTheme(),
      UserRole.student => AppTheme.studentDarkTheme(),
      UserRole.unknown => AppTheme.dark(),
    };
  }

  /// Set user role and notify listeners
  void setUserRole(UserRole role) {
    if (_userRole != role) {
      _userRole = role;
      notifyListeners();
    }
  }

  /// Set theme mode and notify listeners
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  /// Parse user role from string
  static UserRole parseUserRole(String? roleString) {
    return switch (roleString?.toLowerCase()) {
      'doctor' => UserRole.doctor,
      'student' => UserRole.student,
      _ => UserRole.unknown,
    };
  }

  /// Get role as string
  String get roleAsString {
    return switch (_userRole) {
      UserRole.doctor => 'doctor',
      UserRole.student => 'student',
      UserRole.unknown => 'unknown',
    };
  }
}
