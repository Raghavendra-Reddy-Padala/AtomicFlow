import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _initializeTheme();
  }

  void _initializeTheme() async {
    try {
      await _loadThemeFromPrefs();
    } catch (e) {
      _themeMode = ThemeMode.system; // Fallback to system default
    } finally {
      notifyListeners();
    }
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTheme = prefs.getString('theme');
    switch (storedTheme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _setTheme(ThemeMode.dark, 'dark');
    } else if (_themeMode == ThemeMode.dark) {
      _setTheme(ThemeMode.system, 'system');
    } else {
      _setTheme(ThemeMode.light, 'light');
    }
  }

  void _setTheme(ThemeMode mode, String prefsValue) {
    _themeMode = mode;
    _saveThemeToPrefs(prefsValue);
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme);
  }
}
