import 'dart:math' as math;

import 'package:objectbox/objectbox.dart';

import 'query_builder.dart';

/// 基于 ObjectBox 的通用查询构建器。
///
/// 由于当前抽象层使用函数式谓词与比较器，
/// 这里通过在内存中对 `Box` 的数据进行筛选与排序实现最小可行能力。
class ObjectBoxQueryBuilder<E> implements DatabaseQueryBuilder<E> {
  ObjectBoxQueryBuilder(this._box);

  final Box<E> _box;

  DatabasePredicate<E>? _predicate;
  DatabaseComparator<E>? _comparator;
  int? _limit;
  int? _offset;

  @override
  Future<List<E>> findAll() async {
    return _execute();
  }

  @override
  Future<E?> findFirst() async {
    final results = await _execute();
    if (results.isEmpty) {
      return null;
    }
    return results.first;
  }

  @override
  ObjectBoxQueryBuilder<E> filter(DatabasePredicate<E> predicate) {
    final previous = _predicate;
    if (previous == null) {
      _predicate = predicate;
    } else {
      _predicate = (value) => previous(value) && predicate(value);
    }
    return this;
  }

  @override
  ObjectBoxQueryBuilder<E> sort(DatabaseComparator<E> comparator) {
    _comparator = comparator;
    return this;
  }

  @override
  ObjectBoxQueryBuilder<E> limit(int value) {
    _limit = value < 0 ? null : value;
    return this;
  }

  @override
  ObjectBoxQueryBuilder<E> offset(int value) {
    _offset = value < 0 ? 0 : value;
    return this;
  }

  Future<List<E>> _execute() async {
    final data = _box.getAll();
    var results = _predicate == null
        ? List<E>.from(data)
        : data.where(_predicate!).toList();

    final comparator = _comparator;
    if (comparator != null) {
      results.sort(comparator);
    }

    final offset = _offset ?? 0;
    if (offset >= results.length) {
      return <E>[];
    }

    final limit = _limit ?? results.length;
    final end = math.min(results.length, offset + limit);
    return results.sublist(offset, end);
  }
}
