import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/presentation/tasks/utils/list_comparison_utils.dart';

void main() {
  group('listEquals', () {
    test('returns true for identical lists', () {
      final list = [_createTask(id: 1)];
      expect(listEquals(list, list), isTrue);
    });

    test('returns true for equal lists', () {
      final list1 = [
        _createTask(id: 1, sortIndex: 10),
        _createTask(id: 2, sortIndex: 20),
      ];
      final list2 = [
        _createTask(id: 1, sortIndex: 10),
        _createTask(id: 2, sortIndex: 20),
      ];
      expect(listEquals(list1, list2), isTrue);
    });

    test('returns false for different lengths', () {
      final list1 = [_createTask(id: 1)];
      final list2 = [_createTask(id: 1), _createTask(id: 2)];
      expect(listEquals(list1, list2), isFalse);
    });

    test('returns false for different ids', () {
      final list1 = [_createTask(id: 1)];
      final list2 = [_createTask(id: 2)];
      expect(listEquals(list1, list2), isFalse);
    });

    test('returns false for different sortIndices', () {
      final list1 = [_createTask(id: 1, sortIndex: 10)];
      final list2 = [_createTask(id: 1, sortIndex: 20)];
      expect(listEquals(list1, list2), isFalse);
    });

    test('returns true for empty lists', () {
      expect(listEquals([], []), isTrue);
    });
  });

  group('treeEquals', () {
    test('returns true for identical trees', () {
      final tree = [_createTreeNode(id: 1)];
      expect(treeEquals(tree, tree), isTrue);
    });

    test('returns true for equal trees', () {
      final tree1 = [
        _createTreeNode(id: 1, sortIndex: 10),
        _createTreeNode(id: 2, sortIndex: 20),
      ];
      final tree2 = [
        _createTreeNode(id: 1, sortIndex: 10),
        _createTreeNode(id: 2, sortIndex: 20),
      ];
      expect(treeEquals(tree1, tree2), isTrue);
    });

    test('returns false for different lengths', () {
      final tree1 = [_createTreeNode(id: 1)];
      final tree2 = [
        _createTreeNode(id: 1),
        _createTreeNode(id: 2),
      ];
      expect(treeEquals(tree1, tree2), isFalse);
    });

    test('returns false for different task ids', () {
      final tree1 = [_createTreeNode(id: 1)];
      final tree2 = [_createTreeNode(id: 2)];
      expect(treeEquals(tree1, tree2), isFalse);
    });

    test('returns false for different task sortIndices', () {
      final tree1 = [_createTreeNode(id: 1, sortIndex: 10)];
      final tree2 = [_createTreeNode(id: 1, sortIndex: 20)];
      expect(treeEquals(tree1, tree2), isFalse);
    });

    test('returns true for empty trees', () {
      expect(treeEquals([], []), isTrue);
    });
  });
}

Task _createTask({required int id, double sortIndex = 0}) {
  final now = DateTime.now();
  return Task(
    id: id,
    taskId: 'task-$id',
    title: 'Task $id',
    status: TaskStatus.pending,
    sortIndex: sortIndex,
    tags: const [],
    templateLockCount: 0,
    logs: const [],
    createdAt: now,
    updatedAt: now,
  );
}

TaskTreeNode _createTreeNode({required int id, double sortIndex = 0}) {
  return TaskTreeNode(
    task: _createTask(id: id, sortIndex: sortIndex),
    children: [],
  );
}

