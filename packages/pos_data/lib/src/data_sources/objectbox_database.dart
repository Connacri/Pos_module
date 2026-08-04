import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../objectbox.g.dart';

class ObjectboxDatabase {
  ObjectboxDatabase._();

  static Store? _store;

  static Store get store {
    final s = _store;
    if (s == null) {
      throw StateError('ObjectboxDatabase.open() doit être appelé avant toute utilisation');
    }
    return s;
  }

  static bool get isOpen => _store != null;

  static Future<void> open() async {
    if (_store != null) return;
    final dir = await getApplicationDocumentsDirectory();
    _store = await openStore(directory: p.join(dir.path, 'objectbox'));
  }

  static Box<T> box<T>() => store.box<T>();

  /// Hook de test : remplace le store partagé (par exemple un store en
  /// mémoire ou dans un répertoire temporaire).
  static void useStoreForTesting(Store store) {
    _store = store;
  }

  static void close() {
    _store?.close();
    _store = null;
  }
}
