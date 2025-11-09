import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/presentation/tasks/utils/tree_flattening_utils.dart';

void main() {
  group('flattenTree', () {
    test('flattens single node tree', () {
      final root = TaskTreeNode(task: _createTask(id: 1), children: []);

      final result = flattenTree(root);

      expect(result.length, 1);
      expect(result[0].task.id, 1);
      expect(result[0].depth, 0);
    });

    test('flattens tree with one level of children', () {
      final root = TaskTreeNode(
        task: _createTask(id: 1),
        children: [
          TaskTreeNode(task: _createTask(id: 2), children: []),
          TaskTreeNode(task: _createTask(id: 3), children: []),
        ],
      );

      final result = flattenTree(root);

      expect(result.length, 3);
      expect(result[0].task.id, 1);
      expect(result[0].depth, 0);
      expect(result[1].task.id, 2);
      expect(result[1].depth, 1);
      expect(result[2].task.id, 3);
      expect(result[2].depth, 1);
    });

    test('flattens deeply nested tree', () {
      final root = TaskTreeNode(
        task: _createTask(id: 1),
        children: [
          TaskTreeNode(
            task: _createTask(id: 2),
            children: [
              TaskTreeNode(
                task: _createTask(id: 3),
                children: [
                  TaskTreeNode(task: _createTask(id: 4), children: []),
                ],
              ),
            ],
          ),
        ],
      );

      final result = flattenTree(root);

      expect(result.length, 4);
      expect(result[0].depth, 0);
      expect(result[1].depth, 1);
      expect(result[2].depth, 2);
      expect(result[3].depth, 3);
    });

    test('excludes root when includeRoot is false', () {
      final root = TaskTreeNode(
        task: _createTask(id: 1),
        children: [TaskTreeNode(task: _createTask(id: 2), children: [])],
      );

      final result = flattenTree(root, includeRoot: false);

      expect(result.length, 1);
      expect(result[0].task.id, 2);
      expect(result[0].depth, 1);
    });

    test('respects custom starting depth', () {
      final root = TaskTreeNode(
        task: _createTask(id: 1),
        children: [TaskTreeNode(task: _createTask(id: 2), children: [])],
      );

      final result = flattenTree(root, depth: 5);

      expect(result[0].depth, 5);
      expect(result[1].depth, 6);
    });
  });
}

Task _createTask({required int id}) {
  final now = DateTime.now();
  return Task(
    id: id,

    title: 'Task $id',
    status: TaskStatus.pending,
    sortIndex: 0,
    tags: const [],
    templateLockCount: 0,
    logs: const [],
    createdAt: now,
    updatedAt: now,
  );
}
