import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos_core/pos_core.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://VOTRE-PROJET.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'VOTRE-CLE-ANON',
  );

  static bool get isConfigured =>
      url.contains('.supabase.co') && anonKey != 'VOTRE-CLE-ANON';

  static Future<void> initialize() async {
    if (!isConfigured) {
      AppLogger.warning('Supabase non configuré : mode hors-ligne uniquement');
      return;
    }
    await Supabase.initialize(url: url, publishableKey: anonKey);
  }
}
