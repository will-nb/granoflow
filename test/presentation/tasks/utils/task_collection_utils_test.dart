import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/presentation/tasks/utils/task_collection_utils.dart';

void main() {
  group('collectRoots', () {
    test('returns all tasks when none have parents', () {
      final tasks = [
        _createTask(id: 1, parentId: null),
        _createTask(id: 2, parentId: null),
        _createTask(id: 3, parentId: null),
      ];

      final roots = collectRoots(tasks);

      expect(roots.length, 3);
      expect(roots.map((t) => t.id), [1, 2, 3]);
    });

    test('filters out tasks with parents in the list', () {
      final tasks = [
        _createTask(id: 1, parentId: null),
        _createTask(id: 2, parentId: 1),
        _createTask(id: 3, parentId: null),
        _createTask(id: 4, parentId: 3),
      ];

      final roots = collectRoots(tasks);

      expect(roots.length, 2);
      expect(roots.map((t) => t.id), [1, 3]);
    });

    test('includes tasks whose parents are not in the list', () {
      final tasks = [
        _createTask(id: 1, parentId: null),
        _createTask(id: 2, parentId: 999), // parent not in list
        _createTask(id: 3, parentId: null),
      ];

      final roots = collectRoots(tasks);

      expect(roots.length, 3);
      expect(roots.map((t) => t.id), [1, 2, 3]);
    });

    test('preserves input order', () {
      final tasks = [
        _createTask(id: 3, parentId: null),
        _createTask(id: 1, parentId: null),
        _createTask(id: 2, parentId: null),
      ];

      final roots = collectRoots(tasks);

      expect(roots.map((t) => t.id), [3, 1, 2]); // order preserved
    });

    test('returns empty list for empty input', () {
      final roots = collectRoots([]);
      expect(roots, isEmpty);
    });
  });
}

Task _createTask({required int id, int? parentId}) {
  final now = DateTime.now();
  return Task(
    id: id,
    taskId: 'task-$id',
    title: 'Task $id',
    status: TaskStatus.pending,
    parentId: parentId,
    sortIndex: 0,
    tags: const [],
    templateLockCount: 0,
    logs: const [],
    createdAt: now,
    updatedAt: now,
    taskKind: TaskKind.regular,
  );
}

