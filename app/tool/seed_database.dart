import 'package:flutter/material.dart';

import 'package:pos_core/pos_core.dart';
import 'package:pos_data/pos_data.dart';

/// Script de remplissage des données de démonstration.
///
/// Peuple toutes les boxes ObjectBox (catégories, produits, clients,
/// ventes, lignes de vente, factures, lignes de facture, paiements)
/// ainsi que les tables Supabase correspondantes avec des exemples
/// réalistes.
///
/// Lancement (desktop / Windows) :
///   cd app
///   flutter run -d windows -t tool/seed_database.dart
///
/// Args optionnels :
///   --force     efface puis réinsère les données de démonstration
///   --no-cloud  ne contacte pas Supabase (ObjectBox uniquement)
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final force = args.contains('--force');
  final syncCloud = !args.contains('--no-cloud');

  AppLogger.info('Ouverture de la base ObjectBox...');
  await ObjectboxDatabase.open();
  if (force) {
    _clearBoxes();
    AppLogger.info('Base vidée (--force)');
  }

  AppLogger.info('Remplissage des boxes ObjectBox...');
  final seeded = await SeedService.seedIfEmpty();
  if (!seeded) {
    AppLogger.info('Des données existent déjà, opération ignorée.');
    AppLogger.info('Relancez avec --force pour réinitialiser.');
  } else {
    AppLogger.info(
      'ObjectBox rempli : '
      '${SeedData.categories.length} catégories, '
      '${SeedData.products.length} produits, '
      '${SeedData.customers.length} clients, '
      '${SeedData.sales.length} ventes, '
      '${SeedData.invoices.length} factures, '
      '${SeedData.payments.length} paiements.',
    );
  }

  if (syncCloud) {
    if (!SupabaseConfig.isConfigured) {
      AppLogger.warning('Supabase non configuré, étape cloud ignorée.');
    } else {
      AppLogger.info('Initialisation de Supabase...');
      await SupabaseConfig.initialize();
      AppLogger.info('Remplissage des tables Supabase...');
      await SeedService.seedSupabase();
      AppLogger.info('Supabase rempli avec succès.');
    }
  }

  ObjectboxDatabase.close();
  AppLogger.info('Terminé.');
}

void _clearBoxes() {
  SeedService.clearObjectBox();
}
