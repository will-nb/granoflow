import 'dart:async';

import 'package:objectbox/objectbox.dart';

import 'database_adapter.dart';
import 'objectbox_query_builder.dart';
import 'query_builder.dart';

/// ObjectBox 版 `DatabaseAdapter` 实现。
///
class ObjectBoxAdapter implements DatabaseAdapter {
  ObjectBoxAdapter(this.store);

  final Store store;

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
    final box = _box<E>();
    final builderInstance = ObjectBoxQueryBuilder<E>(box);
    build(builderInstance);
    // Use Store.subscribe to watch for changes
    // Note: This is a simplified implementation - ObjectBox doesn't have Box.watch()
    // We'll use a periodic stream that checks for changes
    return Stream.periodic(const Duration(milliseconds: 100))
        .asyncMap((_) => builderInstance.findAll())
        .distinct((prev, next) {
      // Simple comparison - in production, you'd want more sophisticated change detection
      if (prev.length != next.length) return false;
      for (var i = 0; i < prev.length; i++) {
        if (prev[i] != next[i]) return false;
      }
      return true;
    });
  }

  @override
  Future<void> close() async {
    store.close();
  }

  Box<E> _box<E>() => store.box<E>();

  Future<T> _runInTransaction<T>(
    TxMode mode,
    DatabaseTransactionCallback<T> action,
  ) {
    return store.runInTransactionAsync<T, void>(
      mode,
      (void _) async {
        try {
          return await action();
        } on DatabaseAdapterException {
          rethrow;
        } catch (error) {
          throw DatabaseAdapterException(
            'ObjectBox transaction failed',
            error,
          );
        }
      },
      null,
    );
  }
}
