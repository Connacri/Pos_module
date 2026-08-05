import 'package:objectbox/objectbox.dart';

/// Mappage entre l'ID local (ObjectBox) et l'ID distant (Supabase) d'un
/// enregistrement synchronisé.
///
/// L'ID distant d'un appareil est `deviceId * [_remoteIdSpace] + idLocal`.
/// Quand un autre appareil tire ces lignes, ObjectBox leur attribue de nouveaux
/// ID locaux : ce mappage permet de retrouver la correspondance et de traduire
/// les clés étrangères (items, paiements) sans collision ni doublon.
@Entity()
class SyncIdEntity {
  @Id()
  int id = 0;

  /// Type d'entité : 'product', 'category', 'customer', 'sale', 'invoice',
  /// 'payment', 'return'.
  @Index()
  String entityType = '';

  /// ID de la ligne sur Supabase.
  @Index()
  int remoteId = 0;

  /// ID de la ligne dans ObjectBox.
  int localId = 0;
}
