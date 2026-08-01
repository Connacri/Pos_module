import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos_core/pos_core.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fexvpescpgpcqgjpdmzo.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_FdeJGPk4VjtE8EsiVAQzXQ_Gx-H_eyD',
  );

  static bool get isConfigured => url.contains('.supabase.co');

  static Future<void> initialize() async {
    if (!isConfigured) {
      AppLogger.warning('Supabase non configuré : mode hors-ligne uniquement');
      return;
    }
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }
}
