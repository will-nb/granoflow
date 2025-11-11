import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:granoflow/main.dart' as app;

import 'package:granoflow/core/providers/repository_providers.dart';
import 'package:granoflow/core/providers/app_config_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/models/project.dart';
import 'package:granoflow/data/models/milestone.dart';
import 'package:granoflow/core/services/project_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Drift Integration Tests', () {
    testWidgets(
      'should create, edit, and delete tasks',
      (WidgetTester tester) async {
        // 启动应用
        app.main();
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        // 验证应用已加载
        expect(find.byType(MaterialApp), findsOneWidget);

        // 等待应用启动和界面加载
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(seconds: 1));
        }

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
        ]);
        await container.read(projectServiceProvider.future);
        await container.read(metricOrchestratorProvider.future);
        await container.read(seedImportServiceProvider.future);

        // 等待种子导入完成
        try {
          await container.read(seedInitializerProvider.future).timeout(
            const Duration(seconds: 120),
          );
        } catch (e) {
          // 如果种子导入失败，继续测试（可能已经导入过）
          print('Seed import may have failed or already completed: $e');
        }

        final taskRepository = await container.read(taskRepositoryProvider.future);

        // 测试创建任务
        final taskDraft = TaskDraft(
          title: 'Test Task',
          description: 'Test Description',
          status: TaskStatus.pending,
        );
        final createdTask = await taskRepository.createTask(taskDraft);
        expect(createdTask.id, isNotEmpty);
        expect(createdTask.title, equals('Test Task'));
        expect(createdTask.description, equals('Test Description'));
        expect(createdTask.status, equals(TaskStatus.pending));

        // 验证任务已保存
        final retrievedTask = await taskRepository.findById(createdTask.id);
        expect(retrievedTask, isNotNull);
        expect(retrievedTask!.title, equals('Test Task'));

        // 测试编辑任务
        final update = TaskUpdate(
          title: 'Updated Task',
          description: 'Updated Description',
        );
        await taskRepository.updateTask(createdTask.id, update);

        // 验证任务已更新
        final retrievedUpdatedTask = await taskRepository.findById(createdTask.id);
        expect(retrievedUpdatedTask, isNotNull);
        expect(retrievedUpdatedTask!.title, equals('Updated Task'));
        expect(retrievedUpdatedTask!.description, equals('Updated Description'));

        // 测试删除任务
        await taskRepository.softDelete(createdTask.id);

        // 验证任务已删除（软删除，状态变为 trashed）
        final deletedTask = await taskRepository.findById(createdTask.id);
        expect(deletedTask, isNotNull);
        expect(deletedTask!.status, equals(TaskStatus.trashed));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'should create, edit, and delete projects',
      (WidgetTester tester) async {
        // 启动应用
        app.main();
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        // 验证应用已加载
        expect(find.byType(MaterialApp), findsOneWidget);

        // 等待应用启动和界面加载
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(seconds: 1));
        }

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
        ]);
        await container.read(projectServiceProvider.future);
        await container.read(metricOrchestratorProvider.future);
        await container.read(seedImportServiceProvider.future);

        // 等待种子导入完成
        try {
          await container.read(seedInitializerProvider.future).timeout(
            const Duration(seconds: 120),
          );
        } catch (e) {
          print('Seed import may have failed or already completed: $e');
        }

        final projectRepository = await container.read(projectRepositoryProvider.future);
        final projectService = await container.read(projectServiceProvider.future);

        // 测试创建项目
        final projectBlueprint = ProjectBlueprint(
          title: 'Test Project',
          description: 'Test Description',
          dueDate: DateTime.now(),
          tags: const [],
          milestones: const [],
        );
        final createdProject = await projectService.createProject(projectBlueprint);
        expect(createdProject.id, isNotEmpty);
        expect(createdProject.title, equals('Test Project'));
        expect(createdProject.description, equals('Test Description'));

        // 验证项目已保存
        final retrievedProject = await projectRepository.findById(createdProject.id);
        expect(retrievedProject, isNotNull);
        expect(retrievedProject!.title, equals('Test Project'));

        // 测试编辑项目
        final update = ProjectUpdate(
          title: 'Updated Project',
          description: 'Updated Description',
        );
        await projectService.updateProject(createdProject.id, update);

        // 验证项目已更新
        final retrievedUpdatedProject = await projectRepository.findById(createdProject.id);
        expect(retrievedUpdatedProject, isNotNull);
        expect(retrievedUpdatedProject!.title, equals('Updated Project'));
        expect(retrievedUpdatedProject!.description, equals('Updated Description'));

        // 测试删除项目
        await projectService.deleteProject(createdProject.id);

        // 验证项目已删除
        final deletedProject = await projectRepository.findById(createdProject.id);
        expect(deletedProject, isNull);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'should create, edit, and delete milestones',
      (WidgetTester tester) async {
        // 启动应用
        app.main();
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        // 验证应用已加载
        expect(find.byType(MaterialApp), findsOneWidget);

        // 等待应用启动和界面加载
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(seconds: 1));
        }

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
        ]);
        await container.read(projectServiceProvider.future);
        await container.read(metricOrchestratorProvider.future);
        await container.read(seedImportServiceProvider.future);

        // 等待种子导入完成
        try {
          await container.read(seedInitializerProvider.future).timeout(
            const Duration(seconds: 120),
          );
        } catch (e) {
          print('Seed import may have failed or already completed: $e');
        }

        final projectService = await container.read(projectServiceProvider.future);
        final milestoneRepository = await container.read(milestoneRepositoryProvider.future);
        final milestoneService = await container.read(milestoneServiceProvider.future);

        // 先创建一个项目作为里程碑的父项目
        final projectBlueprint = ProjectBlueprint(
          title: 'Parent Project',
          dueDate: DateTime.now(),
          tags: const [],
          milestones: const [],
        );
        final parentProject = await projectService.createProject(projectBlueprint);

        // 测试创建里程碑
        final createdMilestone = await milestoneService.createMilestone(
          projectId: parentProject.id,
          title: 'Test Milestone',
          description: 'Test Description',
        );
        expect(createdMilestone.id, isNotEmpty);
        expect(createdMilestone.title, equals('Test Milestone'));
        expect(createdMilestone.description, equals('Test Description'));
        expect(createdMilestone.projectId, equals(parentProject.id));

        // 验证里程碑已保存
        final retrievedMilestone = await milestoneRepository.findById(createdMilestone.id);
        expect(retrievedMilestone, isNotNull);
        expect(retrievedMilestone!.title, equals('Test Milestone'));

        // 测试编辑里程碑
        await milestoneService.updateMilestone(
          id: createdMilestone.id,
          title: 'Updated Milestone',
          description: 'Updated Description',
        );

        // 验证里程碑已更新
        final retrievedUpdatedMilestone = await milestoneRepository.findById(createdMilestone.id);
        expect(retrievedUpdatedMilestone, isNotNull);
        expect(retrievedUpdatedMilestone!.title, equals('Updated Milestone'));
        expect(retrievedUpdatedMilestone!.description, equals('Updated Description'));

        // 测试删除里程碑
        await milestoneService.delete(createdMilestone.id);

        // 验证里程碑已删除
        final deletedMilestone = await milestoneRepository.findById(createdMilestone.id);
        expect(deletedMilestone, isNull);

        // 清理：删除父项目
        await projectService.deleteProject(parentProject.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'should handle query operations correctly',
      (WidgetTester tester) async {
        // 启动应用
        app.main();
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        // 验证应用已加载
        expect(find.byType(MaterialApp), findsOneWidget);

        // 等待应用启动和界面加载
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(seconds: 1));
        }

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
        ]);
        await container.read(projectServiceProvider.future);
        await container.read(metricOrchestratorProvider.future);
        await container.read(seedImportServiceProvider.future);

        // 等待种子导入完成
        try {
          await container.read(seedInitializerProvider.future).timeout(
            const Duration(seconds: 120),
          );
        } catch (e) {
          print('Seed import may have failed or already completed: $e');
        }

        final taskRepository = await container.read(taskRepositoryProvider.future);
        final projectRepository = await container.read(projectRepositoryProvider.future);
        final taskService = await container.read(taskServiceProvider.future);
        final projectService = await container.read(projectServiceProvider.future);

        // 创建一些测试数据
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
          TaskDraft(title: 'Task 1', status: TaskStatus.pending, projectId: project1.id),
        );
        final task2 = await taskRepository.createTask(
          TaskDraft(title: 'Task 2', status: TaskStatus.pending, projectId: project1.id),
        );
        final task3 = await taskRepository.createTask(
          TaskDraft(title: 'Task 3', status: TaskStatus.pending, projectId: project2.id),
        );

        // 测试查询所有任务
        final allTasks = await taskRepository.listAll();
        expect(allTasks.length, greaterThanOrEqualTo(3));

        // 测试查询所有项目
        final allProjects = await projectRepository.listAll();
        expect(allProjects.length, greaterThanOrEqualTo(2));

        // 测试按项目 ID 查询任务（使用 watchTasksByProjectId 的 Stream）
        final project1TasksStream = taskRepository.watchTasksByProjectId(project1.id);
        final project1Tasks = await project1TasksStream.first;
        expect(project1Tasks.length, greaterThanOrEqualTo(2));
        expect(project1Tasks.any((t) => t.id == task1.id), isTrue);
        expect(project1Tasks.any((t) => t.id == task2.id), isTrue);

        // 测试按项目 ID 查询任务（项目 2）
        final project2TasksStream = taskRepository.watchTasksByProjectId(project2.id);
        final project2Tasks = await project2TasksStream.first;
        expect(project2Tasks.length, greaterThanOrEqualTo(1));
        expect(project2Tasks.any((t) => t.id == task3.id), isTrue);

        // 测试按 ID 查找
        final foundTask = await taskRepository.findById(task1.id);
        expect(foundTask, isNotNull);
        expect(foundTask!.title, equals('Task 1'));

        final foundProject = await projectRepository.findById(project1.id);
        expect(foundProject, isNotNull);
        expect(foundProject!.title, equals('Project 1'));

        // 清理测试数据
        await taskRepository.softDelete(task1.id);
        await taskRepository.softDelete(task2.id);
        await taskRepository.softDelete(task3.id);
        await projectService.deleteProject(project1.id);
        await projectService.deleteProject(project2.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'should handle Stream/watch operations correctly',
      (WidgetTester tester) async {
        // 启动应用
        app.main();
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        // 验证应用已加载
        expect(find.byType(MaterialApp), findsOneWidget);

        // 等待应用启动和界面加载
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(seconds: 1));
        }

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
        ]);
        await container.read(projectServiceProvider.future);
        await container.read(metricOrchestratorProvider.future);
        await container.read(seedImportServiceProvider.future);

        // 等待种子导入完成
        try {
          await container.read(seedInitializerProvider.future).timeout(
            const Duration(seconds: 120),
          );
        } catch (e) {
          print('Seed import may have failed or already completed: $e');
        }

        final taskRepository = await container.read(taskRepositoryProvider.future);
        final projectRepository = await container.read(projectRepositoryProvider.future);
        final taskService = await container.read(taskServiceProvider.future);
        final projectService = await container.read(projectServiceProvider.future);

        // 创建测试项目
        final testProject = await projectService.createProject(
          ProjectBlueprint(
            title: 'Stream Test Project',
            dueDate: DateTime.now(),
            tags: const [],
            milestones: const [],
          ),
        );

        // 创建新任务
        final testTask = await taskRepository.createTask(
          TaskDraft(
            title: 'Stream Test Task',
            status: TaskStatus.pending,
            projectId: testProject.id,
          ),
        );

        // 等待数据写入
        await tester.pump(const Duration(seconds: 1));

        // 验证任务已创建
        final retrievedTask = await taskRepository.findById(testTask.id);
        expect(retrievedTask, isNotNull);
        expect(retrievedTask!.title, equals('Stream Test Task'));

        // 监听任务变化（使用 Stream 的第一个值）
        final taskStream = taskRepository.watchTasksByProjectId(testProject.id);
        final taskList = await taskStream.first.timeout(
          const Duration(seconds: 5),
        );
        expect(taskList.any((t) => t.id == testTask.id), isTrue);

        // 更新任务
        await taskRepository.updateTask(
          testTask.id,
          TaskUpdate(title: 'Updated Stream Test Task'),
        );

        // 等待数据更新
        await tester.pump(const Duration(seconds: 1));

        // 验证任务已更新
        final updatedTask = await taskRepository.findById(testTask.id);
        expect(updatedTask, isNotNull);
        expect(updatedTask!.title, equals('Updated Stream Test Task'));

        // 清理
        await taskRepository.softDelete(testTask.id);
        await projectService.deleteProject(testProject.id);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
