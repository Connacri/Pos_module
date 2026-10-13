import 'dart:async';

/// Annotations ObjectBox standard
class Entity {
  final int? uid;
  const Entity({this.uid});
}

class Id {
  final bool assignable;
  final int? uid;
  const Id({this.assignable = false, this.uid});
}

class Index {
  final int? uid;
  const Index({this.uid});
}

class Transient {
  const Transient();
}

class Property {
  final int? uid;
  final int? type;
  const Property({this.uid, this.type});
}

enum PutMode { put, insert, update }

typedef ConditionPredicate<T> = bool Function(T item);

abstract class Condition<T> {
  bool test(T item);
}

class _PredicateCondition<T> extends Condition<T> {
  final ConditionPredicate<T> predicate;
  _PredicateCondition(this.predicate);

  @override
  bool test(T item) => predicate(item);
}

/// Propriétés pour les requêtes typées ObjectBox
class QueryProperty<EntityT, ValueT> {
  final int propertyId;
  final String name;
  final ValueT? Function(EntityT entity) getter;

  const QueryProperty(this.propertyId, this.name, this.getter);
}

class QueryStringProperty<EntityT> extends QueryProperty<EntityT, String> {
  const QueryStringProperty(super.propertyId, super.name, super.getter);

  Condition<EntityT> equals(String value, {bool caseSensitive = true}) {
    return _PredicateCondition<EntityT>((entity) {
      final v = getter(entity);
      if (v == null) return false;
      if (!caseSensitive) {
        return v.toLowerCase() == value.toLowerCase();
      }
      return v == value;
    });
  }

  Condition<EntityT> contains(String value, {bool caseSensitive = false}) {
    return _PredicateCondition<EntityT>((entity) {
      final v = getter(entity);
      if (v == null) return false;
      if (!caseSensitive) {
        return v.toLowerCase().contains(value.toLowerCase());
      }
      return v.contains(value);
    });
  }
}

class QueryIntegerProperty<EntityT> extends QueryProperty<EntityT, int> {
  const QueryIntegerProperty(super.propertyId, super.name, super.getter);

  Condition<EntityT> equals(int value) {
    return _PredicateCondition<EntityT>((entity) => getter(entity) == value);
  }

  Condition<EntityT> notEquals(int value) {
    return _PredicateCondition<EntityT>((entity) => getter(entity) != value);
  }

  Condition<EntityT> greaterThan(int value) {
    return _PredicateCondition<EntityT>((entity) {
      final v = getter(entity);
      return v != null && v > value;
    });
  }

  Condition<EntityT> lessThan(int value) {
    return _PredicateCondition<EntityT>((entity) {
      final v = getter(entity);
      return v != null && v < value;
    });
  }
}

class QueryDoubleProperty<EntityT> extends QueryProperty<EntityT, double> {
  const QueryDoubleProperty(super.propertyId, super.name, super.getter);

  Condition<EntityT> equals(double value) {
    return _PredicateCondition<EntityT>((entity) => getter(entity) == value);
  }

  Condition<EntityT> lessThan(double value) {
    return _PredicateCondition<EntityT>((entity) {
      final v = getter(entity);
      return v != null && v < value;
    });
  }

  Condition<EntityT> lessOrEqual(double value) {
    return _PredicateCondition<EntityT>((entity) {
      final v = getter(entity);
      return v != null && v <= value;
    });
  }

  Condition<EntityT> greaterThan(double value) {
    return _PredicateCondition<EntityT>((entity) {
      final v = getter(entity);
      return v != null && v > value;
    });
  }
}

class QueryBooleanProperty<EntityT> extends QueryProperty<EntityT, bool> {
  const QueryBooleanProperty(super.propertyId, super.name, super.getter);

  Condition<EntityT> equals(bool value) {
    return _PredicateCondition<EntityT>((entity) => getter(entity) == value);
  }
}

class QueryDateProperty<EntityT> extends QueryProperty<EntityT, DateTime> {
  const QueryDateProperty(super.propertyId, super.name, super.getter);

  Condition<EntityT> betweenDate(DateTime start, DateTime end) {
    return _PredicateCondition<EntityT>((entity) {
      final v = getter(entity);
      if (v == null) return false;
      return (v.isAfter(start) || v.isAtSameMomentAs(start)) &&
          (v.isBefore(end) || v.isAtSameMomentAs(end));
    });
  }
}

/// Requête ObjectBox avec exécution et écoute réactive
class Query<T> {
  final Box<T> _box;
  final Condition<T>? _condition;

  Query(this._box, this._condition);

  List<T> find() {
    final all = _box.getAll();
    if (_condition == null) return all;
    return all.where((item) => _condition.test(item)).toList();
  }

  T? findFirst() {
    final list = find();
    return list.isNotEmpty ? list.first : null;
  }

  int remove() {
    final items = find();
    var count = 0;
    for (final item in items) {
      final id = _box._getId(item);
      if (id != null && _box.remove(id)) {
        count++;
      }
    }
    return count;
  }

  int count() => find().length;
}

class QueryBuilder<T> {
  final Box<T> _box;
  final Condition<T>? _condition;

  QueryBuilder(this._box, [this._condition]);

  Query<T> build() => Query<T>(_box, _condition);

  Stream<Query<T>> watch({bool triggerImmediately = true}) {
    late StreamController<Query<T>> controller;
    StreamSubscription? sub;

    controller = StreamController<Query<T>>(
      onListen: () {
        if (triggerImmediately) {
          controller.add(build());
        }
        sub = _box._changeStream.listen((_) {
          controller.add(build());
        });
      },
      onCancel: () {
        sub?.cancel();
      },
    );

    return controller.stream;
  }
}

/// Boîte de données ObjectBox
class Box<T> {
  final Map<int, T> _storage = {};
  int _autoIncrementId = 0;
  final StreamController<void> _changeController =
      StreamController<void>.broadcast();

  Stream<void> get _changeStream => _changeController.stream;

  int? _getId(T entity) {
    try {
      final dynamic dyn = entity;
      return dyn.id as int;
    } catch (_) {
      return null;
    }
  }

  void _setId(T entity, int id) {
    try {
      final dynamic dyn = entity;
      dyn.id = id;
    } catch (_) {}
  }

  int put(T entity, {PutMode mode = PutMode.put}) {
    int id = _getId(entity) ?? 0;
    if (id <= 0) {
      _autoIncrementId++;
      id = _autoIncrementId;
      _setId(entity, id);
    } else {
      if (id > _autoIncrementId) {
        _autoIncrementId = id;
      }
    }
    _storage[id] = entity;
    _changeController.add(null);
    return id;
  }

  List<int> putMany(List<T> entities, {PutMode mode = PutMode.put}) {
    final ids = <int>[];
    for (final entity in entities) {
      ids.add(put(entity, mode: mode));
    }
    return ids;
  }

  T? get(int id) => _storage[id];

  List<T> getAll() => List<T>.from(_storage.values);

  List<T> getMany(List<int> ids) {
    return ids.map((id) => _storage[id]).whereType<T>().toList();
  }

  bool remove(int id) {
    final removed = _storage.remove(id) != null;
    if (removed) {
      _changeController.add(null);
    }
    return removed;
  }

  int removeMany(List<int> ids) {
    var count = 0;
    for (final id in ids) {
      if (_storage.remove(id) != null) count++;
    }
    if (count > 0) {
      _changeController.add(null);
    }
    return count;
  }

  int removeAll() {
    final count = _storage.length;
    _storage.clear();
    if (count > 0) {
      _changeController.add(null);
    }
    return count;
  }

  int count({int limit = 0}) => _storage.length;

  bool isEmpty() => _storage.isEmpty;

  QueryBuilder<T> query([Condition<T>? condition]) {
    return QueryBuilder<T>(this, condition);
  }
}

/// Entrepôt de stockage principal ObjectBox
class Store {
  final Map<Type, Box<dynamic>> _boxes = {};
  bool _isClosed = false;

  bool get isClosed => _isClosed;

  Box<T> box<T>() {
    if (_isClosed) throw StateError('Store est fermé');
    return _boxes.putIfAbsent(T, () => Box<T>()) as Box<T>;
  }

  void close() {
    _isClosed = true;
    _boxes.clear();
  }
}

Future<Store> openStore({String? directory}) async {
  return Store();
}
