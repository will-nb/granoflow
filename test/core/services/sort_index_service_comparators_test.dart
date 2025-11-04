import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/services/sort_index_service_comparators.dart';
import 'package:granoflow/data/models/task.dart';

void main() {
  group('SortIndexServiceComparators', () {
    final baseDate = DateTime(2025, 1, 15, 10, 30);

    Task _task({
      required int id,
      double sortIndex = 1000,
      DateTime? dueAt,
      DateTime? createdAt,
    }) {
      return Task(
        id: id,
        taskId: 'task-$id',
        title: 'Task $id',
        status: TaskStatus.pending,
        createdAt: createdAt ?? baseDate,
        updatedAt: baseDate,
        sortIndex: sortIndex,
        dueAt: dueAt,
        tags: const [],
      );
    }

    group('compareTasksForInbox', () {
      test('按 sortIndex 升序排序', () {
        final task1 = _task(id: 1, sortIndex: 1000);
        final task2 = _task(id: 2, sortIndex: 2000);

        final result = SortIndexServiceComparators.compareTasksForInbox(
          task1,
          task2,
        );

        expect(result, lessThan(0), reason: 'sortIndex 小的应该排在前面');
      });

      test('sortIndex 相同时按 createdAt 降序排序', () {
        final task1 = _task(id: 1, sortIndex: 1000, createdAt: baseDate);
        final task2 = _task(
          id: 2,
          sortIndex: 1000,
          createdAt: baseDate.add(const Duration(hours: 1)),
        );

        final result = SortIndexServiceComparators.compareTasksForInbox(
          task1,
          task2,
        );

        expect(result, greaterThan(0), reason: '新任务（createdAt 更晚）应该排在前面');
      });

      test('sortIndex 和 createdAt 都相同时返回 0', () {
        final task1 = _task(id: 1, sortIndex: 1000, createdAt: baseDate);
        final task2 = _task(id: 2, sortIndex: 1000, createdAt: baseDate);

        final result = SortIndexServiceComparators.compareTasksForInbox(
          task1,
          task2,
        );

        expect(result, equals(0));
      });
    });

    group('compareTasksForTasksPage', () {
      test('按 dueAt 日期升序排序', () {
        final task1 = _task(
          id: 1,
          dueAt: DateTime(2025, 1, 15, 10, 0),
          sortIndex: 2000,
        );
        final task2 = _task(
          id: 2,
          dueAt: DateTime(2025, 1, 16, 10, 0),
          sortIndex: 1000,
        );

        final result = SortIndexServiceComparators.compareTasksForTasksPage(
          task1,
          task2,
        );

        expect(result, lessThan(0), reason: 'dueAt 早的应该排在前面');
      });

      test('dueAt 日期相同时按 sortIndex 升序排序', () {
        final dueDate = DateTime(2025, 1, 15, 10, 0);
        final task1 = _task(id: 1, dueAt: dueDate, sortIndex: 1000);
        final task2 = _task(id: 2, dueAt: dueDate, sortIndex: 2000);

        final result = SortIndexServiceComparators.compareTasksForTasksPage(
          task1,
          task2,
        );

        expect(result, lessThan(0), reason: 'sortIndex 小的应该排在前面');
      });

      test('dueAt 日期和 sortIndex 都相同时按 createdAt 降序排序', () {
        final dueDate = DateTime(2025, 1, 15, 10, 0);
        final task1 = _task(
          id: 1,
          dueAt: dueDate,
          sortIndex: 1000,
          createdAt: baseDate,
        );
        final task2 = _task(
          id: 2,
          dueAt: dueDate,
          sortIndex: 1000,
          createdAt: baseDate.add(const Duration(hours: 1)),
        );

        final result = SortIndexServiceComparators.compareTasksForTasksPage(
          task1,
          task2,
        );

        expect(result, greaterThan(0), reason: '新任务应该排在前面');
      });

      test('没有 dueAt 的任务排在后面', () {
        final task1 = _task(id: 1, dueAt: DateTime(2025, 1, 15));
        final task2 = _task(id: 2, dueAt: null);

        final result = SortIndexServiceComparators.compareTasksForTasksPage(
          task1,
          task2,
        );

        expect(result, lessThan(0), reason: '有 dueAt 的任务应该排在前面');
      });

      test('两个都没有 dueAt 时按 sortIndex 升序排序', () {
        final task1 = _task(id: 1, dueAt: null, sortIndex: 1000);
        final task2 = _task(id: 2, dueAt: null, sortIndex: 2000);

        final result = SortIndexServiceComparators.compareTasksForTasksPage(
          task1,
          task2,
        );

        expect(result, lessThan(0), reason: 'sortIndex 小的应该排在前面');
      });

      test('忽略 dueAt 的时间部分，只比较日期', () {
        final task1 = _task(
          id: 1,
          dueAt: DateTime(2025, 1, 15, 10, 0),
          sortIndex: 2000,
        );
        final task2 = _task(
          id: 2,
          dueAt: DateTime(2025, 1, 15, 20, 0),
          sortIndex: 1000,
        );

        final result = SortIndexServiceComparators.compareTasksForTasksPage(
          task1,
          task2,
        );

        expect(result, greaterThan(0),
            reason: '日期相同，sortIndex 小的应该排在前面');
      });
    });

    group('compareTasksForChildren', () {
      test('使用与 Inbox 相同的排序规则', () {
        final task1 = _task(id: 1, sortIndex: 1000, createdAt: baseDate);
        final task2 = _task(
          id: 2,
          sortIndex: 1000,
          createdAt: baseDate.add(const Duration(hours: 1)),
        );

        final result = SortIndexServiceComparators.compareTasksForChildren(
          task1,
          task2,
        );

        expect(result, greaterThan(0), reason: '新任务应该排在前面');
      });
    });
  });
}

