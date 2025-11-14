import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/presentation/common/task_list/task_list_insertion_index_converter.dart';
import 'package:granoflow/presentation/tasks/utils/tree_flattening_utils.dart';

/// 创建测试任务辅助函数
Task _createTask({required String id, double sortIndex = 1000}) {
  return Task(
    id: id,

    title: 'Task $id',
    status: TaskStatus.pending,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    
    sortIndex: sortIndex,
    tags: const [],
  );
}

void main() {
  group('TaskListInsertionIndexConverter', () {
    group('convertFlattenedIndexToRootInsertionIndex', () {
      test('should return 0 for top insertion (index 0)', () {
        final task1 = _createTask(id: '1');
        final task2 = _createTask(id: '2');
        final flattenedTasks = [
          FlattenedTaskNode(task1, 0),
          FlattenedTaskNode(task2, 0),
        ];
        final rootTasks = [task1, task2];
        final taskIdToIndex = {'1': 0, '2': 1};
        final filteredTasks = [task1, task2];

        final result =
            TaskListInsertionIndexConverter.convertFlattenedIndexToRootInsertionIndex(
              0,
              flattenedTasks,
              taskIdToIndex,
              rootTasks,
              filteredTasks,
            );

        expect(result, 0);
      });

      test('should return rootTasks.length for bottom insertion', () {
        final task1 = _createTask(id: '1');
        final task2 = _createTask(id: '2');
        final flattenedTasks = [
          FlattenedTaskNode(task1, 0),
          FlattenedTaskNode(task2, 0),
        ];
        final rootTasks = [task1, task2];
        final taskIdToIndex = {'1': 0, '2': 1};
        final filteredTasks = [task1, task2];

        final result =
            TaskListInsertionIndexConverter.convertFlattenedIndexToRootInsertionIndex(
              2, // 超出列表长度
              flattenedTasks,
              taskIdToIndex,
              rootTasks,
              filteredTasks,
            );

        expect(result, 2); // rootTasks.length
      });

      test('should return root index for root task', () {
        final task1 = _createTask(id: '1');
        final task2 = _createTask(id: '2');
        final flattenedTasks = [
          FlattenedTaskNode(task1, 0),
          FlattenedTaskNode(task2, 0),
        ];
        final rootTasks = [task1, task2];
        final taskIdToIndex = {'1': 0, '2': 1};
        final filteredTasks = [task1, task2];

        final result =
            TaskListInsertionIndexConverter.convertFlattenedIndexToRootInsertionIndex(
              1, // 指向 task2
              flattenedTasks,
              taskIdToIndex,
              rootTasks,
              filteredTasks,
            );

        expect(result, 1); // task2 的根索引
      });

      test('should find root parent for subtask', () {
        final task1 = _createTask(id: '1');
        final task2 = _createTask(id: '2');
        final flattenedTasks = [
          FlattenedTaskNode(task1, 0),
          FlattenedTaskNode(task2, 1), // 子任务
        ];
        final rootTasks = [task1];
        final taskIdToIndex = {'1': 0}; // task2 不在根任务映射中
        final filteredTasks = [task1, task2];

        final result =
            TaskListInsertionIndexConverter.convertFlattenedIndexToRootInsertionIndex(
              1, // 指向 task2（子任务）
              flattenedTasks,
              taskIdToIndex,
              rootTasks,
              filteredTasks,
            );

        expect(result, 1); // 应该返回 task1 的索引 + 1（插入到 task1 之后）
      });

      test('should handle nested subtask (three levels)', () {
        final task1 = _createTask(id: '1');
        final task2 = _createTask(id: '2');
        final task3 = _createTask(id: '3');
        final flattenedTasks = [
          FlattenedTaskNode(task1, 0),
          FlattenedTaskNode(task2, 1),
          FlattenedTaskNode(task3, 2), // 三级任务
        ];
        final rootTasks = [task1];
        final taskIdToIndex = {'1': 0};
        final filteredTasks = [task1, task2, task3];

        final result =
            TaskListInsertionIndexConverter.convertFlattenedIndexToRootInsertionIndex(
              2, // 指向 task3（三级任务）
              flattenedTasks,
              taskIdToIndex,
              rootTasks,
              filteredTasks,
            );

        expect(result, 1); // 应该返回 task1 的索引 + 1
      });

      test('should handle empty root tasks list', () {
        final flattenedTasks = <FlattenedTaskNode>[];
        final rootTasks = <Task>[];
        final taskIdToIndex = <String, int>{};
        final filteredTasks = <Task>[];

        final result =
            TaskListInsertionIndexConverter.convertFlattenedIndexToRootInsertionIndex(
              0,
              flattenedTasks,
              taskIdToIndex,
              rootTasks,
              filteredTasks,
            );

        expect(result, 0);
      });

      test('should throw StateError when parent task not found', () {
        final task1 = _createTask(id: '1');
        final task2 = _createTask(id: '2'); // 父任务不存在
        final flattenedTasks = [
          FlattenedTaskNode(task1, 0),
          FlattenedTaskNode(task2, 1), // 子任务，但父任务不在 filteredTasks 中
        ];
        final rootTasks = [task1];
        final taskIdToIndex = {'1': 0};
        final filteredTasks = [task1, task2]; // task2 的父任务 999 不在列表中

        expect(
          () =>
              TaskListInsertionIndexConverter.convertFlattenedIndexToRootInsertionIndex(
                1, // 指向 task2（子任务）
                flattenedTasks,
                taskIdToIndex,
                rootTasks,
                filteredTasks,
              ),
          throwsStateError,
        );
      }, skip: '层级系统已下线，该场景不再出现，待新结构确认后重写');
    });

    group('findTasksForInsertionIndex', () {
      test('should return first target type for top insertion', () {
        final task1 = _createTask(id: '1');
        final task2 = _createTask(id: '2');
        final flattenedTasks = [
          FlattenedTaskNode(task1, 0),
          FlattenedTaskNode(task2, 0),
        ];
        final rootTasks = [task1, task2];
        final taskIdToIndex = {'1': 0, '2': 1};
        final filteredTasks = [task1, task2];

        final result =
            TaskListInsertionIndexConverter.findTasksForInsertionIndex(
              0,
              flattenedTasks,
              rootTasks,
              taskIdToIndex,
              filteredTasks,
            );

        expect(result.beforeTask, null);
        expect(result.afterTask, task1);
        expect(result.targetType, 'first');
      });

      test('should return last target type for bottom insertion', () {
        final task1 = _createTask(id: '1');
        final task2 = _createTask(id: '2');
        final flattenedTasks = [
          FlattenedTaskNode(task1, 0),
          FlattenedTaskNode(task2, 0),
        ];
        final rootTasks = [task1, task2];
        final taskIdToIndex = {'1': 0, '2': 1};
        final filteredTasks = [task1, task2];

        final result =
            TaskListInsertionIndexConverter.findTasksForInsertionIndex(
              2, // 底部插入
              flattenedTasks,
              rootTasks,
              taskIdToIndex,
              filteredTasks,
            );

        expect(result.beforeTask, task2);
        expect(result.afterTask, null);
        expect(result.targetType, 'last');
      });

      test('should return between target type for middle insertion', () {
        final task1 = _createTask(id: '1');
        final task2 = _createTask(id: '2');
        final task3 = _createTask(id: '3');
        final flattenedTasks = [
          FlattenedTaskNode(task1, 0),
          FlattenedTaskNode(task2, 0),
          FlattenedTaskNode(task3, 0),
        ];
        final rootTasks = [task1, task2, task3];
        final taskIdToIndex = {'1': 0, '2': 1, '3': 2};
        final filteredTasks = [task1, task2, task3];

        final result =
            TaskListInsertionIndexConverter.findTasksForInsertionIndex(
              2, // 插入到 task2 之后
              flattenedTasks,
              rootTasks,
              taskIdToIndex,
              filteredTasks,
            );

        expect(result.beforeTask, task2);
        expect(result.afterTask, task3);
        expect(result.targetType, 'between');
      });

      test('should handle empty root tasks list', () {
        final flattenedTasks = <FlattenedTaskNode>[];
        final rootTasks = <Task>[];
        final taskIdToIndex = <String, int>{};
        final filteredTasks = <Task>[];

        final result =
            TaskListInsertionIndexConverter.findTasksForInsertionIndex(
              0,
              flattenedTasks,
              rootTasks,
              taskIdToIndex,
              filteredTasks,
            );

        expect(result.beforeTask, null);
        expect(result.afterTask, null);
        expect(result.targetType, 'first');
      });

      test('should handle insertion at subtask position', () {
        final task1 = _createTask(id: '1');
        final task2 = _createTask(id: '2');
        final flattenedTasks = [
          FlattenedTaskNode(task1, 0),
          FlattenedTaskNode(task2, 1),
        ];
        final rootTasks = [task1];
        final taskIdToIndex = {'1': 0};
        final filteredTasks = [task1, task2];

        final result =
            TaskListInsertionIndexConverter.findTasksForInsertionIndex(
              1, // 指向子任务 task2
              flattenedTasks,
              rootTasks,
              taskIdToIndex,
              filteredTasks,
            );

        // 应该插入到 task1 之后（因为 task2 是 task1 的子任务）
        expect(result.beforeTask, task1);
        expect(result.afterTask, null);
        expect(result.targetType, 'last');
      });
    });
  });
}
