import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light; // Default to light
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    AppTheme.setActiveThemeMode(_themeMode);
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString('themeMode');
    if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeStr == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light; // defaults to light
    }
    AppTheme.setActiveThemeMode(_themeMode);
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    AppTheme.setActiveThemeMode(_themeMode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
  }
}
