import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Détermine la connectivité **réelle** de l'app : connexion internet et accès
/// à la base Supabase, via de vraies requêtes HTTP.
///
/// `connectivity_plus` est peu fiable sous Windows (il peut renvoyer `none` même
/// avec une connexion active, ou lever une `PlatformException` au démarrage).
/// On s'appuie donc sur de vrais échanges réseau.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService({
    String? supabaseUrl,
    this.probeInterval = const Duration(seconds: 8),
  }) : _supabaseUrl = supabaseUrl {
    _start();
  }

  /// URL de la base Supabase (null => état Supabase considéré comme disponible
  /// en mode hors-ligne).
  final String? _supabaseUrl;
  final Duration probeInterval;
  bool _isOnline = true;
  bool _supabaseOnline = true;
  bool _checking = false;
  Timer? _timer;

  bool get isOnline => _isOnline;
  bool get isSupabaseOnline => _supabaseOnline;

  Future<void> _start() async {
    // Petite pause au démarrage : laisse le réseau s'initialiser.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await _checkNow();

    _timer = Timer.periodic(probeInterval, (_) => _checkNow());
  }

  Future<void> _checkNow() async {
    if (_checking) return;
    _checking = true;
    try {
      final internet = await _probe('https://www.gstatic.com/generate_204');
      _setOnline(internet);

      if (_supabaseUrl != null && _supabaseUrl.isNotEmpty) {
        final supabase = await _probe(_supabaseUrl);
        _setSupabaseOnline(internet && supabase);
      } else {
        _setSupabaseOnline(internet);
      }
    } finally {
      _checking = false;
    }
  }

  Future<bool> _probe(String url) async {
    if (kIsWeb) {
      // Pas de dart:io sur le web : impossible de tester, on suppose en ligne.
      return true;
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.userAgentHeader, 'pos_module-health-check');
      final response = await request.close();
      await response.drain<void>();
      // Toute réponse HTTP (même 4xx/5xx) prouve que le réseau répond.
      return response.statusCode >= 100 && response.statusCode < 600;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  void _setOnline(bool value) {
    if (_isOnline != value) {
      _isOnline = value;
      notifyListeners();
    }
  }

  void _setSupabaseOnline(bool value) {
    if (_supabaseOnline != value) {
      _supabaseOnline = value;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}