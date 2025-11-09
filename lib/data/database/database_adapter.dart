import 'dart:async';

import 'query_builder.dart';

typedef DatabaseTransactionCallback<T> = FutureOr<T> Function();

/// 底层数据库发生错误时抛出的统一异常类型，避免向上层暴露具体实现细节。
class DatabaseAdapterException implements Exception {
  DatabaseAdapterException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'DatabaseAdapterException(message: $message, cause: $cause)';
}

/// 提供最小集合的数据库操作抽象，仓库层只能通过本接口访问持久化层。
abstract class DatabaseAdapter {
  Future<T> readTransaction<T>(DatabaseTransactionCallback<T> action);

  Future<T> writeTransaction<T>(DatabaseTransactionCallback<T> action);

  DatabaseQueryBuilder<E> queryBuilder<E>();

  Stream<List<E>> watch<E>(
    DatabaseQueryBuilder<E> Function(DatabaseQueryBuilder<E> builder) build,
  );

  Future<void> close();
}
