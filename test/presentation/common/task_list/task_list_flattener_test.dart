import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/presentation/common/task_list/task_list_flattener.dart';
import 'package:granoflow/presentation/tasks/utils/tree_flattening_utils.dart';

/// 创建测试任务辅助函数
Task _createTask({
  required int id,
  int? parentId,
}) {
  return Task(
    id: id,
    taskId: 'task-$id',
    title: 'Task $id',
    status: TaskStatus.pending,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    parentId: parentId,
    sortIndex: 1000,
    tags: const [],
  );
}

/// 创建测试树节点辅助函数
TaskTreeNode _createNode(Task task, List<TaskTreeNode> children) {
  return TaskTreeNode(task: task, children: children);
}

void main() {
  group('TaskListFlattener', () {
    group('flattenTreeWithExpansion', () {
      test('should flatten single task', () {
        final task = _createTask(id: 1);
        final node = _createNode(task, []);
        final expandedTaskIds = <int>{};

        final result = TaskListFlattener.flattenTreeWithExpansion(
          node,
          expandedTaskIds: expandedTaskIds,
        );

        expect(result.length, 1);
        expect(result[0].task.id, 1);
        expect(result[0].depth, 0);
      });

      test('should not include children when parent is not expanded', () {
        final task1 = _createTask(id: 1);
        final task2 = _createTask(id: 2, parentId: 1);
        final task3 = _createTask(id: 3, parentId: 1);
        final node = _createNode(
          task1,
          [
            _createNode(task2, []),
            _createNode(task3, []),
          ],
        );
        final expandedTaskIds = <int>{}; // 任务1未展开

        final result = TaskListFlattener.flattenTreeWithExpansion(
          node,
          expandedTaskIds: expandedTaskIds,
        );

        expect(result.length, 1);
        expect(result[0].task.id, 1);
        expect(result[0].depth, 0);
      });

      test('should include children when parent is expanded', () {
        final task1 = _createTask(id: 1);
        final task2 = _createTask(id: 2, parentId: 1);
        final task3 = _createTask(id: 3, parentId: 1);
        final node = _createNode(
          task1,
          [
            _createNode(task2, []),
            _createNode(task3, []),
          ],
        );
        final expandedTaskIds = {1}; // 任务1已展开

        final result = TaskListFlattener.flattenTreeWithExpansion(
          node,
          expandedTaskIds: expandedTaskIds,
        );

        expect(result.length, 3);
        expect(result[0].task.id, 1);
        expect(result[0].depth, 0);
        expect(result[1].task.id, 2);
        expect(result[1].depth, 1);
        expect(result[2].task.id, 3);
        expect(result[2].depth, 1);
      });

      test('should calculate depth correctly for nested tasks', () {
        final task1 = _createTask(id: 1);
        final task2 = _createTask(id: 2, parentId: 1);
        final task3 = _createTask(id: 3, parentId: 2);
        final node = _createNode(
          task1,
          [
            _createNode(
              task2,
              [
                _createNode(task3, []),
              ],
            ),
          ],
        );
        final expandedTaskIds = {1, 2}; // 任务1和2都已展开

        final result = TaskListFlattener.flattenTreeWithExpansion(
          node,
          expandedTaskIds: expandedTaskIds,
        );

        expect(result.length, 3);
        expect(result[0].task.id, 1);
        expect(result[0].depth, 0);
        expect(result[1].task.id, 2);
        expect(result[1].depth, 1);
        expect(result[2].task.id, 3);
        expect(result[2].depth, 2);
      });

      test('should only expand immediate children when nested parent is collapsed', () {
        final task1 = _createTask(id: 1);
        final task2 = _createTask(id: 2, parentId: 1);
        final task3 = _createTask(id: 3, parentId: 2);
        final node = _createNode(
          task1,
          [
            _createNode(
              task2,
              [
                _createNode(task3, []),
              ],
            ),
          ],
        );
        final expandedTaskIds = {1}; // 只有任务1展开，任务2未展开

        final result = TaskListFlattener.flattenTreeWithExpansion(
          node,
          expandedTaskIds: expandedTaskIds,
        );

        expect(result.length, 2); // 只有任务1和2
        expect(result[0].task.id, 1);
        expect(result[0].depth, 0);
        expect(result[1].task.id, 2);
        expect(result[1].depth, 1);
        // 任务3不应该出现，因为任务2未展开
      });

      test('should handle multiple root nodes', () {
        final task1 = _createTask(id: 1);
        final task2 = _createTask(id: 2);
        final node1 = _createNode(task1, []);
        final node2 = _createNode(task2, []);
        final expandedTaskIds = <int>{};

        // 注意：flattenTreeWithExpansion 只处理单个节点
        // 多个根节点需要在外部循环调用
        final result1 = TaskListFlattener.flattenTreeWithExpansion(
          node1,
          expandedTaskIds: expandedTaskIds,
        );
        final result2 = TaskListFlattener.flattenTreeWithExpansion(
          node2,
          expandedTaskIds: expandedTaskIds,
        );

        expect(result1.length, 1);
        expect(result1[0].task.id, 1);
        expect(result2.length, 1);
        expect(result2[0].task.id, 2);
      });

      test('should handle empty children list', () {
        final task = _createTask(id: 1);
        final node = _createNode(task, []);
        final expandedTaskIds = <int>{};

        final result = TaskListFlattener.flattenTreeWithExpansion(
          node,
          expandedTaskIds: expandedTaskIds,
        );

        expect(result.length, 1);
        expect(result[0].task.id, 1);
        expect(result[0].depth, 0);
      });

      test('should handle partial expansion', () {
        final task1 = _createTask(id: 1);
        final task2 = _createTask(id: 2, parentId: 1);
        final task3 = _createTask(id: 3, parentId: 1);
        final task4 = _createTask(id: 4, parentId: 2);
        final node = _createNode(
          task1,
          [
            _createNode(
              task2,
              [
                _createNode(task4, []),
              ],
            ),
            _createNode(task3, []),
          ],
        );
        final expandedTaskIds = {1}; // 只有任务1展开

        final result = TaskListFlattener.flattenTreeWithExpansion(
          node,
          expandedTaskIds: expandedTaskIds,
        );

        expect(result.length, 3); // 任务1、2、3
        expect(result[0].task.id, 1);
        expect(result[0].depth, 0);
        expect(result[1].task.id, 2);
        expect(result[1].depth, 1);
        expect(result[2].task.id, 3);
        expect(result[2].depth, 1);
        // 任务4不应该出现，因为任务2未展开
      });

      test('should handle custom starting depth', () {
        final task = _createTask(id: 1);
        final node = _createNode(task, []);
        final expandedTaskIds = <int>{};

        final result = TaskListFlattener.flattenTreeWithExpansion(
          node,
          depth: 2, // 自定义起始深度
          expandedTaskIds: expandedTaskIds,
        );

        expect(result.length, 1);
        expect(result[0].task.id, 1);
        expect(result[0].depth, 2);
      });
    });
  });
}

