import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/presentation/common/task_list/task_list_tree_builder.dart';

/// 创建测试任务辅助函数
Task _createTask({
  required String id,
  double sortIndex = 1000,
  String? projectId,
  String? milestoneId,
}) {
  return Task(
    id: id,

    title: 'Task $id',
    status: TaskStatus.pending,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    
    sortIndex: sortIndex,
    projectId: projectId,
    milestoneId: milestoneId,
    tags: const [],
  );
}

void main() {
  group('TaskListTreeBuilder', () {
    group('buildTaskTree', () {
      test('should build tree with root tasks only', () {
        final tasks = [
          _createTask(id: '1'),
          _createTask(id: '2'),
          _createTask(id: '3'),
        ];

        final trees = TaskListTreeBuilder.buildTaskTree(tasks);

        expect(trees.length, 3);
        expect(trees[0].task.id, '1');
        expect(trees[1].task.id, '2');
        expect(trees[2].task.id, '3');
        expect(trees[0].children, isEmpty);
        expect(trees[1].children, isEmpty);
        expect(trees[2].children, isEmpty);
      });

      test('should build tree without parent-child relationships (hierarchy removed)', () {
        final tasks = [
          _createTask(id: '1'),
          _createTask(id: '2'),
          _createTask(id: '3'),
        ];

        final trees = TaskListTreeBuilder.buildTaskTree(tasks);

        // 层级功能已移除，所有任务都是根任务
        expect(trees.length, 3);
        expect(trees[0].task.id, '1');
        expect(trees[0].children, isEmpty);
        expect(trees[1].task.id, '2');
        expect(trees[1].children, isEmpty);
        expect(trees[2].task.id, '3');
        expect(trees[2].children, isEmpty);
      });

      test('should build tree with multiple root tasks and children', () {
        final tasks = [
          _createTask(id: '1'),
          _createTask(id: '2'),
          _createTask(id: '3'),
          _createTask(id: '4'),
          _createTask(id: '5'),
        ];

        final trees = TaskListTreeBuilder.buildTaskTree(tasks);

        // 层级功能已移除，所有任务都是根任务
        expect(trees.length, 5);
        expect(trees[0].task.id, '1');
        expect(trees[1].task.id, '2');
        expect(trees[2].task.id, '3');
        expect(trees[3].task.id, '4');
        expect(trees[4].task.id, '5');
        // 所有任务都没有子任务
        for (final tree in trees) {
          expect(tree.children, isEmpty);
        }
      });

      test('should exclude project tasks from children', () {
        final tasks = [
          _createTask(id: '1'),
          _createTask(id: '2',  projectId: 'project-1'),
        ];

        final trees = TaskListTreeBuilder.buildTaskTree(tasks);

        expect(trees.length, 1);
        expect(trees[0].task.id, '1');
        expect(trees[0].children, isEmpty);
      }, skip: '任务列表新策略允许 project 任务在根层显示，待确定后重写');

      test('should exclude milestone tasks from children', () {
        final tasks = [
          _createTask(id: '1'),
          _createTask(id: '2',  milestoneId: 'milestone-1'),
        ];

        final trees = TaskListTreeBuilder.buildTaskTree(tasks);

        expect(trees.length, 1);
        expect(trees[0].task.id, '1');
        expect(trees[0].children, isEmpty);
      }, skip: '任务树展示规则已更新，不再按 milestone 过滤，待新逻辑确定后重写');

      test('should sort children by sortIndex', () {
        final tasks = [
          _createTask(id: '1'),
          _createTask(id: '2',  sortIndex: 3000),
          _createTask(id: '3',  sortIndex: 1000),
          _createTask(id: '4',  sortIndex: 2000),
        ];

        final trees = TaskListTreeBuilder.buildTaskTree(tasks);

        expect(trees[0].children.length, 3);
        expect(trees[0].children[0].task.id, '3'); // sortIndex: 1000
        expect(trees[0].children[1].task.id, '4'); // sortIndex: 2000
        expect(trees[0].children[2].task.id, '2'); // sortIndex: 3000
      }, skip: '层级视图已移除 children 排序逻辑，将在新方案确定后补充测试');

      test('should handle empty task list', () {
        final tasks = <Task>[];

        final trees = TaskListTreeBuilder.buildTaskTree(tasks);

        expect(trees, isEmpty);
      });

      test('should handle tasks without nesting (hierarchy removed)', () {
        final tasks = [
          _createTask(id: '1'),
          _createTask(id: '2'),
          _createTask(id: '3'),
        ];

        final trees = TaskListTreeBuilder.buildTaskTree(tasks);
        
        // 层级功能已移除，所有任务都是根任务
        expect(trees.length, 3);
        expect(trees[0].task.id, '1');
        expect(trees[0].children, isEmpty);
        expect(trees[1].task.id, '2');
        expect(trees[1].children, isEmpty);
        expect(trees[2].task.id, '3');
        expect(trees[2].children, isEmpty);
      });
    });

    group('buildSubtree', () {
      test('should build subtree with single task', () {
        final task = _createTask(id: '1');
        final byId = {'1': task};

        final node = TaskListTreeBuilder.buildSubtree(task, byId);

        expect(node.task.id, '1');
        expect(node.children, isEmpty);
      });

      test('should build subtree without children (hierarchy removed)', () {
        final task1 = _createTask(id: '1');
        final task2 = _createTask(id: '2');
        final task3 = _createTask(id: '3');
        final byId = {'1': task1, '2': task2, '3': task3};

        final node = TaskListTreeBuilder.buildSubtree(task1, byId);

        // 层级功能已移除，不再有子任务
        expect(node.task.id, '1');
        expect(node.children, isEmpty);
      });

      test('should build subtree without nested children (hierarchy removed)', () {
        final task1 = _createTask(id: '1');
        final task2 = _createTask(id: '2');
        final task3 = _createTask(id: '3');
        final byId = {'1': task1, '2': task2, '3': task3};

        final node = TaskListTreeBuilder.buildSubtree(task1, byId);

        // 层级功能已移除，不再有嵌套子任务
        expect(node.task.id, '1');
        expect(node.children, isEmpty);
      });
    });

    group('populateHasChildrenMap', () {
      test('should mark task with children as true', () {
        final task1 = _createTask(id: '1');
        final task2 = _createTask(id: '2');
        final node = TaskTreeNode(
          task: task1,
          children: [TaskTreeNode(task: task2, children: const [])],
        );
        final map = <String, bool>{};
        final allTasks = [task1, task2];

        TaskListTreeBuilder.populateHasChildrenMap(node, map, allTasks);

        expect(map['1'], true);
        expect(map['2'], false);
      });

      test('should mark task without children as false', () {
        final task = _createTask(id: '1');
        final node = TaskTreeNode(task: task, children: const []);
        final map = <String, bool>{};
        final allTasks = [task];

        TaskListTreeBuilder.populateHasChildrenMap(node, map, allTasks);

        expect(map['1'], false);
      });

      test('should recursively populate map for nested trees', () {
        final task1 = _createTask(id: '1');
        final task2 = _createTask(id: '2');
        final task3 = _createTask(id: '3');
        final node = TaskTreeNode(
          task: task1,
          children: [
            TaskTreeNode(
              task: task2,
              children: [TaskTreeNode(task: task3, children: const [])],
            ),
          ],
        );
        final map = <String, bool>{};
        final allTasks = [task1, task2, task3];

        TaskListTreeBuilder.populateHasChildrenMap(node, map, allTasks);

        expect(map['1'], true);
        expect(map['2'], true);
        expect(map['3'], false);
      });

      test('should handle empty tree', () {
        final task = _createTask(id: '1');
        final node = TaskTreeNode(task: task, children: const []);
        final map = <String, bool>{};
        final allTasks = [task];

        TaskListTreeBuilder.populateHasChildrenMap(node, map, allTasks);

        expect(map['1'], false);
        expect(map.length, 1);
      });
    });
  });
}
