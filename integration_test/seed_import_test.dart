import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:granoflow/main.dart' as app;

import 'package:granoflow/core/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Seed Import Integration Tests', () {
    testWidgets(
      'should import projects, milestones, and tasks on first launch',
      (WidgetTester tester) async {
        // 启动应用
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // 验证应用已加载
        expect(find.byType(MaterialApp), findsOneWidget);

        // 获取应用的 ProviderContainer
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp).first),
        );
        final taskRepository = container.read(taskRepositoryProvider);
        final projectRepository = container.read(projectRepositoryProvider);
        final milestoneRepository = container.read(milestoneRepositoryProvider);

        // 清空数据库（在应用启动后）
        final existingTasks = await taskRepository.listAll();
        for (final task in existingTasks) {
          await taskRepository.softDelete(task.id);
        }
        final existingProjects = await projectRepository.listAll();
        for (final project in existingProjects) {
          await projectRepository.delete(project.id);
        }
        final existingMilestones = await milestoneRepository.listAll();
        for (final milestone in existingMilestones) {
          await milestoneRepository.delete(milestone.id);
        }

        // 应用已经在 setUpAll 中启动，等待界面加载
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // 等待种子导入完成
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // 验证项目已导入
        final projects = await projectRepository.listAll();
        expect(projects.length, greaterThan(0), reason: '应该至少导入一个项目');

        // 验证里程碑已导入
        final milestones = await milestoneRepository.listAll();
        expect(milestones.length, greaterThan(0), reason: '应该至少导入一个里程碑');

        // 验证任务已导入
        final tasks = await taskRepository.listAll();
        expect(tasks.length, greaterThan(0), reason: '应该至少导入一个任务');

        // 验证项目有正确的 id（UUID v4 格式）
        for (final project in projects) {
          expect(project.id, isNotEmpty, reason: '项目应该有 id');
          expect(
            project.id,
            matches(
              RegExp(
                r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
                caseSensitive: false,
              ),
            ),
            reason: 'id 应该是 UUID v4 格式',
          );
        }

        // 验证里程碑有正确的 id（UUID v4 格式）和 projectId
        for (final milestone in milestones) {
          expect(
            milestone.id,
            isNotEmpty,
            reason: '里程碑应该有 id',
          );
          expect(
            milestone.id,
            matches(
              RegExp(
                r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
                caseSensitive: false,
              ),
            ),
            reason: 'id 应该是 UUID v4 格式',
          );
          expect(
            milestone.projectId,
            isNotEmpty,
            reason: '里程碑应该有 projectId',
          );

          // 验证 projectId 指向一个存在的项目
          final project = await projectRepository.findById(milestone.projectId);
          expect(project, isNotNull, reason: '里程碑的 projectId 应该指向一个存在的项目');
        }

        // 验证任务有正确的 id（UUID v4 格式）
        for (final task in tasks) {
          expect(task.id, isNotEmpty, reason: '任务应该有 id');
          expect(
            task.id,
            matches(
              RegExp(
                r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
                caseSensitive: false,
              ),
            ),
            reason: 'id 应该是 UUID v4 格式',
          );

          // 如果任务有关联的项目，验证 projectId
          if (task.projectId != null && task.projectId!.isNotEmpty) {
            final project = await projectRepository.findById(task.projectId!);
            expect(
              project,
              isNotNull,
              reason: '任务的 projectId 应该指向一个存在的项目',
            );
          }

          // 如果任务有关联的里程碑，验证 milestoneId
          if (task.milestoneId != null && task.milestoneId!.isNotEmpty) {
            final milestone = await milestoneRepository.findById(task.milestoneId!);
            expect(
              milestone,
              isNotNull,
              reason: '任务的 milestoneId 应该指向一个存在的里程碑',
            );
          }
        }

        // 验证种子项目存在
        final seedProject = projects.firstWhere(
          (p) => p.seedSlug == 'project_new_concept_english_3',
          orElse: () =>
              throw Exception('未找到种子项目 project_new_concept_english_3'),
        );
        expect(seedProject, isNotNull, reason: '应该导入种子项目');

        // 验证种子里程碑存在并关联到项目
        final seedMilestones = milestones
            .where(
              (m) =>
                  m.seedSlug != null &&
                  m.seedSlug!.startsWith('milestone_unit'),
            )
            .toList();
        expect(seedMilestones.length, greaterThan(0), reason: '应该导入种子里程碑');
        for (final milestone in seedMilestones) {
          expect(
            milestone.projectId,
            equals(seedProject.id),
            reason: '里程碑应该关联到种子项目',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'should be idempotent - no duplicate data on second import',
      (WidgetTester tester) async {
        // 启动应用
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // 验证应用已加载
        expect(find.byType(MaterialApp), findsOneWidget);

        // 获取应用的 ProviderContainer
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp).first),
        );
        final taskRepository = container.read(taskRepositoryProvider);
        final projectRepository = container.read(projectRepositoryProvider);
        final milestoneRepository = container.read(milestoneRepositoryProvider);

        // 获取第一次导入后的数据数量
        final projectsBefore = await projectRepository.listAll();
        final milestonesBefore = await milestoneRepository.listAll();
        final tasksBefore = await taskRepository.listAll();

        final projectCountBefore = projectsBefore.length;
        final milestoneCountBefore = milestonesBefore.length;
        final taskCountBefore = tasksBefore.length;

        // 热重启应用（模拟第二次启动）
        await tester.binding.reassembleApplication();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // 验证数据数量没有增加
        final projectsAfter = await projectRepository.listAll();
        final milestonesAfter = await milestoneRepository.listAll();
        final tasksAfter = await taskRepository.listAll();

        expect(
          projectsAfter.length,
          equals(projectCountBefore),
          reason: '项目数量不应该增加',
        );
        expect(
          milestonesAfter.length,
          equals(milestoneCountBefore),
          reason: '里程碑数量不应该增加',
        );
        expect(tasksAfter.length, equals(taskCountBefore), reason: '任务数量不应该增加');
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );
  });
}
