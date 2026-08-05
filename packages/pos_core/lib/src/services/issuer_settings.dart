import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Émetteur (entreprise) affiché sur les factures.
///
/// Ces informations sont persistées localement et utilisées comme en-tête
/// lors de la création des factures ainsi que sur l'écran de détail.
class IssuerSettings {
  IssuerSettings._();

  static const String defaultName = 'POS Module';
  static const String defaultAddress = 'Alger, Algérie';
  static const String defaultTaxId = '099900000000';

  static Future<IssuerData> load() async {
    final prefs = await SharedPreferences.getInstance();
    return IssuerData(
      name: prefs.getString(AppConstants.keyIssuerName),
      address: prefs.getString(AppConstants.keyIssuerAddress),
      taxId: prefs.getString(AppConstants.keyIssuerTaxId),
      phone: prefs.getString(AppConstants.keyIssuerPhone),
      email: prefs.getString(AppConstants.keyIssuerEmail),
      logoUrl: prefs.getString(AppConstants.keyIssuerLogoUrl),
    );
  }

  static Future<void> save(IssuerData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyIssuerName, data.name ?? '');
    await prefs.setString(AppConstants.keyIssuerAddress, data.address ?? '');
    await prefs.setString(AppConstants.keyIssuerTaxId, data.taxId ?? '');
    await prefs.setString(AppConstants.keyIssuerPhone, data.phone ?? '');
    await prefs.setString(AppConstants.keyIssuerEmail, data.email ?? '');
    await prefs.setString(AppConstants.keyIssuerLogoUrl, data.logoUrl ?? '');
  }
}

/// Données de l'émetteur (valeurs nulles = non configurées).
class IssuerData {
  const IssuerData({
    this.name,
    this.address,
    this.taxId,
    this.phone,
    this.email,
    this.logoUrl,
  });

  final String? name;
  final String? address;
  final String? taxId;
  final String? phone;
  final String? email;
  final String? logoUrl;
}
