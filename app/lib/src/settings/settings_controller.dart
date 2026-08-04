import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pos_core/pos_core.dart';

class SettingsController extends ChangeNotifier {
  SettingsController() {
    _load();
  }

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;
  double _defaultTaxRate = AppConstants.defaultTaxRate;

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;

  /// Taux de TVA par défaut (fraction 0..1) appliqué aux nouveaux produits.
  double get defaultTaxRate => _defaultTaxRate;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == prefs.getString(AppConstants.keyThemeMode),
      orElse: () => ThemeMode.system,
    );
    final localeCode = prefs.getString(AppConstants.keyLocale);
    if (localeCode != null) {
      _locale = Locale(localeCode);
    }
    _defaultTaxRate = await TaxSettings.defaultRate();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyThemeMode, mode.name);
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLocale, locale.languageCode);
  }

  Future<void> setDefaultTaxRate(double rate) async {
    final clamped = rate.clamp(0.0, 1.0);
    _defaultTaxRate = clamped;
    notifyListeners();
    await TaxSettings.setDefaultRate(clamped);
  }
}
