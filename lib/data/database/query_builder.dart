import 'dart:async';

typedef DatabasePredicate<T> = bool Function(T value);
typedef DatabaseComparator<T> = int Function(T a, T b);

/// 抽象的查询构建器接口，用于在不直接依赖底层数据库的前提下
/// 构建筛选、排序、分页等查询条件。
abstract class DatabaseQueryBuilder<T> {
  DatabaseQueryBuilder<T> filter(DatabasePredicate<T> predicate);

  DatabaseQueryBuilder<T> sort(DatabaseComparator<T> comparator);

  DatabaseQueryBuilder<T> limit(int value);

  DatabaseQueryBuilder<T> offset(int value);

  Future<List<T>> findAll();

  Future<T?> findFirst();
}
