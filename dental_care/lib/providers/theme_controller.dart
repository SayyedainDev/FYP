import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class ThemeController extends ChangeNotifier {
  static const String _key = 'app_theme_mode';

  AppThemeMode _mode = AppThemeMode.light;
  bool _isReady = false;

  AppThemeMode get mode => _mode;
  bool get isReady => _isReady;

  ThemeMode get themeMode {
    return ThemeMode.light;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final loadedMode = AppThemeMode.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => AppThemeMode.light,
    );

    _mode = loadedMode == AppThemeMode.light
        ? AppThemeMode.light
        : AppThemeMode.light;

    if (raw != AppThemeMode.light.name) {
      await prefs.setString(_key, AppThemeMode.light.name);
    }

    _isReady = true;
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode nextMode) async {
    _mode = AppThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, AppThemeMode.light.name);
  }

  Future<void> toggleLightDark() async {
    await setMode(AppThemeMode.light);
  }
}
