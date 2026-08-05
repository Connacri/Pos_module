import 'package:objectbox/objectbox.dart';

/// Mappage entre l'ID local (ObjectBox) et l'ID distant (Supabase) d'un
/// enregistrement synchronisé.
///
/// L'ID distant est toujours l'ID canonique attribué par Supabase (pas de
/// plage d'ID propre à chaque appareil). Quand un appareil tire des lignes
/// créées ailleurs, ObjectBox leur attribue de nouveaux ID locaux : ce
/// mappage permet de retrouver la correspondance et de traduire les clés
/// étrangères (items, paiements) sans collision ni doublon. Il est aussi
/// réécrit si la ligne distante canonique change après une remise à zéro du
/// serveur.
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
