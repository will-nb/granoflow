import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/data/models/node.dart';
import 'package:granoflow/data/repositories/node_repository.dart';
import 'package:granoflow/data/repositories/drift/drift_node_repository.dart';
import 'package:granoflow/data/database/database_adapter.dart';
import 'package:granoflow/data/database/drift_adapter.dart';
import 'package:granoflow/data/drift/database.dart';

void main() {
  group('DriftNodeRepository', () {
    late DatabaseAdapter adapter;
    late NodeRepository repository;
    late AppDatabase testDb;

    setUp(() async {
      // 创建内存数据库用于测试
      testDb = AppDatabase.test();
      // 设置测试实例为单例
      AppDatabase.setTestInstance(testDb);
      adapter = DriftAdapter();
      repository = DriftNodeRepository(adapter);
    });

    tearDown(() async {
      await adapter.close();
      await testDb.close();
      // 重置单例
      AppDatabase.setTestInstance(null);
    });

    group('节点 CRUD 操作', () {
      test('应该能够创建节点', () async {
        final node = await repository.createNode(
          taskId: 'task-1',
          title: 'Test Node',
        );

        expect(node.id, isNotEmpty);
        expect(node.taskId, 'task-1');
        expect(node.title, 'Test Node');
        expect(node.status, NodeStatus.pending);
        expect(node.parentId, isNull);
      });

      test('应该能够创建子节点', () async {
        final parent = await repository.createNode(
          taskId: 'task-1',
          title: 'Parent Node',
        );

        final child = await repository.createNode(
          taskId: 'task-1',
          title: 'Child Node',
          parentId: parent.id,
        );

        expect(child.parentId, parent.id);
      });

      test('应该能够更新节点标题', () async {
        final node = await repository.createNode(
          taskId: 'task-1',
          title: 'Original Title',
        );

        await repository.updateNode(node.id, title: 'Updated Title');

        final updated = await repository.findById(node.id);
        expect(updated, isNotNull);
        expect(updated!.title, 'Updated Title');
      });

      test('应该能够更新节点状态', () async {
        final node = await repository.createNode(
          taskId: 'task-1',
          title: 'Test Node',
        );

        await repository.updateNode(node.id, status: NodeStatus.finished);

        final updated = await repository.findById(node.id);
        expect(updated, isNotNull);
        expect(updated!.status, NodeStatus.finished);
      });

      test('应该能够删除节点（软删除）', () async {
        final node = await repository.createNode(
          taskId: 'task-1',
          title: 'Test Node',
        );

        await repository.deleteNode(node.id);

        final deleted = await repository.findById(node.id);
        expect(deleted, isNotNull);
        expect(deleted!.status, NodeStatus.deleted);
      });

      test('应该能够删除节点及其子节点', () async {
        final parent = await repository.createNode(
          taskId: 'task-1',
          title: 'Parent Node',
        );

        final child1 = await repository.createNode(
          taskId: 'task-1',
          title: 'Child 1',
          parentId: parent.id,
        );

        final child2 = await repository.createNode(
          taskId: 'task-1',
          title: 'Child 2',
          parentId: parent.id,
        );

        await repository.deleteNodeWithChildren(parent.id);

        final deletedParent = await repository.findById(parent.id);
        final deletedChild1 = await repository.findById(child1.id);
        final deletedChild2 = await repository.findById(child2.id);

        expect(deletedParent, isNotNull);
        expect(deletedParent!.status, NodeStatus.deleted);
        expect(deletedChild1, isNotNull);
        expect(deletedChild1!.status, NodeStatus.deleted);
        expect(deletedChild2, isNotNull);
        expect(deletedChild2!.status, NodeStatus.deleted);
      });

      test('应该能够恢复已删除的节点', () async {
        final node = await repository.createNode(
          taskId: 'task-1',
          title: 'Test Node',
        );

        await repository.deleteNode(node.id);
        await repository.restoreNode(node.id);

        final restored = await repository.findById(node.id);
        expect(restored, isNotNull);
        expect(restored!.status, NodeStatus.pending);
      });
    });

    group('节点查询', () {
      test('应该能够查询任务的所有节点', () async {
        await repository.createNode(taskId: 'task-1', title: 'Node 1');
        await repository.createNode(taskId: 'task-1', title: 'Node 2');
        await repository.createNode(taskId: 'task-2', title: 'Node 3');

        final nodes = await repository.listNodesByTaskId('task-1');
        expect(nodes.length, 2);
        expect(nodes.every((n) => n.taskId == 'task-1'), isTrue);
      });

      test('应该能够查询子节点', () async {
        final parent = await repository.createNode(
          taskId: 'task-1',
          title: 'Parent',
        );

        await repository.createNode(
          taskId: 'task-1',
          title: 'Child 1',
          parentId: parent.id,
        );

        await repository.createNode(
          taskId: 'task-1',
          title: 'Child 2',
          parentId: parent.id,
        );

        final children = await repository.listChildrenByParentId(parent.id);
        expect(children.length, 2);
        expect(children.every((n) => n.parentId == parent.id), isTrue);
      });

      test('应该能够监听节点变化', () async {
        final stream = repository.watchNodesByTaskId('task-1');
        final subscription = stream.listen((nodes) {
          expect(nodes.length, greaterThanOrEqualTo(0));
        });

        await repository.createNode(taskId: 'task-1', title: 'New Node');
        await Future.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();
      });
    });

    group('节点排序和移动', () {
      test('应该能够批量重排序节点', () async {
        final node1 = await repository.createNode(taskId: 'task-1', title: 'Node 1');
        final node2 = await repository.createNode(taskId: 'task-1', title: 'Node 2');
        final node3 = await repository.createNode(taskId: 'task-1', title: 'Node 3');

        await repository.reorderNodes([node3.id, node1.id, node2.id]);

        final nodes = await repository.listNodesByTaskId('task-1');
        expect(nodes.length, 3);
        // 验证排序顺序
        expect(nodes[0].id, node3.id);
        expect(nodes[1].id, node1.id);
        expect(nodes[2].id, node2.id);
      });

      test('应该能够移动节点到新的父节点', () async {
        final parent1 = await repository.createNode(
          taskId: 'task-1',
          title: 'Parent 1',
        );

        final parent2 = await repository.createNode(
          taskId: 'task-1',
          title: 'Parent 2',
        );

        final child = await repository.createNode(
          taskId: 'task-1',
          title: 'Child',
          parentId: parent1.id,
        );

        await repository.moveNode(child.id, parent2.id, 1000.0);

        final moved = await repository.findById(child.id);
        expect(moved, isNotNull);
        expect(moved!.parentId, parent2.id);
        expect(moved.sortIndex, 1000.0);
      });
    });
  });
}

