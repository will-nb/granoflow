import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/data/models/node.dart';

void main() {
  group('Node', () {
    final now = DateTime(2024, 1, 1, 12, 0, 0);

    test('应该正确创建 Node 实例', () {
      final node = Node(
        id: 'node-1',
        taskId: 'task-1',
        title: 'Test Node',
        status: NodeStatus.pending,
        sortIndex: 0.0,
        createdAt: now,
        updatedAt: now,
      );

      expect(node.id, 'node-1');
      expect(node.taskId, 'task-1');
      expect(node.title, 'Test Node');
      expect(node.status, NodeStatus.pending);
      expect(node.sortIndex, 0.0);
      expect(node.parentId, isNull);
      expect(node.createdAt, now);
      expect(node.updatedAt, now);
    });

    test('应该支持 copyWith 部分更新', () {
      final node = Node(
        id: 'node-1',
        taskId: 'task-1',
        title: 'Test Node',
        status: NodeStatus.pending,
        sortIndex: 0.0,
        createdAt: now,
        updatedAt: now,
      );

      final updated = node.copyWith(
        title: 'Updated Node',
        status: NodeStatus.finished,
      );

      expect(updated.id, 'node-1');
      expect(updated.title, 'Updated Node');
      expect(updated.status, NodeStatus.finished);
      expect(updated.sortIndex, 0.0); // 未更新的字段保持不变
    });

    test('应该正确比较 Node 实例', () {
      final node1 = Node(
        id: 'node-1',
        taskId: 'task-1',
        title: 'Test Node',
        status: NodeStatus.pending,
        sortIndex: 0.0,
        createdAt: now,
        updatedAt: now,
      );

      final node2 = Node(
        id: 'node-1',
        taskId: 'task-1',
        title: 'Test Node',
        status: NodeStatus.pending,
        sortIndex: 0.0,
        createdAt: now,
        updatedAt: now,
      );

      final node3 = Node(
        id: 'node-2',
        taskId: 'task-1',
        title: 'Test Node',
        status: NodeStatus.pending,
        sortIndex: 0.0,
        createdAt: now,
        updatedAt: now,
      );

      expect(node1 == node2, isTrue);
      expect(node1.hashCode == node2.hashCode, isTrue);
      expect(node1 == node3, isFalse);
    });

    test('应该支持 parentId', () {
      final parentNode = Node(
        id: 'parent-1',
        taskId: 'task-1',
        title: 'Parent Node',
        status: NodeStatus.pending,
        sortIndex: 0.0,
        createdAt: now,
        updatedAt: now,
      );

      final childNode = Node(
        id: 'child-1',
        taskId: 'task-1',
        title: 'Child Node',
        status: NodeStatus.pending,
        sortIndex: 0.0,
        createdAt: now,
        updatedAt: now,
        parentId: parentNode.id,
      );

      expect(childNode.parentId, 'parent-1');
    });
  });

  group('NodeStatus', () {
    test('应该包含三种状态', () {
      expect(NodeStatus.values.length, 3);
      expect(NodeStatus.values, contains(NodeStatus.pending));
      expect(NodeStatus.values, contains(NodeStatus.finished));
      expect(NodeStatus.values, contains(NodeStatus.deleted));
    });
  });
}

