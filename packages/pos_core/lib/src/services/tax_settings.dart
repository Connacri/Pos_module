import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Réglages de TVA persistés localement.
///
/// Le taux est stocké en fraction (0.19 = 19%). Il sert de valeur par défaut
/// lors de la création d'un nouveau produit depuis le formulaire produit.
class TaxSettings {
  TaxSettings._();

  /// Taux de TVA par défaut appliqué aux nouveaux produits (fraction 0..1).
  static Future<double> defaultRate() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getDouble(AppConstants.keyDefaultTaxRate);
    if (stored == null || !stored.isFinite || stored < 0 || stored > 1) {
      return AppConstants.defaultTaxRate;
    }
    return stored;
  }

  /// Enregistre le taux de TVA par défaut (fraction 0..1).
  static Future<void> setDefaultRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyDefaultTaxRate, rate);
  }
}
