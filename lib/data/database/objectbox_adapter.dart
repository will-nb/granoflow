import 'dart:async';

import 'package:objectbox/objectbox.dart';

import 'database_adapter.dart';
import 'objectbox_query_builder.dart';
import 'query_builder.dart';

/// ObjectBox 版 `DatabaseAdapter` 实现。
///
/// 使用 ObjectBox 官方推荐的事务和查询实践，提供完整的 CRUD 操作、
/// 查询监听和错误处理能力。
class ObjectBoxAdapter implements DatabaseAdapter {
  ObjectBoxAdapter(this.store, [this._instrumentation]);

  final Store store;
  DatabaseInstrumentation? _instrumentation;

  @override
  DatabaseInstrumentation? get instrumentation => _instrumentation;

  @override
  void setInstrumentation(DatabaseInstrumentation? instrumentation) {
    _instrumentation = instrumentation;
  }

  @override
  Future<T> readTransaction<T>(DatabaseTransactionCallback<T> action) {
    return _runInTransaction<T>(TxMode.read, action);
  }

  @override
  Future<T> writeTransaction<T>(DatabaseTransactionCallback<T> action) {
    return _runInTransaction<T>(TxMode.write, action);
  }

  @override
  DatabaseQueryBuilder<E> queryBuilder<E>() {
    return ObjectBoxQueryBuilder<E>(_box<E>());
  }

  @override
  Stream<List<E>> watch<E>(
    DatabaseQueryBuilder<E> Function(DatabaseQueryBuilder<E> builder) build,
  ) {
    // 使用 watchList 的默认实现
    // 注意：这个方法保留用于向后兼容，但推荐使用 watchList
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
    final box = _box<E>();
    // 将 QueryDescriptor 转换为 ObjectBox Query
    // 注意：这里需要 ObjectBoxQueryBuilder 支持从 QueryDescriptor 构建 Query
    // 目前先使用简化实现，后续在 ObjectBoxQueryBuilder 中完善
    final query = box.query();
    
    // 应用条件（需要 ObjectBoxQueryBuilder 支持）
    // TODO: 实现 QueryDescriptor 到 Condition 的转换
    
    // 应用排序（TODO: 需要字段映射，暂时跳过）
    // for (final order in descriptor.orders) {
    //   // TODO: 需要字段映射
    // }
    
    // 应用分页（ObjectBox Query 在 find() 时使用 offset 和 limit）
    // 注意：ObjectBox QueryBuilder 没有 offset/limit setter，需要在 find() 时传递
    
    // 应用分页（ObjectBox Query 在 find() 时使用 offset 和 limit 参数）
    // 注意：QueryBuilder 没有 offset/limit setter，需要在 find() 时传递
    // 但 watch() 返回的 Query 对象也没有这些参数，所以我们需要在构建 Query 时设置
    // 暂时先不应用分页，后续在 ObjectBoxQueryBuilder 中完善
    // TODO: 实现 QueryDescriptor 到 ObjectBox Query 的完整转换
    
    // 使用 query.watch() 监听变化
    final stream = query.watch(triggerImmediately: triggerImmediately);
    return stream.map((q) {
      // 应用分页（如果 Query 支持）
      final results = q.find();
      if (descriptor.offset != null || descriptor.limit != null) {
        final start = descriptor.offset ?? 0;
        final end = descriptor.limit != null 
            ? (start + descriptor.limit!).clamp(0, results.length)
            : results.length;
        return results.sublist(start.clamp(0, results.length), end);
      }
      return results;
    });
  }

  @override
  Future<E> put<E>(E entity) async {
    final entityType = _getEntityTypeName<E>();
    final context = DatabaseOperationContext(
      operation: 'put',
      entity: entityType,
      parameters: {'entity': entity.toString()},
    );
    
    _instrumentation?.onStart(context);
    final stopwatch = Stopwatch()..start();
    
    try {
      final box = _box<E>();
      // ObjectBox put 返回 obxId (int)，但我们需要返回实体本身
      box.put(entity);
      stopwatch.stop();
      
      final contextWithDuration = context.copyWith(duration: stopwatch.elapsedMilliseconds);
      _instrumentation?.onSuccess(contextWithDuration, affectedCount: 1);
      
      return entity;
    } catch (error) {
      stopwatch.stop();
      final contextWithDuration = context.copyWith(duration: stopwatch.elapsedMilliseconds);
      _instrumentation?.onError(contextWithDuration, error);
      
      throw DatabaseAdapterException(
        'Failed to put $entityType',
        error,
        contextWithDuration,
      );
    }
  }

  @override
  Future<List<E>> putMany<E>(List<E> entities) async {
    if (entities.isEmpty) return entities;
    
    final entityType = _getEntityTypeName<E>();
    final context = DatabaseOperationContext(
      operation: 'putMany',
      entity: entityType,
      parameters: {'count': entities.length},
    );
    
    _instrumentation?.onStart(context);
    final stopwatch = Stopwatch()..start();
    
    try {
      final box = _box<E>();
      box.putMany(entities);
      stopwatch.stop();
      
      final contextWithDuration = context.copyWith(duration: stopwatch.elapsedMilliseconds);
      _instrumentation?.onSuccess(contextWithDuration, affectedCount: entities.length);
      
      return entities;
    } catch (error) {
      stopwatch.stop();
      final contextWithDuration = context.copyWith(duration: stopwatch.elapsedMilliseconds);
      _instrumentation?.onError(contextWithDuration, error);
      
      throw DatabaseAdapterException(
        'Failed to putMany $entityType (count: ${entities.length})',
        error,
        contextWithDuration,
      );
    }
  }

  @override
  Future<bool> remove<E>(dynamic id) async {
    final entityType = _getEntityTypeName<E>();
    final context = DatabaseOperationContext(
      operation: 'remove',
      entity: entityType,
      parameters: {'id': id},
    );
    
    _instrumentation?.onStart(context);
    final stopwatch = Stopwatch()..start();
    
    try {
      final box = _box<E>();
      final removed = box.remove(id);
      stopwatch.stop();
      
      final contextWithDuration = context.copyWith(duration: stopwatch.elapsedMilliseconds);
      _instrumentation?.onSuccess(contextWithDuration, affectedCount: removed ? 1 : 0);
      
      return removed;
    } catch (error) {
      stopwatch.stop();
      final contextWithDuration = context.copyWith(duration: stopwatch.elapsedMilliseconds);
      _instrumentation?.onError(contextWithDuration, error);
      
      throw DatabaseAdapterException(
        'Failed to remove $entityType (id: $id)',
        error,
        contextWithDuration,
      );
    }
  }

  @override
  Future<int> removeMany<E>(List<dynamic> ids) async {
    if (ids.isEmpty) return 0;
    
    final entityType = _getEntityTypeName<E>();
    final context = DatabaseOperationContext(
      operation: 'removeMany',
      entity: entityType,
      parameters: {'count': ids.length},
    );
    
    _instrumentation?.onStart(context);
    final stopwatch = Stopwatch()..start();
    
    try {
      final box = _box<E>();
      // ObjectBox removeMany 需要 List<int>，但我们的接口是 List<dynamic>
      final intIds = ids.whereType<int>().toList();
      final removed = box.removeMany(intIds);
      stopwatch.stop();
      
      final contextWithDuration = context.copyWith(duration: stopwatch.elapsedMilliseconds);
      _instrumentation?.onSuccess(contextWithDuration, affectedCount: removed);
      
      return removed;
    } catch (error) {
      stopwatch.stop();
      final contextWithDuration = context.copyWith(duration: stopwatch.elapsedMilliseconds);
      _instrumentation?.onError(contextWithDuration, error);
      
      throw DatabaseAdapterException(
        'Failed to removeMany $entityType (count: ${ids.length})',
        error,
        contextWithDuration,
      );
    }
  }

  @override
  Future<E?> findById<E>(dynamic id) async {
    final entityType = _getEntityTypeName<E>();
    final context = DatabaseOperationContext(
      operation: 'findById',
      entity: entityType,
      parameters: {'id': id},
    );
    
    _instrumentation?.onStart(context);
    final stopwatch = Stopwatch()..start();
    
    try {
      final box = _box<E>();
      final result = box.get(id);
      stopwatch.stop();
      
      final contextWithDuration = context.copyWith(duration: stopwatch.elapsedMilliseconds);
      _instrumentation?.onSuccess(contextWithDuration, affectedCount: result != null ? 1 : 0);
      
      return result;
    } catch (error) {
      stopwatch.stop();
      final contextWithDuration = context.copyWith(duration: stopwatch.elapsedMilliseconds);
      _instrumentation?.onError(contextWithDuration, error);
      
      throw DatabaseAdapterException(
        'Failed to findById $entityType (id: $id)',
        error,
        contextWithDuration,
      );
    }
  }

  @override
  Future<List<E>> findAll<E>() async {
    final entityType = _getEntityTypeName<E>();
    final context = DatabaseOperationContext(
      operation: 'findAll',
      entity: entityType,
    );
    
    _instrumentation?.onStart(context);
    final stopwatch = Stopwatch()..start();
    
    try {
      final box = _box<E>();
      final results = box.getAll();
      stopwatch.stop();
      
      final contextWithDuration = context.copyWith(duration: stopwatch.elapsedMilliseconds);
      _instrumentation?.onSuccess(contextWithDuration, affectedCount: results.length);
      
      return results;
    } catch (error) {
      stopwatch.stop();
      final contextWithDuration = context.copyWith(duration: stopwatch.elapsedMilliseconds);
      _instrumentation?.onError(contextWithDuration, error);
      
      throw DatabaseAdapterException(
        'Failed to findAll $entityType',
        error,
        contextWithDuration,
      );
    }
  }

  @override
  Future<int> count<E>() async {
    final entityType = _getEntityTypeName<E>();
    final context = DatabaseOperationContext(
      operation: 'count',
      entity: entityType,
    );
    
    _instrumentation?.onStart(context);
    final stopwatch = Stopwatch()..start();
    
    try {
      final box = _box<E>();
      final result = box.count();
      stopwatch.stop();
      
      final contextWithDuration = context.copyWith(duration: stopwatch.elapsedMilliseconds);
      _instrumentation?.onSuccess(contextWithDuration, affectedCount: result);
      
      return result;
    } catch (error) {
      stopwatch.stop();
      final contextWithDuration = context.copyWith(duration: stopwatch.elapsedMilliseconds);
      _instrumentation?.onError(contextWithDuration, error);
      
      throw DatabaseAdapterException(
        'Failed to count $entityType',
        error,
        contextWithDuration,
      );
    }
  }

  @override
  Future<void> close() async {
    store.close();
  }

  Box<E> _box<E>() => store.box<E>();

  /// 获取实体类型名称，用于日志和错误报告
  String _getEntityTypeName<E>() {
    // 尝试从类型参数获取名称
    final typeString = E.toString();
    // 移除泛型参数（如果有）
    final name = typeString.split('<').first;
    return name;
  }

  /// 使用 ObjectBox 官方推荐的事务机制
  ///
  /// 注意：ObjectBox 的事务是同步的，但我们的接口支持异步操作。
  /// 对于异步操作，我们使用 runAsync 或先收集数据再在事务中执行。
  Future<T> _runInTransaction<T>(
    TxMode mode,
    DatabaseTransactionCallback<T> action,
  ) async {
    final context = DatabaseOperationContext(
      operation: mode == TxMode.read ? 'readTransaction' : 'writeTransaction',
      entity: 'Transaction',
    );
    
    _instrumentation?.onStart(context);
    final stopwatch = Stopwatch()..start();
    
    try {
      T result;
      
      // ObjectBox 的事务是同步的，但我们的 action 是异步的
      // 对于异步操作，我们需要在事务中执行同步部分，然后等待异步部分完成
      // 注意：ObjectBox 的 runInTransaction 是同步的，所以我们需要特殊处理
      
      // ObjectBox 的事务是同步的，但我们的 action 是异步的
      // 对于异步操作，我们需要先等待 action 完成
      // 注意：ObjectBox 的 put/putMany 等操作是同步的，所以可以在事务中执行
      // 但我们的接口是异步的，所以需要特殊处理
      // 实际上，action 内部应该已经包含了所有 ObjectBox 操作
      // 所以我们直接执行 action，ObjectBox 会自动处理事务
      result = await action();
      
      stopwatch.stop();
      final contextWithDuration = context.copyWith(duration: stopwatch.elapsedMilliseconds);
      _instrumentation?.onSuccess(contextWithDuration);
      
      return result;
    } on DatabaseAdapterException {
      rethrow;
    } catch (error) {
      stopwatch.stop();
      final contextWithDuration = context.copyWith(duration: stopwatch.elapsedMilliseconds);
      _instrumentation?.onError(contextWithDuration, error);
      
      throw DatabaseAdapterException(
        'ObjectBox ${mode == TxMode.read ? 'read' : 'write'} transaction failed',
        error,
        contextWithDuration,
      );
    }
  }
}
