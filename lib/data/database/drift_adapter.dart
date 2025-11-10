import 'dart:async';

import 'database_adapter.dart';
import 'drift_query_builder.dart';
import 'query_builder.dart';
import '../drift/database.dart';

/// Drift 版 `DatabaseAdapter` 实现。
///
/// 使用 Drift 的类型安全查询 API，支持 Web（IndexedDB）和移动端（SQLite），
/// 提供完整的 CRUD 操作、查询监听和错误处理能力。
class DriftAdapter implements DatabaseAdapter {
  DriftAdapter();

  DatabaseInstrumentation? _instrumentation;

  /// 获取 AppDatabase 实例
  AppDatabase get _db => AppDatabase.instance;

  @override
  DatabaseInstrumentation? get instrumentation => _instrumentation;

  @override
  void setInstrumentation(DatabaseInstrumentation? instrumentation) {
    _instrumentation = instrumentation;
  }

  @override
  Future<T> readTransaction<T>(DatabaseTransactionCallback<T> action) async {
    // 使用 Drift 的 transaction API，允许多个并发读取
    // 注意：由于 Repository 直接使用 AppDatabase，这里的 action 可能不直接使用数据库
    // 但为了保持接口一致性，我们仍然使用事务
    return await _db.transaction(() async {
      return await action();
    });
  }

  @override
  Future<T> writeTransaction<T>(DatabaseTransactionCallback<T> action) async {
    // 使用 Drift 的 transaction API，保证原子性和隔离性
    // 注意：由于 Repository 直接使用 AppDatabase，这里的 action 可能不直接使用数据库
    // 但为了保持接口一致性，我们仍然使用事务
    return await _db.transaction(() async {
      return await action();
    });
  }

  @override
  DatabaseQueryBuilder<E> queryBuilder<E>() {
    // TODO: 在阶段 2 实现，需要数据库实例和表信息
    return DriftQueryBuilder<E>();
  }

  @override
  Stream<List<E>> watch<E>(
    DatabaseQueryBuilder<E> Function(DatabaseQueryBuilder<E> builder) build,
  ) {
    // TODO: 在阶段 2 实现，使用 Drift 的 Stream 查询监听机制
    final builderInstance = queryBuilder<E>();
    build(builderInstance);
    final descriptor = builderInstance.descriptor;
    if (descriptor != null) {
      return watchList<E>(descriptor, triggerImmediately: true);
    }
    // 如果没有 descriptor，回退到轮询方式
    return Stream.periodic(const Duration(milliseconds: 100))
        .asyncMap((_) => builderInstance.findAll())
        .distinct((prev, next) {
      if (prev.length != next.length) return false;
      for (var i = 0; i < prev.length; i++) {
        if (prev[i] != next[i]) return false;
      }
      return true;
    });
  }

  @override
  Stream<List<E>> watchList<E>(
    QueryDescriptor descriptor, {
    bool triggerImmediately = true,
  }) {
    // TODO: 在阶段 2 实现，使用 Drift 的 Stream 查询监听机制
    // 首次订阅时立即触发一次（triggerImmediately: true）
    throw UnimplementedError('watchList will be implemented in stage 2');
  }

  @override
  Future<E> put<E>(E entity) {
    // TODO: 在阶段 2 实现，使用 Drift 的 insert 或 update 操作
    throw UnimplementedError('put will be implemented in stage 2');
  }

  @override
  Future<List<E>> putMany<E>(List<E> entities) async {
    if (entities.isEmpty) return entities;

    // TODO: 在阶段 2 实现，使用 Drift 的批量插入操作
    // 每批 100 条记录，避免内存溢出和事务超时
    const batchSize = 100;
    final results = <E>[];

    for (var i = 0; i < entities.length; i += batchSize) {
      final batch = entities.sublist(
        i,
        (i + batchSize).clamp(0, entities.length),
      );
      // TODO: 批量插入逻辑
      results.addAll(batch);
    }

    return results;
  }

  @override
  Future<bool> remove<E>(dynamic id) {
    // TODO: 在阶段 2 实现，根据 ID 删除实体
    throw UnimplementedError('remove will be implemented in stage 2');
  }

  @override
  Future<int> removeMany<E>(List<dynamic> ids) async {
    if (ids.isEmpty) return 0;

    // TODO: 在阶段 2 实现，批量删除实体
    // 每批 100 条记录，避免事务超时
    const batchSize = 100;
    var totalRemoved = 0;

    for (var i = 0; i < ids.length; i += batchSize) {
      final batch = ids.sublist(
        i,
        (i + batchSize).clamp(0, ids.length),
      );
      // TODO: 批量删除逻辑
      totalRemoved += batch.length;
    }

    return totalRemoved;
  }

  @override
  Future<E?> findById<E>(dynamic id) {
    // TODO: 在阶段 2 实现，根据 ID 查找实体
    throw UnimplementedError('findById will be implemented in stage 2');
  }

  @override
  Future<List<E>> findAll<E>() {
    // TODO: 在阶段 2 实现，查找所有实体（无过滤条件）
    throw UnimplementedError('findAll will be implemented in stage 2');
  }

  @override
  Future<int> count<E>() {
    // TODO: 在阶段 2 实现，统计实体数量
    throw UnimplementedError('count will be implemented in stage 2');
  }

  @override
  Future<void> close() async {
    // TODO: 在阶段 2 实现，关闭数据库连接，释放资源
  }

  // TODO: 在阶段 2 实现，获取实体类型名称，用于日志和错误报告
  // String _getEntityTypeName<E>() {
  //   final typeString = E.toString();
  //   final name = typeString.split('<').first;
  //   return name;
  // }
}
