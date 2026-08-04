import 'package:flutter/material.dart';

/// Colonne de l'en-tête triable d'une liste.
class SortableListColumn {
  const SortableListColumn({
    required this.label,
    required this.key,
    this.flex = 1,
    this.align = TextAlign.start,
    this.padding = EdgeInsets.zero,
  });

  final String label;
  final String key;
  final int flex;
  final TextAlign align;
  final EdgeInsetsGeometry padding;
}

/// En-tête de liste triable.
///
/// La colonne active change de dimension (police plus grande, gras, flèche de
/// tri) et chaque colonne peut être cliquée pour trier ou inverser le tri.
class SortableListHeader extends StatelessWidget {
  const SortableListHeader({
    super.key,
    required this.columns,
    required this.sortKey,
    required this.ascending,
    required this.onSort,
  });

  final List<SortableListColumn> columns;
  final String sortKey;
  final bool ascending;
  final void Function(String key, bool ascending) onSort;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          for (final column in columns)
            Expanded(
              flex: column.flex,
              child: _ColumnHeader(
                column: column,
                active: column.key == sortKey,
                ascending: ascending,
                theme: theme,
                onTap: () {
                  if (column.key == sortKey) {
                    onSort(column.key, !ascending);
                  } else {
                    onSort(column.key, true);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({
    required this.column,
    required this.active,
    required this.ascending,
    required this.theme,
    required this.onTap,
  });

  final SortableListColumn column;
  final bool active;
  final bool ascending;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = active
        ? theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
            fontSize: (theme.textTheme.labelMedium?.fontSize ?? 12) + 1.5,
          )
        : theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          );

    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            column.label,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (active) ...[
          const SizedBox(width: 4),
          Icon(
            ascending ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: theme.colorScheme.primary,
          ),
        ],
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: column.padding,
        child: Align(alignment: _toAlignment(column.align), child: label),
      ),
    );
  }
}

Alignment _toAlignment(TextAlign align) {
  return switch (align) {
    TextAlign.center => Alignment.center,
    TextAlign.end || TextAlign.right => Alignment.centerRight,
    _ => Alignment.centerLeft,
  };
}

/// Trie une liste selon la clé et le sens demandés.
///
/// `selector` extrait la valeur comparable (nullable) à comparer pour chaque
/// élément. Les éléments sans valeur vont en fin de liste.
List<T> sortByKey<T>(
  List<T> items,
  String key,
  bool ascending,
  Comparable? Function(T item) selector,
) {
  final list = List<T>.from(items);
  list.sort((a, b) {
    final av = selector(a);
    final bv = selector(b);
    if (av == null && bv == null) return 0;
    if (av == null) return ascending ? 1 : -1;
    if (bv == null) return ascending ? -1 : 1;
    final c = av.compareTo(bv);
    return ascending ? c : -c;
  });
  return list;
}
