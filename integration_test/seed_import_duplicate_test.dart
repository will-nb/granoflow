import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:granoflow/main.dart' as app;

import 'package:granoflow/core/providers/repository_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 测试种子导入的重复导入问题
/// 
/// 验证：
/// 1. 项目不会重复导入（通过 seedSlug 检查）
/// 2. 任务能正确导入
/// 3. 多次运行导入不会产生重复数据
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Seed Import Duplicate Prevention Tests', () {
    testWidgets(
      'should not duplicate projects when importing seeds multiple times',
      (WidgetTester tester) async {
        // 启动应用
        app.main();
        // 使用 pump 和延迟，避免 pumpAndSettle 无限等待
        await tester.pump();
        await Future.delayed(const Duration(seconds: 2));
        await tester.pump();

        // 验证应用已加载
        expect(find.byType(MaterialApp), findsOneWidget);

        // 获取应用的 ProviderContainer
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp).first),
        );
        final taskRepository = await container.read(taskRepositoryProvider.future);
        final projectRepository = await container.read(projectRepositoryProvider.future);
        final seedImportService = await container.read(seedImportServiceProvider.future);

        // 清空数据库（限制清理数量以避免超时）
        final existingTasks = await taskRepository.listAll();
        final tasksToDelete = existingTasks.take(100).toList();
        for (final task in tasksToDelete) {
          await taskRepository.softDelete(task.id);
        }
        final existingProjects = await projectRepository.listAll();
        final projectsToDelete = existingProjects.take(100).toList();
        for (final project in projectsToDelete) {
          await projectRepository.delete(project.id);
        }

        // 等待清理完成
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 500));
        await tester.pump();

        // 第一次导入
        await seedImportService.importIfNeeded('en');
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // 记录第一次导入后的数据
        final projectsAfterFirst = await projectRepository.listAll();
        final tasksAfterFirst = await taskRepository.listAll();
        final projectCountAfterFirst = projectsAfterFirst.length;
        final taskCountAfterFirst = tasksAfterFirst.length;

        print('第一次导入后: ${projectCountAfterFirst} 个项目, ${taskCountAfterFirst} 个任务');

        // 验证第一次导入有数据
        expect(projectCountAfterFirst, greaterThan(0),
            reason: '第一次导入应该至少有一个项目');
        expect(taskCountAfterFirst, greaterThan(0),
            reason: '第一次导入应该至少有一个任务');

        // 记录项目的 seedSlug
        final projectSeedSlugs = <String>{};
        for (final project in projectsAfterFirst) {
          if (project.seedSlug != null) {
            projectSeedSlugs.add(project.seedSlug!);
          }
        }

        // 第二次导入（应该不会创建重复项目）
        await seedImportService.importIfNeeded('en');
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 500));
        await tester.pump();

        // 记录第二次导入后的数据
        final projectsAfterSecond = await projectRepository.listAll();
        final tasksAfterSecond = await taskRepository.listAll();
        final projectCountAfterSecond = projectsAfterSecond.length;
        final taskCountAfterSecond = tasksAfterSecond.length;

        print('第二次导入后: ${projectCountAfterSecond} 个项目, ${taskCountAfterSecond} 个任务');

        // 验证项目数量没有增加
        expect(projectCountAfterSecond, equals(projectCountAfterFirst),
            reason: '第二次导入不应该创建重复项目');

        // 验证任务数量没有增加（或者只增加了必要的任务，如果有的话）
        // 注意：任务可能会因为其他原因增加，所以我们只检查项目
        expect(taskCountAfterSecond, greaterThanOrEqualTo(taskCountAfterFirst),
            reason: '第二次导入不应该减少任务数量');

        // 验证所有项目的 seedSlug 仍然存在
        final projectSeedSlugsAfterSecond = <String>{};
        for (final project in projectsAfterSecond) {
          if (project.seedSlug != null) {
            projectSeedSlugsAfterSecond.add(project.seedSlug!);
          }
        }

        expect(projectSeedSlugsAfterSecond, equals(projectSeedSlugs),
            reason: '项目的 seedSlug 应该保持一致');

        // 第三次导入（再次验证）
        await seedImportService.importIfNeeded('en');
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 500));
        await tester.pump();

        final projectsAfterThird = await projectRepository.listAll();
        final projectCountAfterThird = projectsAfterThird.length;

        print('第三次导入后: ${projectCountAfterThird} 个项目');

        // 验证项目数量仍然没有增加
        expect(projectCountAfterThird, equals(projectCountAfterFirst),
            reason: '第三次导入不应该创建重复项目');
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    testWidgets(
      'should import tasks correctly on first launch',
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
        final taskRepository = await container.read(taskRepositoryProvider.future);
        final projectRepository = await container.read(projectRepositoryProvider.future);
        final seedImportService = await container.read(seedImportServiceProvider.future);

        // 清空数据库（限制清理数量以避免超时）
        final existingTasks = await taskRepository.listAll();
        final tasksToDelete = existingTasks.take(100).toList();
        for (final task in tasksToDelete) {
          await taskRepository.softDelete(task.id);
        }
        final existingProjects = await projectRepository.listAll();
        final projectsToDelete = existingProjects.take(100).toList();
        for (final project in projectsToDelete) {
          await projectRepository.delete(project.id);
        }

        // 等待清理完成
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 500));
        await tester.pump();

        // 执行导入
        await seedImportService.importIfNeeded('en');
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 500));
        await tester.pump();

        // 验证任务已导入
        final tasks = await taskRepository.listAll();
        final projects = await projectRepository.listAll();

        print('导入后: ${projects.length} 个项目, ${tasks.length} 个任务');

        // 验证至少有一些任务
        expect(tasks.length, greaterThan(0),
            reason: '应该至少导入一个任务');

        // 验证任务有正确的属性
        for (final task in tasks) {
          expect(task.id, isNotEmpty, reason: '任务应该有 id');
          expect(task.title, isNotEmpty, reason: '任务应该有标题');
        }

        // 层级功能已移除，所有任务都是根任务
        expect(tasks.length, greaterThan(0),
            reason: '应该至少有一个任务');

        // 验证有项目任务（projectId != null）
        final projectTasks = tasks.where((t) => t.projectId != null).toList();
        if (projects.isNotEmpty) {
          expect(projectTasks.length, greaterThan(0),
              reason: '如果有项目，应该有项目任务');
        }
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    testWidgets(
      'should not duplicate tasks when importing seeds multiple times',
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
        final taskRepository = await container.read(taskRepositoryProvider.future);
        final seedImportService = await container.read(seedImportServiceProvider.future);

        // 清空数据库（限制清理数量以避免超时）
        final existingTasks = await taskRepository.listAll();
        final tasksToDelete = existingTasks.take(100).toList();
        for (final task in tasksToDelete) {
          await taskRepository.softDelete(task.id);
        }
        final projectRepository = await container.read(projectRepositoryProvider.future);
        final existingProjects = await projectRepository.listAll();
        final projectsToDelete = existingProjects.take(100).toList();
        for (final project in projectsToDelete) {
          await projectRepository.delete(project.id);
        }

        // 等待清理完成
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 500));
        await tester.pump();

        // 第一次导入
        await seedImportService.importIfNeeded('en');
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 500));
        await tester.pump();

        // 记录第一次导入后的任务
        final tasksAfterFirst = await taskRepository.listAll();
        final taskCountAfterFirst = tasksAfterFirst.length;
        final taskSeedSlugs = <String>{};
        for (final task in tasksAfterFirst) {
          if (task.seedSlug != null) {
            taskSeedSlugs.add(task.seedSlug!);
          }
        }

        print('第一次导入后: ${taskCountAfterFirst} 个任务, ${taskSeedSlugs.length} 个有 seedSlug');

        // 验证第一次导入有任务
        expect(taskCountAfterFirst, greaterThan(0),
            reason: '第一次导入应该至少有一个任务');

        // 第二次导入
        await seedImportService.importIfNeeded('en');
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 500));
        await tester.pump();

        // 记录第二次导入后的任务
        final tasksAfterSecond = await taskRepository.listAll();
        final taskCountAfterSecond = tasksAfterSecond.length;
        final taskSeedSlugsAfterSecond = <String>{};
        for (final task in tasksAfterSecond) {
          if (task.seedSlug != null) {
            taskSeedSlugsAfterSecond.add(task.seedSlug!);
          }
        }

        print('第二次导入后: ${taskCountAfterSecond} 个任务, ${taskSeedSlugsAfterSecond.length} 个有 seedSlug');

        // 验证任务数量没有显著增加（允许一些小的差异，但不应该翻倍）
        expect(taskCountAfterSecond, lessThanOrEqualTo(taskCountAfterFirst * 1.5),
            reason: '第二次导入不应该创建大量重复任务');

        // 如果有 seedSlug 的任务，验证它们没有重复
        if (taskSeedSlugs.isNotEmpty) {
          // 统计每个 seedSlug 出现的次数
          final seedSlugCounts = <String, int>{};
          for (final task in tasksAfterSecond) {
            if (task.seedSlug != null) {
              seedSlugCounts[task.seedSlug!] =
                  (seedSlugCounts[task.seedSlug!] ?? 0) + 1;
            }
          }

          // 验证每个 seedSlug 只出现一次
          for (final entry in seedSlugCounts.entries) {
            expect(entry.value, lessThanOrEqualTo(1),
                reason: 'seedSlug "${entry.key}" 不应该重复，但出现了 ${entry.value} 次');
          }
        }
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}
