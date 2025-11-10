import 'dart:async';

import '../../lib/data/database/database_adapter.dart';
import '../../lib/data/database/query_builder.dart';

/// 内存数据库适配器，用于测试和验证抽象层。
///
/// 实现 DatabaseAdapter 接口，将所有数据存储在内存中，不依赖任何外部数据库。
/// 主要用于：
/// - 单元测试中替代 ObjectBoxAdapter，避免需要真实的数据库实例
/// - 验证仓储层仅依赖 DatabaseAdapter 抽象，不直接使用 Store/Box
/// - 为未来切换到 Drift 等 SQL 数据库做准备
class InMemoryDatabaseAdapter implements DatabaseAdapter {
  InMemoryDatabaseAdapter([this._instrumentation]);

  DatabaseInstrumentation? _instrumentation;

  @override
  DatabaseInstrumentation? get instrumentation => _instrumentation;

  @override
  void setInstrumentation(DatabaseInstrumentation? instrumentation) {
    _instrumentation = instrumentation;
  }

  // 使用 Map<Type, Map<dynamic, dynamic>> 存储实体
  // 外层 Map 的 key 是实体类型，内层 Map 的 key 是实体的 ID
  final Map<Type, Map<dynamic, dynamic>> _storage = {};

  // 用于生成自增 ID（当实体没有 ID 时）
  final Map<Type, int> _idCounters = {};

  // 用于 watch 的 StreamController
  final Map<Type, StreamController<List<dynamic>>> _watchControllers = {};

  @override
  Future<T> readTransaction<T>(DatabaseTransactionCallback<T> action) async {
    // 内存实现中，读取操作不需要特殊的事务处理
    return await action();
  }

  @override
  Future<T> writeTransaction<T>(DatabaseTransactionCallback<T> action) async {
    // 内存实现中，写入操作不需要特殊的事务处理
    // 但我们可以在这里添加一些验证逻辑
    return await action();
  }

  @override
  Future<E> put<E>(E entity) async {
    final context = DatabaseOperationContext(
      operation: 'put',
      entity: _getEntityTypeName<E>(),
      parameters: {'entity': entity.toString()},
    );

    _instrumentation?.onStart(context);
    final startTime = DateTime.now();

    try {
      final type = E;
      if (!_storage.containsKey(type)) {
        _storage[type] = {};
      }

      // 尝试获取实体的 ID（假设实体有 id 字段）
      final id = _getEntityId(entity);
      if (id == null) {
        // 如果没有 ID，生成一个
        final counter = _idCounters.putIfAbsent(type, () => 0);
        _idCounters[type] = counter + 1;
        _setEntityId(entity, counter);
      }

      final entityId = _getEntityId(entity)!;
      _storage[type]![entityId] = entity;

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      _instrumentation?.onSuccess(
        context.copyWith(duration: duration),
        affectedCount: 1,
      );

      // 通知 watch 订阅者
      _notifyWatchers<E>();

      return entity;
    } catch (e) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      _instrumentation?.onError(context.copyWith(duration: duration), e);
      throw DatabaseAdapterException(
        'Failed to put entity: $e',
        e,
        context,
      );
    }
  }

  @override
  Future<List<E>> putMany<E>(List<E> entities) async {
    final context = DatabaseOperationContext(
      operation: 'putMany',
      entity: _getEntityTypeName<E>(),
      parameters: {'count': entities.length},
    );

    _instrumentation?.onStart(context);
    final startTime = DateTime.now();

    try {
      for (final entity in entities) {
        await put<E>(entity);
      }

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      _instrumentation?.onSuccess(
        context.copyWith(duration: duration),
        affectedCount: entities.length,
      );

      return entities;
    } catch (e) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      _instrumentation?.onError(context.copyWith(duration: duration), e);
      throw DatabaseAdapterException(
        'Failed to putMany entities: $e',
        e,
        context,
      );
    }
  }

  @override
  Future<bool> remove<E>(dynamic id) async {
    final context = DatabaseOperationContext(
      operation: 'remove',
      entity: _getEntityTypeName<E>(),
      parameters: {'id': id},
    );

    _instrumentation?.onStart(context);
    final startTime = DateTime.now();

    try {
      final type = E;
      if (!_storage.containsKey(type)) {
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        _instrumentation?.onSuccess(
          context.copyWith(duration: duration),
          affectedCount: 0,
        );
        return false;
      }

      final removed = _storage[type]!.remove(id) != null;

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      _instrumentation?.onSuccess(
        context.copyWith(duration: duration),
        affectedCount: removed ? 1 : 0,
      );

      if (removed) {
        _notifyWatchers<E>();
      }

      return removed;
    } catch (e) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      _instrumentation?.onError(context.copyWith(duration: duration), e);
      throw DatabaseAdapterException(
        'Failed to remove entity: $e',
        e,
        context,
      );
    }
  }

  @override
  Future<int> removeMany<E>(List<dynamic> ids) async {
    final context = DatabaseOperationContext(
      operation: 'removeMany',
      entity: _getEntityTypeName<E>(),
      parameters: {'count': ids.length},
    );

    _instrumentation?.onStart(context);
    final startTime = DateTime.now();

    try {
      int removed = 0;
      for (final id in ids) {
        if (await remove<E>(id)) {
          removed++;
        }
      }

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      _instrumentation?.onSuccess(
        context.copyWith(duration: duration),
        affectedCount: removed,
      );

      return removed;
    } catch (e) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      _instrumentation?.onError(context.copyWith(duration: duration), e);
      throw DatabaseAdapterException(
        'Failed to removeMany entities: $e',
        e,
        context,
      );
    }
  }

  @override
  Future<E?> findById<E>(dynamic id) async {
    final context = DatabaseOperationContext(
      operation: 'findById',
      entity: _getEntityTypeName<E>(),
      parameters: {'id': id},
    );

    _instrumentation?.onStart(context);
    final startTime = DateTime.now();

    try {
      final type = E;
      if (!_storage.containsKey(type)) {
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        _instrumentation?.onSuccess(
          context.copyWith(duration: duration),
          affectedCount: 0,
        );
        return null;
      }

      final entity = _storage[type]![id] as E?;

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      _instrumentation?.onSuccess(
        context.copyWith(duration: duration),
        affectedCount: entity != null ? 1 : 0,
      );

      return entity;
    } catch (e) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      _instrumentation?.onError(context.copyWith(duration: duration), e);
      throw DatabaseAdapterException(
        'Failed to findById: $e',
        e,
        context,
      );
    }
  }

  @override
  Future<List<E>> findAll<E>() async {
    final context = DatabaseOperationContext(
      operation: 'findAll',
      entity: _getEntityTypeName<E>(),
    );

    _instrumentation?.onStart(context);
    final startTime = DateTime.now();

    try {
      final type = E;
      if (!_storage.containsKey(type)) {
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        _instrumentation?.onSuccess(
          context.copyWith(duration: duration),
          affectedCount: 0,
        );
        return <E>[];
      }

      final entities = _storage[type]!.values.cast<E>().toList();

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      _instrumentation?.onSuccess(
        context.copyWith(duration: duration),
        affectedCount: entities.length,
      );

      return entities;
    } catch (e) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      _instrumentation?.onError(context.copyWith(duration: duration), e);
      throw DatabaseAdapterException(
        'Failed to findAll: $e',
        e,
        context,
      );
    }
  }

  @override
  Future<int> count<E>() async {
    final context = DatabaseOperationContext(
      operation: 'count',
      entity: _getEntityTypeName<E>(),
    );

    _instrumentation?.onStart(context);
    final startTime = DateTime.now();

    try {
      final type = E;
      if (!_storage.containsKey(type)) {
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        _instrumentation?.onSuccess(
          context.copyWith(duration: duration),
          affectedCount: 0,
        );
        return 0;
      }

      final count = _storage[type]!.length;

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      _instrumentation?.onSuccess(
        context.copyWith(duration: duration),
        affectedCount: count,
      );

      return count;
    } catch (e) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      _instrumentation?.onError(context.copyWith(duration: duration), e);
      throw DatabaseAdapterException(
        'Failed to count: $e',
        e,
        context,
      );
    }
  }

  @override
  Stream<List<E>> watch<E>(
    DatabaseQueryBuilder<E> Function(DatabaseQueryBuilder<E> builder) buildQuery,
  ) {
    // 内存实现中，watch 使用简单的轮询机制
    // 注意：这不是最优实现，但对于测试来说足够了
    final controller = StreamController<List<E>>.broadcast();
    Timer? timer;

    void emit() {
      findAll<E>().then((entities) {
        if (!controller.isClosed) {
          controller.add(entities);
        }
      });
    }

    // 立即触发一次
    emit();

    // 每 100ms 轮询一次
    timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!controller.isClosed) {
        emit();
      } else {
        timer?.cancel();
      }
    });

    controller.onCancel = () {
      timer?.cancel();
    };

    return controller.stream;
  }

  @override
  Stream<List<E>> watchList<E>(
    QueryDescriptor descriptor, {
    bool triggerImmediately = true,
  }) {
    // 内存实现中，watchList 也使用轮询机制
    final controller = StreamController<List<E>>.broadcast();
    Timer? timer;

    void emit() {
      findAll<E>().then((entities) {
        // TODO: 应用 descriptor 的过滤、排序、分页
        // 目前简化实现，直接返回所有实体
        if (!controller.isClosed) {
          controller.add(entities);
        }
      });
    }

    if (triggerImmediately) {
      emit();
    }

    timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!controller.isClosed) {
        emit();
      } else {
        timer?.cancel();
      }
    });

    controller.onCancel = () {
      timer?.cancel();
    };

    return controller.stream;
  }

  @override
  DatabaseQueryBuilder<E> queryBuilder<E>() {
    // 内存实现中，返回一个简单的查询构建器
    // 注意：这需要实现一个内存版本的查询构建器
    // 目前返回一个占位实现，实际使用时需要完善
    throw UnimplementedError(
      'InMemoryDatabaseAdapter.queryBuilder is not yet implemented. '
      'Use findAll() or watch() instead.',
    );
  }

  @override
  Future<void> close() async {
    // 关闭所有 watch 控制器
    for (final controller in _watchControllers.values) {
      await controller.close();
    }
    _watchControllers.clear();
    // 清空存储（可选，取决于测试需求）
    // _storage.clear();
    // _idCounters.clear();
  }

  /// 清空所有数据（用于测试）
  void clear() {
    _storage.clear();
    _idCounters.clear();
    for (final controller in _watchControllers.values) {
      controller.close();
    }
    _watchControllers.clear();
  }

  // 辅助方法：获取实体类型名称
  String _getEntityTypeName<E>() {
    return E.toString();
  }

  // 辅助方法：获取实体的 ID（使用反射或约定）
  // 假设实体有 id 或 obxId 字段
  dynamic _getEntityId(dynamic entity) {
    // 尝试通过反射获取 id 字段
    // 注意：Dart 的反射能力有限，这里使用约定
    try {
      // 如果实体有 id getter
      if (entity is Map) {
        return entity['id'];
      }
      // 尝试使用 dynamic 调用
      return (entity as dynamic).id ?? (entity as dynamic).obxId;
    } catch (e) {
      return null;
    }
  }

  // 辅助方法：设置实体的 ID
  void _setEntityId(dynamic entity, dynamic id) {
    try {
      if (entity is Map) {
        entity['id'] = id;
      } else {
        // 尝试使用 dynamic 设置
        (entity as dynamic).id = id;
      }
    } catch (e) {
      // 忽略设置失败
    }
  }

  // 通知 watch 订阅者数据已变化
  void _notifyWatchers<E>() {
    final type = E;
    final controller = _watchControllers[type];
    if (controller != null && !controller.isClosed) {
      findAll<E>().then((entities) {
        if (!controller.isClosed) {
          controller.add(entities);
        }
      });
    }
  }
}
