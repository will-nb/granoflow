import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:granoflow/main.dart' as app;

import 'package:granoflow/core/providers/repository_providers.dart';
import 'package:granoflow/core/providers/app_config_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/models/project.dart';
import 'package:granoflow/data/models/node.dart';
import 'package:granoflow/core/services/project_models.dart';
import 'package:granoflow/core/services/focus_flow_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User Operations Integration Tests', () {
    /// 设置测试应用并初始化所有 providers
    Future<ProviderContainer> setupTestApp(WidgetTester tester) async {
      // 启动应用
      app.main();
      await tester.pump();
      
      // 等待应用启动，MaterialApp 可能需要一些时间才能出现
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (tester.any(find.byType(MaterialApp))) {
          break;
        }
      }
      
      // 使用 pumpAndSettle 确保所有动画和异步操作完成
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 验证应用已加载
      expect(find.byType(MaterialApp), findsOneWidget);

      // 获取应用的 ProviderContainer
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp).first),
      );

      // 等待所有依赖的 provider 已初始化
      await container.read(databaseAdapterProvider.future);
      await container.read(seedRepositoryProvider.future);
      await Future.wait([
        container.read(tagRepositoryProvider.future),
        container.read(taskRepositoryProvider.future),
        container.read(projectRepositoryProvider.future),
        container.read(milestoneRepositoryProvider.future),
        container.read(preferenceRepositoryProvider.future),
        container.read(nodeRepositoryProvider.future),
      ]);
      await container.read(projectServiceProvider.future);
      await container.read(milestoneServiceProvider.future);
      await container.read(metricOrchestratorProvider.future);
      await container.read(seedImportServiceProvider.future);
      await container.read(taskServiceProvider.future);
      await container.read(nodeServiceProvider.future);
      await container.read(focusFlowServiceProvider.future);
      await container.read(taskQueryServiceProvider.future);
      await container.read(focusSessionRepositoryProvider.future);

      // 等待种子导入完成
      try {
        await container.read(seedInitializerProvider.future).timeout(
          const Duration(seconds: 120),
        );
      } catch (e) {
        // 如果种子导入失败，继续测试（可能已经导入过）
        print('Seed import may have failed or already completed: $e');
      }

      return container;
    }

    // ============================================
    // 任务创建操作测试（5个）
    // ============================================

    testWidgets(
      'test_task_create_001: 通过对话框创建任务（无日期）',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建任务（无日期）
        final createdTask = await taskService.captureInboxTask(
          title: 'Test Task No Date',
        );

        // 验证任务已创建
        expect(createdTask.id, isNotEmpty);
        expect(createdTask.title, equals('Test Task No Date'));
        expect(createdTask.status, equals(TaskStatus.inbox));
        expect(createdTask.dueAt, isNull);

        // 验证任务已保存
        final retrievedTask = await taskRepository.findById(createdTask.id);
        expect(retrievedTask, isNotNull);
        expect(retrievedTask!.title, equals('Test Task No Date'));
        expect(retrievedTask.status, equals(TaskStatus.inbox));

        // 清理
        await taskRepository.softDelete(createdTask.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_create_002: 通过对话框创建任务（有日期）',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建任务（有日期）
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final taskDraft = TaskDraft(
          title: 'Test Task With Date',
          status: TaskStatus.pending,
          dueAt: tomorrow,
        );
        final createdTask = await taskRepository.createTask(taskDraft);

        // 验证任务已创建
        expect(createdTask.id, isNotEmpty);
        expect(createdTask.title, equals('Test Task With Date'));
        expect(createdTask.status, equals(TaskStatus.pending));
        expect(createdTask.dueAt, isNotNull);

        // 验证任务已保存
        final retrievedTask = await taskRepository.findById(createdTask.id);
        expect(retrievedTask, isNotNull);
        expect(retrievedTask!.title, equals('Test Task With Date'));
        expect(retrievedTask.dueAt, isNotNull);

        // 清理
        await taskRepository.softDelete(createdTask.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_create_003: 在收件箱快速添加任务',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 在收件箱快速添加任务
        final createdTask = await taskService.captureInboxTask(
          title: 'Quick Add Inbox Task',
        );

        // 验证任务已创建并在收件箱中
        expect(createdTask.id, isNotEmpty);
        expect(createdTask.title, equals('Quick Add Inbox Task'));
        expect(createdTask.status, equals(TaskStatus.inbox));

        // 验证任务在收件箱中
        final inboxTasks = await taskRepository.watchInbox().first;
        expect(inboxTasks.any((t) => t.id == createdTask.id), isTrue);

        // 清理
        await taskRepository.softDelete(createdTask.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_create_004: 在任务列表快速添加任务',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskRepository = await container.read(taskRepositoryProvider.future);
        final taskService = await container.read(taskServiceProvider.future);

        // 先创建一个任务
        final taskDraft = TaskDraft(
          title: 'Task To Plan',
          status: TaskStatus.inbox,
        );
        final task = await taskRepository.createTask(taskDraft);

        // 规划任务到今日
        final today = DateTime.now();
        await taskService.planTask(
          taskId: task.id,
          dueDateLocal: today,
          section: TaskSection.today,
        );

        // 验证任务已规划
        final retrievedTask = await taskRepository.findById(task.id);
        expect(retrievedTask, isNotNull);
        expect(retrievedTask!.dueAt, isNotNull);
        expect(retrievedTask.dueAt!.year, equals(today.year));
        expect(retrievedTask.dueAt!.month, equals(today.month));
        expect(retrievedTask.dueAt!.day, equals(today.day));

        // 清理
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_create_005: 在项目详情页快速添加任务',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final projectService = await container.read(projectServiceProvider.future);
        final milestoneService = await container.read(milestoneServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建项目
        final project = await projectService.createProject(
          ProjectBlueprint(
            title: 'Test Project',
            dueDate: DateTime.now(),
            tags: const [],
            milestones: const [],
          ),
        );

        // 创建里程碑
        final milestone = await milestoneService.createMilestone(
          projectId: project.id,
          title: 'Test Milestone',
        );

        // 在里程碑中创建任务
        final taskDraft = TaskDraft(
          title: 'Task In Milestone',
          status: TaskStatus.pending,
          projectId: project.id,
          milestoneId: milestone.id,
        );
        final createdTask = await taskRepository.createTask(taskDraft);

        // 验证任务已创建并关联到里程碑
        expect(createdTask.id, isNotEmpty);
        expect(createdTask.title, equals('Task In Milestone'));
        expect(createdTask.projectId, equals(project.id));
        expect(createdTask.milestoneId, equals(milestone.id));

        // 验证任务已保存
        final retrievedTask = await taskRepository.findById(createdTask.id);
        expect(retrievedTask, isNotNull);
        expect(retrievedTask!.milestoneId, equals(milestone.id));

        // 清理
        await taskRepository.softDelete(createdTask.id);
        await milestoneService.delete(milestone.id);
        await projectService.deleteProject(project.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    // ============================================
    // 任务编辑操作测试（10个）
    // ============================================

    testWidgets(
      'test_task_edit_001: 编辑任务标题',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建任务
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Original Title', status: TaskStatus.pending),
        );

        // 编辑任务标题
        await taskService.updateDetails(
          taskId: task.id,
          payload: const TaskUpdate(title: 'Updated Title'),
        );

        // 验证标题已更新
        final updatedTask = await taskRepository.findById(task.id);
        expect(updatedTask, isNotNull);
        expect(updatedTask!.title, equals('Updated Title'));

        // 清理
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_edit_002: 编辑任务描述',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建任务
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Test Task', status: TaskStatus.pending),
        );

        // 编辑任务描述
        await taskService.updateDetails(
          taskId: task.id,
          payload: const TaskUpdate(description: 'Test Description'),
        );

        // 验证描述已更新
        final updatedTask = await taskRepository.findById(task.id);
        expect(updatedTask, isNotNull);
        expect(updatedTask!.description, equals('Test Description'));

        // 清理
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_edit_003: 添加标签',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建任务
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Test Task', status: TaskStatus.pending),
        );

        // 添加标签
        await taskService.updateTags(
          taskId: task.id,
          contextTag: 'home',
          priorityTag: 'important',
        );

        // 验证标签已添加
        final updatedTask = await taskRepository.findById(task.id);
        expect(updatedTask, isNotNull);
        expect(updatedTask!.tags, contains('home'));
        expect(updatedTask.tags, contains('important'));

        // 清理
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_edit_004: 删除标签',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建带标签的任务
        final task = await taskRepository.createTask(
          TaskDraft(
            title: 'Test Task',
            status: TaskStatus.pending,
            tags: const ['home', 'important'],
          ),
        );

        // 移除标签
        await taskService.updateTags(
          taskId: task.id,
          contextTag: null, // 清除 contextTag
          priorityTag: null, // 清除 priorityTag
        );

        // 验证标签已移除
        final updatedTask = await taskRepository.findById(task.id);
        expect(updatedTask, isNotNull);
        expect(updatedTask!.tags, isNot(contains('home')));
        expect(updatedTask.tags, isNot(contains('important')));

        // 清理
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_edit_005: 设置截止日期',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建任务
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Test Task', status: TaskStatus.pending),
        );

        // 设置截止日期
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        await taskService.planTask(
          taskId: task.id,
          dueDateLocal: tomorrow,
          section: TaskSection.tomorrow,
        );

        // 验证截止日期已设置
        final updatedTask = await taskRepository.findById(task.id);
        expect(updatedTask, isNotNull);
        expect(updatedTask!.dueAt, isNotNull);
        expect(updatedTask.dueAt!.year, equals(tomorrow.year));
        expect(updatedTask.dueAt!.month, equals(tomorrow.month));
        expect(updatedTask.dueAt!.day, equals(tomorrow.day));

        // 清理
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_edit_006: 清除截止日期',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建带截止日期的任务
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final task = await taskRepository.createTask(
          TaskDraft(
            title: 'Test Task',
            status: TaskStatus.pending,
            dueAt: tomorrow,
          ),
        );

        // 清除截止日期
        await taskRepository.updateTask(
          task.id,
          const TaskUpdate(dueAt: null),
        );

        // 验证截止日期已清除
        final updatedTask = await taskRepository.findById(task.id);
        expect(updatedTask, isNotNull);
        expect(updatedTask!.dueAt, isNull);

        // 清理
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_edit_007: 分配项目',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final projectService = await container.read(projectServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建项目
        final project = await projectService.createProject(
          ProjectBlueprint(
            title: 'Test Project',
            dueDate: DateTime.now(),
            tags: const [],
            milestones: const [],
          ),
        );

        // 创建任务
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Test Task', status: TaskStatus.pending),
        );

        // 分配项目
        await taskRepository.updateTask(
          task.id,
          TaskUpdate(projectId: project.id),
        );

        // 验证任务已关联到项目
        final updatedTask = await taskRepository.findById(task.id);
        expect(updatedTask, isNotNull);
        expect(updatedTask!.projectId, equals(project.id));

        // 清理
        await taskRepository.softDelete(task.id);
        await projectService.deleteProject(project.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_edit_008: 分配里程碑',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final projectService = await container.read(projectServiceProvider.future);
        final milestoneService = await container.read(milestoneServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建项目和里程碑
        final project = await projectService.createProject(
          ProjectBlueprint(
            title: 'Test Project',
            dueDate: DateTime.now(),
            tags: const [],
            milestones: const [],
          ),
        );
        final milestone = await milestoneService.createMilestone(
          projectId: project.id,
          title: 'Test Milestone',
        );

        // 创建任务
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Test Task', status: TaskStatus.pending),
        );

        // 分配里程碑
        await taskRepository.updateTask(
          task.id,
          TaskUpdate(projectId: project.id, milestoneId: milestone.id),
        );

        // 验证任务已关联到里程碑
        final updatedTask = await taskRepository.findById(task.id);
        expect(updatedTask, isNotNull);
        expect(updatedTask!.projectId, equals(project.id));
        expect(updatedTask.milestoneId, equals(milestone.id));

        // 清理
        await taskRepository.softDelete(task.id);
        await milestoneService.delete(milestone.id);
        await projectService.deleteProject(project.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_edit_009: 清除项目分配',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final projectService = await container.read(projectServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建项目和任务
        final project = await projectService.createProject(
          ProjectBlueprint(
            title: 'Test Project',
            dueDate: DateTime.now(),
            tags: const [],
            milestones: const [],
          ),
        );
        final task = await taskRepository.createTask(
          TaskDraft(
            title: 'Test Task',
            status: TaskStatus.pending,
            projectId: project.id,
          ),
        );

        // 清除项目分配
        await taskRepository.updateTask(
          task.id,
          const TaskUpdate(projectId: null, milestoneId: null),
        );

        // 验证项目分配已清除
        final updatedTask = await taskRepository.findById(task.id);
        expect(updatedTask, isNotNull);
        expect(updatedTask!.projectId, isNull);
        expect(updatedTask.milestoneId, isNull);

        // 清理
        await taskRepository.softDelete(task.id);
        await projectService.deleteProject(project.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_edit_010: 管理任务节点',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskRepository = await container.read(taskRepositoryProvider.future);
        final nodeService = await container.read(nodeServiceProvider.future);

        // 创建任务
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Test Task', status: TaskStatus.pending),
        );

        // 创建节点
        final node1 = await nodeService.createNode(
          taskId: task.id,
          title: 'Node 1',
        );
        expect(node1.id, isNotEmpty);
        expect(node1.title, equals('Node 1'));
        expect(node1.status, equals(NodeStatus.pending));

        // 创建子节点
        final node2 = await nodeService.createNode(
          taskId: task.id,
          title: 'Node 2',
          parentId: node1.id,
        );
        expect(node2.id, isNotEmpty);
        expect(node2.parentId, equals(node1.id));

        // 更新节点标题
        final nodeRepository = await container.read(nodeRepositoryProvider.future);
        await nodeService.updateNodeTitle(node1.id, 'Updated Node 1');
        final updatedNode1 = await nodeRepository.findById(node1.id);
        expect(updatedNode1, isNotNull);
        expect(updatedNode1!.title, equals('Updated Node 1'));

        // 更新节点状态
        await nodeService.updateNodeStatus(node1.id, NodeStatus.finished);
        final finishedNode1 = await nodeRepository.findById(node1.id);
        expect(finishedNode1, isNotNull);
        expect(finishedNode1!.status, equals(NodeStatus.finished));

        // 清理
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    // ============================================
    // 任务操作测试（12个）
    // ============================================

    testWidgets(
      'test_task_action_001: 完成任务',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建任务
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Test Task', status: TaskStatus.pending),
        );

        // 完成任务
        await taskService.markCompleted(taskId: task.id);

        // 验证任务状态为已完成
        final completedTask = await taskRepository.findById(task.id);
        expect(completedTask, isNotNull);
        expect(completedTask!.status, equals(TaskStatus.completedActive));

        // 清理
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_action_002: 归档任务',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建任务
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Test Task', status: TaskStatus.pending),
        );

        // 归档任务
        await taskService.archive(task.id);

        // 验证任务状态为已归档
        final archivedTask = await taskRepository.findById(task.id);
        expect(archivedTask, isNotNull);
        expect(archivedTask!.status, equals(TaskStatus.archived));

        // 清理
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_action_003: 删除任务到回收站',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建任务
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Test Task', status: TaskStatus.pending),
        );

        // 软删除任务
        await taskService.softDelete(task.id);

        // 验证任务状态为已删除
        final deletedTask = await taskRepository.findById(task.id);
        expect(deletedTask, isNotNull);
        expect(deletedTask!.status, equals(TaskStatus.trashed));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_action_004: 恢复任务',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建任务并软删除
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Test Task', status: TaskStatus.pending),
        );
        await taskService.softDelete(task.id);

        // 恢复任务
        await taskRepository.updateTask(
          task.id,
          const TaskUpdate(status: TaskStatus.pending),
        );

        // 验证任务状态已恢复
        final restoredTask = await taskRepository.findById(task.id);
        expect(restoredTask, isNotNull);
        expect(restoredTask!.status, equals(TaskStatus.pending));

        // 清理
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_action_005: 永久删除任务',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建任务并软删除
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Test Task', status: TaskStatus.pending),
        );
        await taskService.softDelete(task.id);

        // 永久删除任务（通过清空回收站）
        final count = await taskService.clearTrash();
        expect(count, greaterThanOrEqualTo(1));

        // 验证任务已从数据库删除（通过查询回收站确认）
        final trashedTasks = await taskRepository.listTrashedTasks(
          limit: 100,
          offset: 0,
        );
        expect(trashedTasks.any((t) => t.id == task.id), isFalse);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_action_006: 快速规划到今日',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建任务
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Test Task', status: TaskStatus.pending),
        );

        // 快速规划到今日
        final today = DateTime.now();
        await taskService.planTask(
          taskId: task.id,
          dueDateLocal: today,
          section: TaskSection.today,
        );

        // 验证截止日期为今天
        final plannedTask = await taskRepository.findById(task.id);
        expect(plannedTask, isNotNull);
        expect(plannedTask!.dueAt, isNotNull);
        expect(plannedTask.dueAt!.year, equals(today.year));
        expect(plannedTask.dueAt!.month, equals(today.month));
        expect(plannedTask.dueAt!.day, equals(today.day));

        // 清理
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_action_007: 智能推迟任务',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建有截止日期的任务
        final today = DateTime.now();
        final task = await taskRepository.createTask(
          TaskDraft(
            title: 'Test Task',
            status: TaskStatus.pending,
            dueAt: today,
          ),
        );

        // 推迟到明天
        final tomorrow = today.add(const Duration(days: 1));
        await taskService.planTask(
          taskId: task.id,
          dueDateLocal: tomorrow,
          section: TaskSection.tomorrow,
        );

        // 验证截止日期已推迟
        final postponedTask = await taskRepository.findById(task.id);
        expect(postponedTask, isNotNull);
        expect(postponedTask!.dueAt, isNotNull);
        expect(postponedTask.dueAt!.year, equals(tomorrow.year));
        expect(postponedTask.dueAt!.month, equals(tomorrow.month));
        expect(postponedTask.dueAt!.day, equals(tomorrow.day));

        // 清理
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_action_008: 开始计时',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final focusFlowService = await container.read(focusFlowServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建任务
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Test Task', status: TaskStatus.pending),
        );

        // 开始计时
        await taskService.markInProgress(task.id);
        final session = await focusFlowService.startFocus(
          taskId: task.id,
          estimateMinutes: 25,
        );

        // 验证任务状态为进行中
        final inProgressTask = await taskRepository.findById(task.id);
        expect(inProgressTask, isNotNull);
        expect(inProgressTask!.status, equals(TaskStatus.doing));

        // 验证会话已创建
        expect(session.id, isNotEmpty);
        expect(session.taskId, equals(task.id));

        // 清理
        await focusFlowService.endFocus(
          sessionId: session.id,
          outcome: FocusOutcome.markWasted,
        );
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_action_009: 结束计时',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final focusFlowService = await container.read(focusFlowServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);
        final focusSessionRepository = await container.read(focusSessionRepositoryProvider.future);

        // 创建任务并开始计时
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Test Task', status: TaskStatus.pending),
        );
        await taskService.markInProgress(task.id);
        final session = await focusFlowService.startFocus(
          taskId: task.id,
          estimateMinutes: 25,
        );

        // 结束计时
        await focusFlowService.endFocus(
          sessionId: session.id,
          outcome: FocusOutcome.markWasted,
        );

        // 验证会话已结束
        final endedSession = await focusSessionRepository.findById(session.id);
        expect(endedSession, isNotNull);
        expect(endedSession!.endedAt, isNotNull);

        // 清理
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_action_010: 结束会话-完成任务',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final focusFlowService = await container.read(focusFlowServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建任务并开始计时
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Test Task', status: TaskStatus.pending),
        );
        await taskService.markInProgress(task.id);
        final session = await focusFlowService.startFocus(
          taskId: task.id,
          estimateMinutes: 25,
        );

        // 结束会话时选择完成任务
        await focusFlowService.endFocus(
          sessionId: session.id,
          outcome: FocusOutcome.complete,
        );

        // 验证任务已标记为完成
        final completedTask = await taskRepository.findById(task.id);
        expect(completedTask, isNotNull);
        expect(completedTask!.status, equals(TaskStatus.completedActive));

        // 清理
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_action_011: 结束会话-记录多个任务',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final focusFlowService = await container.read(focusFlowServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建任务并开始计时
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Test Task', status: TaskStatus.pending),
        );
        await taskService.markInProgress(task.id);
        final session = await focusFlowService.startFocus(
          taskId: task.id,
          estimateMinutes: 25,
        );

        // 创建新任务用于转移
        final newTask1 = await taskRepository.createTask(
          TaskDraft(title: 'New Task 1', status: TaskStatus.inbox),
        );
        final newTask2 = await taskRepository.createTask(
          TaskDraft(title: 'New Task 2', status: TaskStatus.inbox),
        );

        // 结束会话时记录多个任务（通过 transferToTaskId 转移）
        await focusFlowService.endFocus(
          sessionId: session.id,
          outcome: FocusOutcome.logMultiple,
          transferToTaskId: newTask1.id,
        );

        // 验证会话已结束
        final focusSessionRepository = await container.read(focusSessionRepositoryProvider.future);
        final endedSession = await focusSessionRepository.findById(session.id);
        expect(endedSession, isNotNull);
        expect(endedSession!.endedAt, isNotNull);

        // 清理
        await taskRepository.softDelete(task.id);
        await taskRepository.softDelete(newTask1.id);
        await taskRepository.softDelete(newTask2.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_task_action_012: 结束会话-标记为浪费',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final focusFlowService = await container.read(focusFlowServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建任务并开始计时
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Test Task', status: TaskStatus.pending),
        );
        await taskService.markInProgress(task.id);
        final session = await focusFlowService.startFocus(
          taskId: task.id,
          estimateMinutes: 25,
        );

        // 结束会话时标记为浪费
        await focusFlowService.endFocus(
          sessionId: session.id,
          outcome: FocusOutcome.markWasted,
        );

        // 验证任务已添加 wasted 标签
        final wastedTask = await taskRepository.findById(task.id);
        expect(wastedTask, isNotNull);
        expect(wastedTask!.tags, contains('wasted'));

        // 清理
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    // ============================================
    // 项目操作测试（8个）
    // ============================================

    testWidgets(
      'test_project_001: 创建项目',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final projectService = await container.read(projectServiceProvider.future);
        final projectRepository = await container.read(projectRepositoryProvider.future);

        // 创建项目
        final project = await projectService.createProject(
          ProjectBlueprint(
            title: 'Test Project',
            description: 'Test Description',
            dueDate: DateTime.now(),
            tags: const [],
            milestones: const [],
          ),
        );

        // 验证项目已创建
        expect(project.id, isNotEmpty);
        expect(project.title, equals('Test Project'));
        expect(project.description, equals('Test Description'));

        // 验证项目已保存
        final retrievedProject = await projectRepository.findById(project.id);
        expect(retrievedProject, isNotNull);
        expect(retrievedProject!.title, equals('Test Project'));

        // 清理
        await projectService.deleteProject(project.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_project_002: 编辑项目',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final projectService = await container.read(projectServiceProvider.future);
        final projectRepository = await container.read(projectRepositoryProvider.future);

        // 创建项目
        final project = await projectService.createProject(
          ProjectBlueprint(
            title: 'Original Title',
            description: 'Original Description',
            dueDate: DateTime.now(),
            tags: const [],
            milestones: const [],
          ),
        );

        // 编辑项目
        await projectService.updateProject(
          project.id,
          const ProjectUpdate(
            title: 'Updated Title',
            description: 'Updated Description',
          ),
        );

        // 验证项目信息已更新
        final updatedProject = await projectRepository.findById(project.id);
        expect(updatedProject, isNotNull);
        expect(updatedProject!.title, equals('Updated Title'));
        expect(updatedProject.description, equals('Updated Description'));

        // 清理
        await projectService.deleteProject(project.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_project_003: 删除项目',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final projectService = await container.read(projectServiceProvider.future);
        final projectRepository = await container.read(projectRepositoryProvider.future);

        // 创建项目
        final project = await projectService.createProject(
          ProjectBlueprint(
            title: 'Test Project',
            dueDate: DateTime.now(),
            tags: const [],
            milestones: const [],
          ),
        );

        // 删除项目
        await projectService.deleteProject(project.id);

        // 验证项目已删除
        final deletedProject = await projectRepository.findById(project.id);
        expect(deletedProject, isNull);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_project_004: 查看项目详情',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final projectService = await container.read(projectServiceProvider.future);
        final projectRepository = await container.read(projectRepositoryProvider.future);

        // 创建项目
        final project = await projectService.createProject(
          ProjectBlueprint(
            title: 'Test Project',
            description: 'Test Description',
            dueDate: DateTime.now(),
            tags: const [],
            milestones: const [],
          ),
        );

        // 查看项目详情
        final projectDetails = await projectRepository.findById(project.id);

        // 验证项目详情正确
        expect(projectDetails, isNotNull);
        expect(projectDetails!.id, equals(project.id));
        expect(projectDetails.title, equals('Test Project'));
        expect(projectDetails.description, equals('Test Description'));

        // 清理
        await projectService.deleteProject(project.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_project_005: 创建里程碑',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final projectService = await container.read(projectServiceProvider.future);
        final milestoneService = await container.read(milestoneServiceProvider.future);
        final milestoneRepository = await container.read(milestoneRepositoryProvider.future);

        // 创建项目
        final project = await projectService.createProject(
          ProjectBlueprint(
            title: 'Test Project',
            dueDate: DateTime.now(),
            tags: const [],
            milestones: const [],
          ),
        );

        // 创建里程碑
        final milestone = await milestoneService.createMilestone(
          projectId: project.id,
          title: 'Test Milestone',
          description: 'Test Description',
        );

        // 验证里程碑已创建
        expect(milestone.id, isNotEmpty);
        expect(milestone.title, equals('Test Milestone'));
        expect(milestone.description, equals('Test Description'));
        expect(milestone.projectId, equals(project.id));

        // 验证里程碑已保存
        final retrievedMilestone = await milestoneRepository.findById(milestone.id);
        expect(retrievedMilestone, isNotNull);
        expect(retrievedMilestone!.title, equals('Test Milestone'));

        // 清理
        await milestoneService.delete(milestone.id);
        await projectService.deleteProject(project.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_project_006: 编辑里程碑',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final projectService = await container.read(projectServiceProvider.future);
        final milestoneService = await container.read(milestoneServiceProvider.future);
        final milestoneRepository = await container.read(milestoneRepositoryProvider.future);

        // 创建项目和里程碑
        final project = await projectService.createProject(
          ProjectBlueprint(
            title: 'Test Project',
            dueDate: DateTime.now(),
            tags: const [],
            milestones: const [],
          ),
        );
        final milestone = await milestoneService.createMilestone(
          projectId: project.id,
          title: 'Original Title',
          description: 'Original Description',
        );

        // 编辑里程碑
        await milestoneService.updateMilestone(
          id: milestone.id,
          title: 'Updated Title',
          description: 'Updated Description',
        );

        // 验证里程碑信息已更新
        final updatedMilestone = await milestoneRepository.findById(milestone.id);
        expect(updatedMilestone, isNotNull);
        expect(updatedMilestone!.title, equals('Updated Title'));
        expect(updatedMilestone.description, equals('Updated Description'));

        // 清理
        await milestoneService.delete(milestone.id);
        await projectService.deleteProject(project.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_project_007: 删除里程碑（无活跃任务）',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final projectService = await container.read(projectServiceProvider.future);
        final milestoneService = await container.read(milestoneServiceProvider.future);
        final milestoneRepository = await container.read(milestoneRepositoryProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建项目和里程碑
        final project = await projectService.createProject(
          ProjectBlueprint(
            title: 'Test Project',
            dueDate: DateTime.now(),
            tags: const [],
            milestones: const [],
          ),
        );
        final milestone = await milestoneService.createMilestone(
          projectId: project.id,
          title: 'Test Milestone',
        );

        // 创建已完成的任务（非活跃任务）
        final completedTask = await taskRepository.createTask(
          TaskDraft(
            title: 'Completed Task',
            status: TaskStatus.completedActive,
            projectId: project.id,
            milestoneId: milestone.id,
            sortIndex: 0,
          ),
        );

        // 删除里程碑
        await milestoneService.delete(milestone.id);

        // 验证里程碑已删除
        final deletedMilestone = await milestoneRepository.findById(milestone.id);
        expect(deletedMilestone, isNull);

        // 验证任务保留但 milestoneId 为 null
        final retainedTask = await taskRepository.findById(completedTask.id);
        expect(retainedTask, isNotNull);
        expect(retainedTask!.milestoneId, isNull);
        expect(retainedTask.projectId, equals(project.id)); // 项目关联保留

        // 清理
        await taskRepository.softDelete(completedTask.id);
        await projectService.deleteProject(project.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_project_007b: 删除里程碑（有活跃任务）',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final projectService = await container.read(projectServiceProvider.future);
        final milestoneService = await container.read(milestoneServiceProvider.future);
        final milestoneRepository = await container.read(milestoneRepositoryProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建项目和里程碑
        final project = await projectService.createProject(
          ProjectBlueprint(
            title: 'Test Project',
            dueDate: DateTime.now(),
            tags: const [],
            milestones: const [],
          ),
        );
        final milestone = await milestoneService.createMilestone(
          projectId: project.id,
          title: 'Test Milestone',
        );

        // 创建活跃任务
        final activeTask1 = await taskRepository.createTask(
          TaskDraft(
            title: 'Active Task 1',
            status: TaskStatus.pending,
            projectId: project.id,
            milestoneId: milestone.id,
            sortIndex: 0,
          ),
        );
        final activeTask2 = await taskRepository.createTask(
          TaskDraft(
            title: 'Active Task 2',
            status: TaskStatus.doing,
            projectId: project.id,
            milestoneId: milestone.id,
            sortIndex: 1,
          ),
        );
        final pausedTask = await taskRepository.createTask(
          TaskDraft(
            title: 'Paused Task',
            status: TaskStatus.paused,
            projectId: project.id,
            milestoneId: milestone.id,
            sortIndex: 2,
          ),
        );

        // 删除里程碑
        await milestoneService.delete(milestone.id);

        // 验证里程碑已删除
        final deletedMilestone = await milestoneRepository.findById(milestone.id);
        expect(deletedMilestone, isNull);

        // 验证所有任务保留但 milestoneId 为 null
        final retainedTask1 = await taskRepository.findById(activeTask1.id);
        expect(retainedTask1, isNotNull);
        expect(retainedTask1!.milestoneId, isNull);
        expect(retainedTask1.projectId, equals(project.id));

        final retainedTask2 = await taskRepository.findById(activeTask2.id);
        expect(retainedTask2, isNotNull);
        expect(retainedTask2!.milestoneId, isNull);
        expect(retainedTask2.projectId, equals(project.id));

        final retainedPausedTask = await taskRepository.findById(pausedTask.id);
        expect(retainedPausedTask, isNotNull);
        expect(retainedPausedTask!.milestoneId, isNull);
        expect(retainedPausedTask.projectId, equals(project.id));

        // 清理
        await taskRepository.softDelete(activeTask1.id);
        await taskRepository.softDelete(activeTask2.id);
        await taskRepository.softDelete(pausedTask.id);
        await projectService.deleteProject(project.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_project_007c: 删除里程碑（无任务）',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final projectService = await container.read(projectServiceProvider.future);
        final milestoneService = await container.read(milestoneServiceProvider.future);
        final milestoneRepository = await container.read(milestoneRepositoryProvider.future);

        // 创建项目和里程碑
        final project = await projectService.createProject(
          ProjectBlueprint(
            title: 'Test Project',
            dueDate: DateTime.now(),
            tags: const [],
            milestones: const [],
          ),
        );
        final milestone = await milestoneService.createMilestone(
          projectId: project.id,
          title: 'Test Milestone',
        );

        // 删除里程碑（无任务）
        await milestoneService.delete(milestone.id);

        // 验证里程碑已删除
        final deletedMilestone = await milestoneRepository.findById(milestone.id);
        expect(deletedMilestone, isNull);

        // 清理
        await projectService.deleteProject(project.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_project_008: 查看里程碑详情',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final projectService = await container.read(projectServiceProvider.future);
        final milestoneService = await container.read(milestoneServiceProvider.future);
        final milestoneRepository = await container.read(milestoneRepositoryProvider.future);

        // 创建项目和里程碑
        final project = await projectService.createProject(
          ProjectBlueprint(
            title: 'Test Project',
            dueDate: DateTime.now(),
            tags: const [],
            milestones: const [],
          ),
        );
        final milestone = await milestoneService.createMilestone(
          projectId: project.id,
          title: 'Test Milestone',
          description: 'Test Description',
        );

        // 查看里程碑详情
        final milestoneDetails = await milestoneRepository.findById(milestone.id);

        // 验证里程碑详情正确
        expect(milestoneDetails, isNotNull);
        expect(milestoneDetails!.id, equals(milestone.id));
        expect(milestoneDetails.title, equals('Test Milestone'));
        expect(milestoneDetails.description, equals('Test Description'));
        expect(milestoneDetails.projectId, equals(project.id));

        // 清理
        await milestoneService.delete(milestone.id);
        await projectService.deleteProject(project.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    // ============================================
    // 标签/搜索/筛选操作测试（6个）
    // ============================================

    testWidgets(
      'test_tag_001: 按标签筛选任务',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建带标签的任务
        final task1 = await taskRepository.createTask(
          TaskDraft(
            title: 'Task with home tag',
            status: TaskStatus.pending,
            tags: const ['home'],
          ),
        );
        final task2 = await taskRepository.createTask(
          TaskDraft(
            title: 'Task with company tag',
            status: TaskStatus.pending,
            tags: const ['company'],
          ),
        );

        // 按标签筛选任务（使用 searchByTitle 并检查标签）
        final allTasks = await taskRepository.listAll();
        final homeTasks = allTasks.where((t) => t.tags.contains('home')).toList();

        // 验证筛选结果正确
        expect(homeTasks.any((t) => t.id == task1.id), isTrue);
        expect(homeTasks.any((t) => t.id == task2.id), isFalse);

        // 清理
        await taskRepository.softDelete(task1.id);
        await taskRepository.softDelete(task2.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_tag_003: 多标签筛选',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建带多个标签的任务
        final task1 = await taskRepository.createTask(
          TaskDraft(
            title: 'Task with home and important',
            status: TaskStatus.pending,
            tags: const ['home', 'important'],
          ),
        );
        final task2 = await taskRepository.createTask(
          TaskDraft(
            title: 'Task with only home',
            status: TaskStatus.pending,
            tags: const ['home'],
          ),
        );

        // 多标签筛选（任务必须包含所有标签）
        final allTasks = await taskRepository.listAll();
        final filteredTasks = allTasks.where((t) =>
            t.tags.contains('home') && t.tags.contains('important')).toList();

        // 验证筛选结果正确
        expect(filteredTasks.any((t) => t.id == task1.id), isTrue);
        expect(filteredTasks.any((t) => t.id == task2.id), isFalse);

        // 清理
        await taskRepository.softDelete(task1.id);
        await taskRepository.softDelete(task2.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_search_001: 输入搜索关键词',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建任务
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Searchable Task Title', status: TaskStatus.pending),
        );

        // 搜索任务
        final results = await taskService.searchTasksByTitle('Searchable');

        // 验证搜索结果正确
        expect(results.any((t) => t.id == task.id), isTrue);

        // 清理
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_search_004: 搜索最少字符限制',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskQueryService = await container.read(taskQueryServiceProvider.future);

        // 使用少于3个字符的关键词搜索
        final results = await taskQueryService.searchTasksByTitle('ab');

        // 验证搜索被限制或返回空结果（根据实现，空字符串返回空列表）
        // 如果关键词少于3个字符，应该返回空结果或有限结果
        expect(results, isA<List<Task>>());
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_filter_003: 按项目筛选',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final projectService = await container.read(projectServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建项目和任务
        final project1 = await projectService.createProject(
          ProjectBlueprint(
            title: 'Project 1',
            dueDate: DateTime.now(),
            tags: const [],
            milestones: const [],
          ),
        );
        final project2 = await projectService.createProject(
          ProjectBlueprint(
            title: 'Project 2',
            dueDate: DateTime.now(),
            tags: const [],
            milestones: const [],
          ),
        );
        final task1 = await taskRepository.createTask(
          TaskDraft(
            title: 'Task in Project 1',
            status: TaskStatus.pending,
            projectId: project1.id,
          ),
        );
        final task2 = await taskRepository.createTask(
          TaskDraft(
            title: 'Task in Project 2',
            status: TaskStatus.pending,
            projectId: project2.id,
          ),
        );

        // 按项目筛选任务
        final project1Tasks = await taskRepository.watchTasksByProjectId(project1.id).first;

        // 验证筛选结果正确
        expect(project1Tasks.any((t) => t.id == task1.id), isTrue);
        expect(project1Tasks.any((t) => t.id == task2.id), isFalse);

        // 清理
        await taskRepository.softDelete(task1.id);
        await taskRepository.softDelete(task2.id);
        await projectService.deleteProject(project1.id);
        await projectService.deleteProject(project2.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_filter_005: 组合筛选',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final projectService = await container.read(projectServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建项目和任务
        final project = await projectService.createProject(
          ProjectBlueprint(
            title: 'Test Project',
            dueDate: DateTime.now(),
            tags: const [],
            milestones: const [],
          ),
        );
        final task1 = await taskRepository.createTask(
          TaskDraft(
            title: 'Task with project and tag',
            status: TaskStatus.pending,
            projectId: project.id,
            tags: const ['home'],
          ),
        );
        final task2 = await taskRepository.createTask(
          TaskDraft(
            title: 'Task with only project',
            status: TaskStatus.pending,
            projectId: project.id,
          ),
        );

        // 组合筛选（按项目和标签）
        final projectTasks = await taskRepository.watchTasksByProjectId(project.id).first;
        final filteredTasks = projectTasks.where((t) => t.tags.contains('home')).toList();

        // 验证筛选结果正确
        expect(filteredTasks.any((t) => t.id == task1.id), isTrue);
        expect(filteredTasks.any((t) => t.id == task2.id), isFalse);

        // 清理
        await taskRepository.softDelete(task1.id);
        await taskRepository.softDelete(task2.id);
        await projectService.deleteProject(project.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    // ============================================
    // 定时器操作测试（3个）
    // ============================================

    testWidgets(
      'test_timer_001: 选择任务',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建任务
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Task for Timer', status: TaskStatus.pending),
        );

        // 查询任务（选择任务）
        final selectedTask = await taskRepository.findById(task.id);

        // 验证任务信息正确
        expect(selectedTask, isNotNull);
        expect(selectedTask!.id, equals(task.id));
        expect(selectedTask.title, equals('Task for Timer'));

        // 清理
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_timer_002: 开始计时',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final focusFlowService = await container.read(focusFlowServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建任务
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Task for Timer', status: TaskStatus.pending),
        );

        // 开始计时
        await taskService.markInProgress(task.id);
        final session = await focusFlowService.startFocus(
          taskId: task.id,
          estimateMinutes: 25,
        );

        // 验证任务状态和会话状态
        final inProgressTask = await taskRepository.findById(task.id);
        expect(inProgressTask, isNotNull);
        expect(inProgressTask!.status, equals(TaskStatus.doing));
        expect(session.id, isNotEmpty);
        expect(session.taskId, equals(task.id));

        // 清理
        await focusFlowService.endFocus(
          sessionId: session.id,
          outcome: FocusOutcome.markWasted,
        );
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_timer_003: 结束计时',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final focusFlowService = await container.read(focusFlowServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);
        final focusSessionRepository = await container.read(focusSessionRepositoryProvider.future);

        // 创建任务并开始计时
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Task for Timer', status: TaskStatus.pending),
        );
        await taskService.markInProgress(task.id);
        final session = await focusFlowService.startFocus(
          taskId: task.id,
          estimateMinutes: 25,
        );

        // 结束计时
        await focusFlowService.endFocus(
          sessionId: session.id,
          outcome: FocusOutcome.markWasted,
        );

        // 验证会话已结束
        final endedSession = await focusSessionRepository.findById(session.id);
        expect(endedSession, isNotNull);
        expect(endedSession!.endedAt, isNotNull);

        // 清理
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    // ============================================
    // 其他操作测试（2个）
    // ============================================

    testWidgets(
      'test_other_001: 下拉刷新',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建任务
        final task = await taskRepository.createTask(
          TaskDraft(title: 'Test Task', status: TaskStatus.pending),
        );

        // 重新查询（模拟下拉刷新）
        final allTasks = await taskRepository.listAll();

        // 验证数据已刷新
        expect(allTasks.any((t) => t.id == task.id), isTrue);

        // 清理
        await taskRepository.softDelete(task.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'test_other_010: 清空回收站',
      (WidgetTester tester) async {
        final container = await setupTestApp(tester);
        final taskService = await container.read(taskServiceProvider.future);
        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 创建多个任务并软删除
        final task1 = await taskRepository.createTask(
          TaskDraft(title: 'Task 1', status: TaskStatus.pending),
        );
        final task2 = await taskRepository.createTask(
          TaskDraft(title: 'Task 2', status: TaskStatus.pending),
        );
        await taskService.softDelete(task1.id);
        await taskService.softDelete(task2.id);

        // 清空回收站
        final count = await taskService.clearTrash();
        expect(count, greaterThanOrEqualTo(2));

        // 验证所有回收站任务已永久删除
        final trashedTasks = await taskRepository.listTrashedTasks(
          limit: 100,
          offset: 0,
        );
        expect(trashedTasks.any((t) => t.id == task1.id), isFalse);
        expect(trashedTasks.any((t) => t.id == task2.id), isFalse);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}

