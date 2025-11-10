import 'dart:async';

import 'query_builder.dart';

typedef DatabaseTransactionCallback<T> = FutureOr<T> Function();

/// 数据库操作的上下文信息，用于错误报告和日志记录。
class DatabaseOperationContext {
  DatabaseOperationContext({
    required this.operation,
    required this.entity,
    this.parameters,
    this.duration,
  });

  /// 操作名称，如 'put', 'findById', 'count' 等
  final String operation;

  /// 实体类型名称，如 'TaskEntity', 'ProjectEntity' 等
  final String entity;

  /// 操作参数，用于调试和日志
  final Map<String, dynamic>? parameters;

  /// 操作耗时（毫秒）
  final int? duration;

  /// 创建带有更新耗时的副本
  DatabaseOperationContext copyWith({int? duration}) {
    return DatabaseOperationContext(
      operation: operation,
      entity: entity,
      parameters: parameters,
      duration: duration ?? this.duration,
    );
  }

  @override
  String toString() =>
      'DatabaseOperationContext(operation: $operation, entity: $entity, '
      'parameters: $parameters, duration: ${duration}ms)';
}

/// 底层数据库发生错误时抛出的统一异常类型，避免向上层暴露具体实现细节。
class DatabaseAdapterException implements Exception {
  DatabaseAdapterException(
    this.message, [
    this.cause,
    this.context,
  ]);

  final String message;
  final Object? cause;
  final DatabaseOperationContext? context;

  @override
  String toString() {
    final buffer = StringBuffer('DatabaseAdapterException(');
    buffer.write('message: $message');
    if (cause != null) {
      buffer.write(', cause: $cause');
    }
    if (context != null) {
      buffer.write(', context: $context');
    }
    buffer.write(')');
    return buffer.toString();
  }
}

/// 数据库操作的 instrumentation 钩子，用于记录操作日志和性能监控。
abstract class DatabaseInstrumentation {
  /// 操作开始时的回调
  void onStart(DatabaseOperationContext context);

  /// 操作成功完成时的回调
  void onSuccess(DatabaseOperationContext context, {int? affectedCount});

  /// 操作失败时的回调
  void onError(DatabaseOperationContext context, Object error);
}

/// 提供最小集合的数据库操作抽象，仓库层只能通过本接口访问持久化层。
///
/// ## 事务语义
/// - `readTransaction`: 用于只读操作，允许多个并发读取
/// - `writeTransaction`: 用于写入操作，保证原子性和隔离性
///
/// ## watchList 触发规则
/// - 当查询结果发生变化时触发（新增、更新、删除）
/// - 首次订阅时立即触发一次（triggerImmediately: true）
/// - 支持取消订阅，避免内存泄漏
///
/// ## count 一致性要求
/// - count 操作应该与 findAll() 返回的结果数量一致
/// - 在事务中，count 应该反映事务内的变更
abstract class DatabaseAdapter {
  /// 可选的 instrumentation 钩子，用于记录操作日志和性能监控
  DatabaseInstrumentation? get instrumentation => null;

  /// 设置 instrumentation 钩子
  void setInstrumentation(DatabaseInstrumentation? instrumentation) {
    // 默认实现：子类可以覆盖
  }

  /// 执行只读事务
  Future<T> readTransaction<T>(DatabaseTransactionCallback<T> action);

  /// 执行写入事务
  Future<T> writeTransaction<T>(DatabaseTransactionCallback<T> action);

  /// 创建查询构建器
  DatabaseQueryBuilder<E> queryBuilder<E>();

  /// 监听查询结果变化（基于查询构建器）
  ///
  /// 注意：此方法使用查询构建器，适合复杂查询场景
  /// 对于简单查询，建议使用 watchList
  Stream<List<E>> watch<E>(
    DatabaseQueryBuilder<E> Function(DatabaseQueryBuilder<E> builder) build,
  );

  /// 监听查询结果变化（基于查询描述符）
  ///
  /// 与 watch 不同，watchList 使用查询描述符，更适合批量操作和性能优化
  /// 首次订阅时立即触发一次（triggerImmediately: true）
  Stream<List<E>> watchList<E>(
    QueryDescriptor descriptor, {
    bool triggerImmediately = true,
  }) {
    // 默认实现：使用 watch 方法
    // 子类可以覆盖以提供更高效的实现
    return watch<E>((builder) {
      // 将 QueryDescriptor 转换为查询构建器调用
      // 这是一个简化实现，子类应该覆盖此方法
      return builder;
    });
  }

  /// 保存单个实体
  Future<E> put<E>(E entity);

  /// 批量保存实体
  Future<List<E>> putMany<E>(List<E> entities);

  /// 根据 ID 删除实体
  Future<bool> remove<E>(dynamic id);

  /// 批量删除实体
  Future<int> removeMany<E>(List<dynamic> ids);

  /// 根据 ID 查找实体
  Future<E?> findById<E>(dynamic id);

  /// 查找所有实体（无过滤条件）
  Future<List<E>> findAll<E>();

  /// 统计实体数量
  Future<int> count<E>();

  /// 关闭数据库连接
  Future<void> close();
}
