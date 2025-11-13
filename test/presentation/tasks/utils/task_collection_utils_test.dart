import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/presentation/tasks/utils/task_collection_utils.dart';

void main() {
  group('collectRoots', () {
    test('returns all tasks when none have parents', () {
      final tasks = [
        _createTask(id: '1', 
        _createTask(id: '2', 
        _createTask(id: '3', 
      ];

      final roots = collectRoots(tasks);

      expect(roots.length, 3);
      expect(roots.map((t) => t.id), ['1', '2', '3']);
    });

    test('filters out tasks with parents in the list', () {
      final tasks = [
        _createTask(id: '1', 
        _createTask(id: '2', 
        _createTask(id: '3', 
        _createTask(id: '4', 
      ];

      final roots = collectRoots(tasks);

      expect(roots.length, 2);
      expect(roots.map((t) => t.id), ['1', '3']);
    });

    test('includes tasks whose parents are not in the list', () {
      final tasks = [
        _createTask(id: '1', 
        _createTask(id: '2',  // parent not in list
        _createTask(id: '3', 
      ];

      final roots = collectRoots(tasks);

      expect(roots.length, 3);
      expect(roots.map((t) => t.id), ['1', '2', '3']);
    });

    test('sorts tasks by sortIndex when no dueAt (Inbox behavior)', () {
      // 当任务没有 dueAt 时，collectRoots 会按 sortIndex 升序排序（Inbox 页面行为）
      final tasks = [
        _createTask(id: '3',  // sortIndex: 3 * 1024 = 3072
        _createTask(id: '1',  // sortIndex: 1 * 1024 = 1024
        _createTask(id: '2',  // sortIndex: 2 * 1024 = 2048
      ];

      final roots = collectRoots(tasks);

      // 应该按 sortIndex 升序排序：1, 2, 3
      expect(roots.map((t) => t.id), ['1', '2', '3']);
    });

    test('returns empty list for empty input', () {
      final roots = collectRoots([]);
      expect(roots, isEmpty);
    });
  });
}

Task _createTask({required String id, String? parentId}) {
  // 使用固定的时间基准，确保排序可预测
  // sortIndex 设置为 id 的数值 * 1024，确保每个任务有唯一的 sortIndex
  final baseTime = DateTime(2025, 1, 1);
  final idNum = int.tryParse(id) ?? 0;
  return Task(
    id: id,

    title: 'Task $id',
    status: TaskStatus.pending,
    
    sortIndex: idNum * 1024.0, // 确保每个任务有唯一的 sortIndex，按 id 顺序排序
    tags: const [],
    templateLockCount: 0,
    logs: const [],
    createdAt: baseTime.add(Duration(hours: idNum)), // 每个任务有不同的 createdAt
    updatedAt: baseTime.add(Duration(hours: idNum)),
  );
}
