import 'dart:async';

typedef DatabasePredicate<T> = bool Function(T value);
typedef DatabaseComparator<T> = int Function(T a, T b);

/// 字段条件描述符，用于描述查询条件
class FieldCondition {
  FieldCondition({
    required this.field,
    required this.operator,
    required this.value,
  });

  /// 字段名称
  final String field;

  /// 操作符：equals, notEquals, greaterThan, lessThan, between, contains, startsWith
  final String operator;

  /// 值（可以是单个值或列表，取决于操作符）
  final dynamic value;

  @override
  String toString() => 'FieldCondition(field: $field, operator: $operator, value: $value)';
}

/// 排序描述符
class OrderDescriptor {
  OrderDescriptor({
    required this.field,
    this.descending = false,
  });

  /// 字段名称
  final String field;

  /// 是否降序
  final bool descending;

  @override
  String toString() => 'OrderDescriptor(field: $field, descending: $descending)';
}

/// 查询描述符，用于描述完整的查询条件
class QueryDescriptor {
  QueryDescriptor({
    this.conditions = const [],
    this.orders = const [],
    this.limit,
    this.offset,
  });

  /// 查询条件列表
  final List<FieldCondition> conditions;

  /// 排序列表
  final List<OrderDescriptor> orders;

  /// 限制返回数量
  final int? limit;

  /// 偏移量
  final int? offset;

  /// 返回查询条件的结构化描述，用于日志和调试
  String describe() {
    final buffer = StringBuffer('QueryDescriptor(');
    if (conditions.isNotEmpty) {
      buffer.write('conditions: ${conditions.map((c) => c.toString()).join(", ")}, ');
    }
    if (orders.isNotEmpty) {
      buffer.write('orders: ${orders.map((o) => o.toString()).join(", ")}, ');
    }
    if (limit != null) {
      buffer.write('limit: $limit, ');
    }
    if (offset != null) {
      buffer.write('offset: $offset, ');
    }
    buffer.write(')');
    return buffer.toString();
  }

  /// 转换为 JSON Map，便于序列化
  Map<String, dynamic> toJson() {
    return {
      'conditions': conditions.map((c) => {
            'field': c.field,
            'operator': c.operator,
            'value': c.value,
          }).toList(),
      'orders': orders.map((o) => {
            'field': o.field,
            'descending': o.descending,
          }).toList(),
      'limit': limit,
      'offset': offset,
    };
  }
}

/// 抽象的查询构建器接口，用于在不直接依赖底层数据库的前提下
/// 构建筛选、排序、分页等查询条件。
abstract class DatabaseQueryBuilder<T> {
  DatabaseQueryBuilder<T> filter(DatabasePredicate<T> predicate);

  DatabaseQueryBuilder<T> sort(DatabaseComparator<T> comparator);

  DatabaseQueryBuilder<T> limit(int value);

  DatabaseQueryBuilder<T> offset(int value);

  Future<List<T>> findAll();

  Future<T?> findFirst();

  /// 返回查询描述符（如果支持）
  QueryDescriptor? get descriptor => null;
}
