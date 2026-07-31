import 'package:flutter/material.dart';

class SettingsController extends ChangeNotifier {
  SettingsController();

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  void loadPreferences(String? themeMode, String? localeCode) {
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == themeMode,
      orElse: () => ThemeMode.system,
    );
    if (localeCode != null) {
      _locale = Locale(localeCode);
    }
    notifyListeners();
  }
}
