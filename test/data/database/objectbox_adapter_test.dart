import 'package:flutter_test/flutter_test.dart';

import '../../../lib/core/utils/objectbox_diagnostics.dart';
import '../../support/in_memory_database_adapter.dart';

// 简单的测试实体类
class _TestEntity {
  _TestEntity({
    this.id,
    required this.name,
  });

  String? id;
  final String name;
}

void main() {
  group('DatabaseAdapter (using InMemoryAdapter)', () {
    late InMemoryDatabaseAdapter adapter;

    setUp(() {
      adapter = InMemoryDatabaseAdapter();
    });

    tearDown(() async {
      adapter.clear();
      await adapter.close();
    });

    group('CRUD operations', () {
      test('put and findById should work correctly', () async {
        final entity = _TestEntity(id: 'test-1', name: 'Test Entity');
        final saved = await adapter.put<_TestEntity>(entity);
        expect(saved.id, equals('test-1'));

        final found = await adapter.findById<_TestEntity>('test-1');
        expect(found, isNotNull);
        expect(found!.id, equals('test-1'));
        expect(found.name, equals('Test Entity'));
      });

      test('putMany should save multiple entities', () async {
        final entities = [
          _TestEntity(id: 'test-1', name: 'Entity 1'),
          _TestEntity(id: 'test-2', name: 'Entity 2'),
        ];

        final saved = await adapter.putMany<_TestEntity>(entities);
        expect(saved.length, equals(2));

        final all = await adapter.findAll<_TestEntity>();
        expect(all.length, equals(2));
      });

      test('remove should delete entity', () async {
        final entity = _TestEntity(id: 'test-1', name: 'Test Entity');
        await adapter.put<_TestEntity>(entity);
        
        final removed = await adapter.remove<_TestEntity>('test-1');
        expect(removed, isTrue);

        final found = await adapter.findById<_TestEntity>('test-1');
        expect(found, isNull);
      });

      test('count should return correct number', () async {
        await adapter.put<_TestEntity>(_TestEntity(id: 'test-1', name: 'Entity 1'));
        await adapter.put<_TestEntity>(_TestEntity(id: 'test-2', name: 'Entity 2'));

        final count = await adapter.count<_TestEntity>();
        expect(count, equals(2));
      });
    });

    group('Transactions', () {
      test('readTransaction should execute read operations', () async {
        final entity = _TestEntity(id: 'test-1', name: 'Test Entity');
        await adapter.put<_TestEntity>(entity);

        final result = await adapter.readTransaction(() async {
          return await adapter.findAll<_TestEntity>();
        });

        expect(result.length, equals(1));
      });

      test('writeTransaction should execute write operations atomically', () async {
        await adapter.writeTransaction(() async {
          await adapter.put<_TestEntity>(_TestEntity(id: 'test-1', name: 'Entity 1'));
          await adapter.put<_TestEntity>(_TestEntity(id: 'test-2', name: 'Entity 2'));
        });

        final count = await adapter.count<_TestEntity>();
        expect(count, equals(2));
      });
    });

    group('Instrumentation', () {
      test('should call instrumentation hooks', () async {
        final fakeInstrumentation = FakeDatabaseInstrumentation();
        adapter.setInstrumentation(fakeInstrumentation);

        final entity = _TestEntity(id: 'test-1', name: 'Test Entity');
        await adapter.put<_TestEntity>(entity);

        expect(fakeInstrumentation.started.length, greaterThan(0));
        expect(fakeInstrumentation.succeeded.length, greaterThan(0));
      });
    });

    group('Error handling', () {
      test('findById should return null for non-existent entity', () async {
        // 尝试查找不存在的实体应该返回 null，而不是抛出异常
        final found = await adapter.findById<_TestEntity>('non-existent');
        expect(found, isNull);
      });
    });
  });
}
