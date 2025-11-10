import 'dart:async';

import '../database/database_adapter.dart';
import '../database/objectbox_adapter.dart';

/// ObjectBox 仓储基类，提供通用的实体转换、日志、错误处理能力。
///
/// ## Adapter 注入校验
/// 构造函数会验证传入的 adapter 必须是 ObjectBoxAdapter 实例，确保类型安全。
/// 这保证了仓储层只能使用 ObjectBox 实现，同时保持了与 DatabaseAdapter 抽象接口的兼容性。
///
/// ## 事务封装
/// 所有数据库操作都通过 `withRead` 和 `withWrite` 方法封装，确保：
/// - 只读操作使用 `readTransaction`，允许多个并发读取
/// - 写入操作使用 `writeTransaction`，保证原子性和隔离性
/// - 未来替换数据库实现时，只需修改 DatabaseAdapter 实现，无需修改仓储代码
///
/// ## 未来兼容性
/// 虽然当前实现要求 ObjectBoxAdapter，但通过依赖 DatabaseAdapter 接口，
/// 未来可以轻松切换到其他实现（如 DriftAdapter）：
/// 1. 实现新的 DatabaseAdapter（如 DriftAdapter）
/// 2. 修改 BaseObjectBoxRepository 的类型检查（或创建新的基类）
/// 3. 业务代码无需修改，因为所有操作都通过 DatabaseAdapter 接口
///
/// ## 子类实现要求
/// 子类需要实现：
/// - `toEntity()`: 将领域模型转换为实体
/// - `toModel()`: 将实体转换为领域模型
/// - `mapEntities()`: 批量转换实体列表
abstract class BaseObjectBoxRepository {
  BaseObjectBoxRepository(
    this._adapter, [
    this._instrumentation,
  ]) {
    // Adapter 注入校验：确保类型安全
    // 注意：虽然这里要求 ObjectBoxAdapter，但通过依赖 DatabaseAdapter 接口，
    // 未来可以轻松切换到其他实现，只需修改此处的类型检查
    if (_adapter is! ObjectBoxAdapter) {
      throw ArgumentError(
        '${runtimeType} requires ObjectBoxAdapter, got ${_adapter.runtimeType}. '
        'This ensures type safety while maintaining compatibility with DatabaseAdapter interface.',
      );
    }
  }

  final DatabaseAdapter _adapter;
  final DatabaseInstrumentation? _instrumentation;

  /// 获取 ObjectBoxAdapter（已校验类型）
  ObjectBoxAdapter get adapter => _adapter as ObjectBoxAdapter;

  /// 执行只读事务的便捷方法
  Future<T> withRead<T>(Future<T> Function() action) async {
    return _adapter.readTransaction(() => action());
  }

  /// 执行写入事务的便捷方法
  Future<T> withWrite<T>(Future<T> Function() action) async {
    return _adapter.writeTransaction(() => action());
  }

  /// 保存单个实体
  Future<E> putEntity<E>(E entity) async {
    return _adapter.put<E>(entity);
  }

  /// 批量保存实体
  Future<List<E>> putManyEntities<E>(List<E> entities) async {
    if (entities.isEmpty) return entities;
    return _adapter.putMany<E>(entities);
  }

  /// 根据 ID 查找实体
  Future<E?> findEntityById<E>(dynamic id) async {
    return _adapter.findById<E>(id);
  }

  /// 查找所有实体
  Future<List<E>> findAllEntities<E>() async {
    return _adapter.findAll<E>();
  }

  /// 统计实体数量
  Future<int> countEntities<E>() async {
    return _adapter.count<E>();
  }

  /// 删除实体
  Future<bool> removeEntity<E>(dynamic id) async {
    return _adapter.remove<E>(id);
  }

  /// 批量删除实体
  Future<int> removeManyEntities<E>(List<dynamic> ids) async {
    if (ids.isEmpty) return 0;
    return _adapter.removeMany<E>(ids);
  }

  /// 确保实体存在，不存在则抛出异常
  Future<E> ensureEntityExists<E>(dynamic id, String entityName) async {
    final entity = await findEntityById<E>(id);
    if (entity == null) {
      throw StateError('$entityName not found: $id');
    }
    return entity;
  }

  /// 将实体流转换为模型流
  Stream<List<M>> mapEntityStream<M, E>(
    Stream<List<E>> entityStream,
    List<M> Function(List<E> entities) mapper,
  ) {
    return entityStream.map(mapper);
  }

  /// 记录操作日志（如果启用了 instrumentation）
  void logOperation({
    required String operation,
    required String entity,
    Map<String, dynamic>? parameters,
    int? duration,
    int? affectedCount,
    Object? error,
  }) {
    final instrumentation = _instrumentation;
    if (instrumentation == null) return;

    final context = DatabaseOperationContext(
      operation: operation,
      entity: entity,
      parameters: parameters,
      duration: duration,
    );

    if (error != null) {
      instrumentation.onError(context, error);
    } else {
      instrumentation.onSuccess(context, affectedCount: affectedCount);
    }
  }
}
