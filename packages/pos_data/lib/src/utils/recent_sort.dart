/// Trie les entités de la plus récente à la plus ancienne : la modification
/// (ou la création) remonte l'élément en tête de liste.
///
/// Ordre de priorité : `updatedAt` (desc), puis `createdAt` (desc), puis
/// `id` (desc) pour départager les éléments sans date.
extension RecentSort<T> on Iterable<T> {
  Iterable<T> sortedByRecent({
    required int Function(T item) id,
    required DateTime? Function(T item) createdAt,
    required DateTime? Function(T item) updatedAt,
  }) {
    final list = toList();
    list.sort((a, b) {
      final at = updatedAt(a) ?? createdAt(a);
      final bt = updatedAt(b) ?? createdAt(b);
      if (at == null && bt == null) return id(b).compareTo(id(a));
      if (at == null) return 1;
      if (bt == null) return -1;
      final byDate = bt.compareTo(at);
      if (byDate != 0) return byDate;
      return id(b).compareTo(id(a));
    });
    return list;
  }
}
