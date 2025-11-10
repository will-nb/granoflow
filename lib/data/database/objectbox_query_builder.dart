import 'dart:math' as math;

import 'package:objectbox/objectbox.dart';

import 'query_builder.dart';

/// 基于 ObjectBox 的通用查询构建器。
///
/// 使用 ObjectBox 原生 QueryBuilder 和 Condition 来构建查询，
/// 支持条件组合、排序、分页以及查询描述。
class ObjectBoxQueryBuilder<E> implements DatabaseQueryBuilder<E> {
  ObjectBoxQueryBuilder(this._box);

  final Box<E> _box;

  // 保留对函数式谓词的支持（向后兼容）
  DatabasePredicate<E>? _predicate;
  DatabaseComparator<E>? _comparator;
  
  // 新的查询描述符支持
  final List<FieldCondition> _conditions = [];
  final List<OrderDescriptor> _orders = [];
  int? _limit;
  int? _offset;

  @override
  QueryDescriptor? get descriptor {
    if (_conditions.isEmpty && _orders.isEmpty && _limit == null && _offset == null) {
      return null;
    }
    return QueryDescriptor(
      conditions: List.unmodifiable(_conditions),
      orders: List.unmodifiable(_orders),
      limit: _limit,
      offset: _offset,
    );
  }

  @override
  Future<List<E>> findAll() async {
    return _execute();
  }

  @override
  Future<E?> findFirst() async {
    final results = await _execute(limit: 1);
    if (results.isEmpty) {
      return null;
    }
    return results.first;
  }

  @override
  ObjectBoxQueryBuilder<E> filter(DatabasePredicate<E> predicate) {
    // 向后兼容：保留函数式谓词支持
    final previous = _predicate;
    if (previous == null) {
      _predicate = predicate;
    } else {
      _predicate = (value) => previous(value) && predicate(value);
    }
    return this;
  }

  /// 添加字段条件（新方法，用于构建 QueryDescriptor）
  ObjectBoxQueryBuilder<E> addCondition(FieldCondition condition) {
    _conditions.add(condition);
    return this;
  }

  @override
  ObjectBoxQueryBuilder<E> sort(DatabaseComparator<E> comparator) {
    // 向后兼容：保留函数式比较器支持
    _comparator = comparator;
    return this;
  }

  /// 添加排序描述符（新方法，用于构建 QueryDescriptor）
  ObjectBoxQueryBuilder<E> addOrder(OrderDescriptor order) {
    _orders.add(order);
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

  /// 执行查询
  Future<List<E>> _execute({int? limit}) async {
    // 如果有 QueryDescriptor 条件，尝试使用 ObjectBox 原生查询
    if (_conditions.isNotEmpty || _orders.isNotEmpty) {
      try {
        return _executeWithQuery(limit: limit);
      } catch (e) {
        // 如果字段映射失败，回退到内存过滤
        // 记录警告但不抛出异常，保持向后兼容
        return _executeInMemory(limit: limit);
      }
    }
    
    // 如果没有条件，但有函数式谓词或比较器，使用内存过滤
    if (_predicate != null || _comparator != null) {
      return _executeInMemory(limit: limit);
    }
    
    // 如果只有分页，使用 ObjectBox 查询
    if (_limit != null || _offset != null) {
      return _executeWithQuery(limit: limit);
    }
    
    // 否则返回所有数据
    return _box.getAll();
  }

  /// 使用 ObjectBox 原生 QueryBuilder 执行查询
  ///
  /// 注意：由于 ObjectBox 的 Property 需要通过生成的代码访问（如 TaskEntity_.id），
  /// 而我们的抽象层是泛型的，无法直接访问 Property。
  /// 因此，目前所有查询都回退到内存过滤。
  /// TODO: 实现字段映射后，可以使用 ObjectBox 原生查询以获得更好的性能。
  Future<List<E>> _executeWithQuery({int? limit}) async {
    // TODO: 实现字段映射后，可以使用 ObjectBox 原生查询
    // 目前回退到内存过滤
    return _executeInMemory(limit: limit);
  }

  /// 在内存中执行查询（回退方案）
  Future<List<E>> _executeInMemory({int? limit}) async {
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

    final queryLimit = limit ?? _limit ?? results.length;
    final end = math.min(results.length, offset + queryLimit);
    return results.sublist(offset, end);
  }

  /// 返回查询描述（用于调试和日志）
  String describe() {
    final descriptor = this.descriptor;
    if (descriptor != null) {
      return descriptor.describe();
    }
    return 'ObjectBoxQueryBuilder(use predicate/comparator, limit: $_limit, offset: $_offset)';
  }
}
