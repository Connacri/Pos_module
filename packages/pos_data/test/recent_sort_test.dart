import 'package:flutter_test/flutter_test.dart';

import 'package:pos_data/src/utils/recent_sort.dart';

class _Item {
  _Item(this.id, {this.updatedAt});

  final int id;
  final DateTime? updatedAt;
}
void main() {
  test('tri le plus récent d\'abord', () {
    final items = [
      _Item(1, updatedAt: DateTime(2024, 1, 1)),
      _Item(2, updatedAt: DateTime(2024, 1, 3)),
      _Item(3, updatedAt: DateTime(2024, 1, 2)),
    ];
    final sorted = items
        .sortedByRecent(
          id: (e) => e.id,
          createdAt: (_) => null,
          updatedAt: (e) => e.updatedAt,
        )
        .map((e) => e.id)
        .toList();
    expect(sorted, [2, 3, 1]);
  });

  test('départage les dates égales par id descendant', () {
    final items = [
      _Item(1, updatedAt: DateTime(2024, 1, 1)),
      _Item(2, updatedAt: DateTime(2024, 1, 1)),
      _Item(3, updatedAt: DateTime(2024, 1, 1)),
    ];
    final sorted = items
        .sortedByRecent(
          id: (e) => e.id,
          createdAt: (_) => null,
          updatedAt: (e) => e.updatedAt,
        )
        .map((e) => e.id)
        .toList();
    expect(sorted, [3, 2, 1]);
  });

  test('sans dates, tri par id descendant', () {
    final items = [_Item(1), _Item(2), _Item(3)];
    final sorted = items
        .sortedByRecent(
          id: (e) => e.id,
          createdAt: (_) => null,
          updatedAt: (e) => e.updatedAt,
        )
        .map((e) => e.id)
        .toList();
    expect(sorted, [3, 2, 1]);
  });
}
