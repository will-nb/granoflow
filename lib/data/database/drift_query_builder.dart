import 'query_builder.dart';

/// 基于 Drift 的类型安全查询构建器。
///
/// 使用 Drift 的类型安全 API 来构建查询，
/// 支持条件组合、排序、分页以及查询描述。
class DriftQueryBuilder<E> implements DatabaseQueryBuilder<E> {
  DriftQueryBuilder();

  // 保留对函数式谓词的支持（向后兼容）
  DatabasePredicate<E>? _predicate;
  // TODO: 在阶段 2 实现，保留对函数式比较器的支持（向后兼容）
  // ignore: unused_field
  DatabaseComparator<E>? _comparator;

  // 新的查询描述符支持
  final List<FieldCondition> _conditions = [];
  final List<OrderDescriptor> _orders = [];
  int? _limit;
  int? _offset;

  @override
  QueryDescriptor? get descriptor {
    if (_conditions.isEmpty &&
        _orders.isEmpty &&
        _limit == null &&
        _offset == null) {
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
    // TODO: 在阶段 2 实现，使用 Drift 的类型安全查询 API
    // 将 FieldCondition 转换为 Drift 的 where() 条件
    // 将 OrderDescriptor 转换为 Drift 的 orderBy() 方法
    throw UnimplementedError('findAll will be implemented in stage 2');
  }

  @override
  Future<E?> findFirst() async {
    // TODO: 在阶段 2 实现，使用 Drift 的类型安全查询 API
    final results = await findAll();
    if (results.isEmpty) {
      return null;
    }
    return results.first;
  }

  @override
  DriftQueryBuilder<E> filter(DatabasePredicate<E> predicate) {
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
  DriftQueryBuilder<E> addCondition(FieldCondition condition) {
    _conditions.add(condition);
    return this;
  }

  @override
  DriftQueryBuilder<E> sort(DatabaseComparator<E> comparator) {
    // TODO: 在阶段 2 实现，向后兼容：保留函数式比较器支持
    _comparator = comparator;
    return this;
  }

  /// 添加排序描述符（新方法，用于构建 QueryDescriptor）
  DriftQueryBuilder<E> addOrder(OrderDescriptor order) {
    _orders.add(order);
    return this;
  }

  @override
  DriftQueryBuilder<E> limit(int value) {
    _limit = value < 0 ? null : value;
    return this;
  }

  @override
  DriftQueryBuilder<E> offset(int value) {
    _offset = value < 0 ? 0 : value;
    return this;
  }

  /// 返回查询描述（用于调试和日志）
  String describe() {
    final descriptor = this.descriptor;
    if (descriptor != null) {
      return descriptor.describe();
    }
    return 'DriftQueryBuilder(use predicate/comparator, limit: $_limit, offset: $_offset)';
  }
}
