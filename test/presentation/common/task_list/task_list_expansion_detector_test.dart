import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/presentation/common/task_list/task_list_expansion_detector.dart';
import 'package:granoflow/presentation/tasks/utils/tree_flattening_utils.dart';

/// 创建测试任务辅助函数
Task _createTask({required int id, int? parentId, double sortIndex = 1000}) {
  return Task(
    id: id,

    title: 'Task $id',
    status: TaskStatus.pending,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    parentId: parentId,
    sortIndex: sortIndex,
    tags: const [],
  );
}

void main() {
  group('TaskListExpansionDetector', () {
    group('isMovedOutOfExpandedArea', () {
      test('should return false when dragged task is root task', () {
        final draggedTask = _createTask(id: 1);
        final flattenedTasks = [
          FlattenedTaskNode(draggedTask, 0),
          FlattenedTaskNode(_createTask(id: 2), 0),
        ];
        final filteredTasks = [draggedTask, _createTask(id: 2)];

        final result = TaskListExpansionDetector.isMovedOutOfExpandedArea(
          draggedTask,
          null, // hoveredTaskId
          1, // hoveredInsertionIndex
          flattenedTasks,
          filteredTasks,
        );

        expect(result, false);
      });

      test('should return false when dragged task is not a subtask', () {
        final draggedTask = _createTask(id: 1);
        final flattenedTasks = [
          FlattenedTaskNode(draggedTask, 0),
          FlattenedTaskNode(_createTask(id: 2), 0),
        ];
        final filteredTasks = [draggedTask, _createTask(id: 2)];

        final result = TaskListExpansionDetector.isMovedOutOfExpandedArea(
          draggedTask,
          2, // hoveredTaskId
          null, // hoveredInsertionIndex
          flattenedTasks,
          filteredTasks,
        );

        expect(result, false);
      });

      test(
        'should return false when dragged subtask is still within parent expanded area',
        () {
          final parentTask = _createTask(id: 1);
          final draggedTask = _createTask(id: 2, parentId: 1);
          final siblingTask = _createTask(id: 3, parentId: 1);
          final flattenedTasks = [
            FlattenedTaskNode(parentTask, 0),
            FlattenedTaskNode(draggedTask, 1),
            FlattenedTaskNode(siblingTask, 1),
            FlattenedTaskNode(_createTask(id: 4), 0),
          ];
          final filteredTasks = [
            parentTask,
            draggedTask,
            siblingTask,
            _createTask(id: 4),
          ];

          // 拖动到父任务的子任务范围内（hoveredTaskId 是 siblingTask）
          final result = TaskListExpansionDetector.isMovedOutOfExpandedArea(
            draggedTask,
            3, // hoveredTaskId (siblingTask)
            null,
            flattenedTasks,
            filteredTasks,
          );

          expect(result, false);
        },
      );

      test(
        'should return true when dragged subtask moves outside parent expanded area',
        () {
          final parentTask = _createTask(id: 1);
          final draggedTask = _createTask(id: 2, parentId: 1);
          final siblingTask = _createTask(id: 3, parentId: 1);
          final otherRootTask = _createTask(id: 4);
          final flattenedTasks = [
            FlattenedTaskNode(parentTask, 0),
            FlattenedTaskNode(draggedTask, 1),
            FlattenedTaskNode(siblingTask, 1),
            FlattenedTaskNode(otherRootTask, 0),
          ];
          final filteredTasks = [
            parentTask,
            draggedTask,
            siblingTask,
            otherRootTask,
          ];

          // 拖动到其他根任务（hoveredTaskId 是 otherRootTask）
          final result = TaskListExpansionDetector.isMovedOutOfExpandedArea(
            draggedTask,
            4, // hoveredTaskId (otherRootTask)
            null,
            flattenedTasks,
            filteredTasks,
          );

          expect(result, true);
        },
      );

      test(
        'should return false when dragged subtask hovers over insertion index within parent area',
        () {
          final parentTask = _createTask(id: 1);
          final draggedTask = _createTask(id: 2, parentId: 1);
          final siblingTask = _createTask(id: 3, parentId: 1);
          final flattenedTasks = [
            FlattenedTaskNode(parentTask, 0),
            FlattenedTaskNode(draggedTask, 1),
            FlattenedTaskNode(siblingTask, 1),
          ];
          final filteredTasks = [parentTask, draggedTask, siblingTask];

          // 拖动到插入索引 2（在父任务的子任务范围内）
          final result = TaskListExpansionDetector.isMovedOutOfExpandedArea(
            draggedTask,
            null, // hoveredTaskId
            2, // hoveredInsertionIndex (在 siblingTask 之后)
            flattenedTasks,
            filteredTasks,
          );

          expect(result, false);
        },
      );

      test(
        'should return true when dragged subtask hovers over insertion index outside parent area',
        () {
          final parentTask = _createTask(id: 1);
          final draggedTask = _createTask(id: 2, parentId: 1);
          final siblingTask = _createTask(id: 3, parentId: 1);
          final otherRootTask = _createTask(id: 4);
          final flattenedTasks = [
            FlattenedTaskNode(parentTask, 0),
            FlattenedTaskNode(draggedTask, 1),
            FlattenedTaskNode(siblingTask, 1),
            FlattenedTaskNode(otherRootTask, 0),
          ];
          final filteredTasks = [
            parentTask,
            draggedTask,
            siblingTask,
            otherRootTask,
          ];

          // 拖动到插入索引 4（在 otherRootTask 之后，超出了父任务扩展区）
          // parentTask 在索引 0，扩展区是索引 1 到 2+1=3
          // 插入索引 4 > lastChildIndex+1 (3)，所以超出扩展区
          final result = TaskListExpansionDetector.isMovedOutOfExpandedArea(
            draggedTask,
            null, // hoveredTaskId
            4, // hoveredInsertionIndex (在 otherRootTask 之后，超出扩展区)
            flattenedTasks,
            filteredTasks,
          );

          expect(result, true);
        },
      );

      test(
        'should return true when dragged subtask hovers over its parent (parent is not in expanded area)',
        () {
          final parentTask = _createTask(id: 1);
          final draggedTask = _createTask(id: 2, parentId: 1);
          final flattenedTasks = [
            FlattenedTaskNode(parentTask, 0),
            FlattenedTaskNode(draggedTask, 1),
          ];
          final filteredTasks = [parentTask, draggedTask];

          // 拖动到父任务上
          // 根据代码逻辑，扩展区范围是 parentIndex+1 到 lastChildIndex
          // 父任务本身在 parentIndex，不在扩展区内，所以应该返回 true
          final result = TaskListExpansionDetector.isMovedOutOfExpandedArea(
            draggedTask,
            1, // hoveredTaskId (parentTask)
            null,
            flattenedTasks,
            filteredTasks,
          );

          // 父任务不在扩展区内（扩展区从 parentIndex+1 开始）
          expect(result, true);
        },
      );

      test('should handle nested subtask (three levels)', () {
        final rootTask = _createTask(id: 1);
        final parentTask = _createTask(id: 2, parentId: 1);
        final draggedTask = _createTask(id: 3, parentId: 2);
        final siblingTask = _createTask(id: 4, parentId: 2);
        final otherRootTask = _createTask(id: 5);
        // 注意：parentTask 的父任务是 rootTask，所以我们需要确保 rootTask 展开以显示 parentTask
        // 但 draggedTask 的父任务是 parentTask，所以我们需要 parentTask 展开以显示 draggedTask 和 siblingTask
        final flattenedTasks = [
          FlattenedTaskNode(rootTask, 0),
          FlattenedTaskNode(parentTask, 1), // parentTask 是 rootTask 的子任务
          FlattenedTaskNode(draggedTask, 2), // draggedTask 是 parentTask 的子任务
          FlattenedTaskNode(siblingTask, 2), // siblingTask 是 parentTask 的子任务
          FlattenedTaskNode(otherRootTask, 0),
        ];
        final filteredTasks = [
          rootTask,
          parentTask,
          draggedTask,
          siblingTask,
          otherRootTask,
        ];

        // 拖动到其他根任务（超出父任务 parentTask 的扩展区范围）
        // parentTask 的扩展区是索引 2-3（draggedTask 和 siblingTask）
        // otherRootTask 在索引 4，超出扩展区
        final result = TaskListExpansionDetector.isMovedOutOfExpandedArea(
          draggedTask,
          5, // hoveredTaskId (otherRootTask)
          null,
          flattenedTasks,
          filteredTasks,
        );

        expect(result, true);
      });

      test(
        'should throw StateError when parent task not found in filteredTasks',
        () {
          final draggedTask = _createTask(id: 1, parentId: 99);
          final flattenedTasks = <FlattenedTaskNode>[];
          final filteredTasks = [draggedTask]; // 不包含父任务 99

          expect(
            () => TaskListExpansionDetector.isMovedOutOfExpandedArea(
              draggedTask,
              null,
              null,
              flattenedTasks,
              filteredTasks,
            ),
            throwsStateError,
          );
        },
      );
    });
  });
}
