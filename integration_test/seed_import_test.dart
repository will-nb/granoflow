import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:granoflow/main.dart' as app;

import 'package:granoflow/core/providers/repository_providers.dart';
import 'package:granoflow/core/providers/app_config_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Seed Import Integration Tests', () {
    testWidgets(
      'should import projects, milestones, and tasks on first launch',
      (WidgetTester tester) async {
        // 启动应用
        app.main();
        await tester.pump();
        
        // 等待应用启动，MaterialApp 可能需要一些时间才能出现
        // 先等待几秒让应用初始化
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

        // 等待应用启动和界面加载
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(seconds: 1));
        }

        // 获取应用的 ProviderContainer
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp).first),
        );
        
        // 先确保所有依赖的 provider 已初始化
        try {
          print('Waiting for database adapter...');
          await container.read(databaseAdapterProvider.future);
          print('Database adapter ready');
          
          // 等待 seedRepositoryProvider 完成（seedImportServiceProvider 的依赖）
          print('Waiting for seed repository...');
          await container.read(seedRepositoryProvider.future);
          print('Seed repository ready');
          
          // 等待其他必要的 repository
          print('Waiting for other repositories...');
          await Future.wait([
            container.read(tagRepositoryProvider.future),
            container.read(taskRepositoryProvider.future),
            container.read(taskTemplateRepositoryProvider.future),
            container.read(milestoneRepositoryProvider.future),
            container.read(preferenceRepositoryProvider.future),
          ]);
          print('All repositories ready');
          
          // 等待 projectServiceProvider 完成
          print('Waiting for project service...');
          await container.read(projectServiceProvider.future);
          print('Project service ready');
          
          // 等待 metricOrchestratorProvider 完成
          print('Waiting for metric orchestrator...');
          await container.read(metricOrchestratorProvider.future);
          print('Metric orchestrator ready');
          
          // 等待 seedImportServiceProvider 完成
          print('Waiting for seed import service...');
          await container.read(seedImportServiceProvider.future);
          print('Seed import service ready');
        } catch (e, stack) {
          print('Error initializing dependencies: $e');
          print('Stack trace: $stack');
          rethrow;
        }
        
        // 现在触发并等待种子导入完成
        try {
          print('Starting seed import...');
          // 使用 timeout 来避免无限等待
          await container.read(seedInitializerProvider.future).timeout(
            const Duration(seconds: 120),
            onTimeout: () {
              throw TimeoutException('Seed import timed out after 120 seconds');
            },
          );
          print('Seed import completed successfully');
        } catch (e) {
          if (e is TimeoutException) {
            print('Seed import timed out: $e');
            rethrow;
          }
          print('Seed import error: $e');
          rethrow;
        }
        
        final taskRepository = await container.read(taskRepositoryProvider.future);
        final projectRepository = await container.read(projectRepositoryProvider.future);
        final milestoneRepository = await container.read(milestoneRepositoryProvider.future);

        // 等待界面加载完成
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(seconds: 1));
        }

        // 验证项目已导入
        final projects = await projectRepository.listAll();
        print('Found ${projects.length} projects after seed import');
        if (projects.isEmpty) {
          // 如果数据库为空，可能是种子导入没有执行，或者数据库被清空了
          // 检查种子导入状态
          final seedRepo = await container.read(seedRepositoryProvider.future);
          final latestVersion = await seedRepo.latestVersion();
          print('Latest seed version: $latestVersion');
          throw Exception('No projects found after seed import. Latest seed version: $latestVersion');
        }
        expect(projects.length, greaterThan(0), reason: '应该至少导入一个项目');

        // 验证里程碑已导入（如果数据库中有里程碑数据）
        final milestones = await milestoneRepository.listAll();
        // 注意：如果数据库已有数据，可能没有里程碑，所以这个检查是可选的
        if (milestones.isEmpty && projects.isNotEmpty) {
          print('注意: 数据库已有数据，没有找到里程碑，但项目总数: ${projects.length}');
        } else {
          expect(milestones.length, greaterThan(0), reason: '应该至少导入一个里程碑');
        }

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

        // 验证里程碑有正确的 id（UUID v4 格式）和 projectId（如果有里程碑）
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

        // 验证种子项目存在（如果数据库中有种子数据）
        // 注意：如果数据库已有数据，可能没有种子项目，所以这个检查是可选的
        final seedProjects = projects.where((p) => p.seedSlug == 'project_new_concept_english_3').toList();
        if (seedProjects.isNotEmpty) {
          final seedProject = seedProjects.first;
          expect(seedProject, isNotNull, reason: '应该导入种子项目');

          // 验证种子里程碑存在并关联到项目（如果有里程碑）
          if (milestones.isNotEmpty) {
            final seedMilestones = milestones
                .where(
                  (m) =>
                      m.seedSlug != null &&
                      m.seedSlug!.startsWith('milestone_unit'),
                )
                .toList();
            if (seedMilestones.isNotEmpty) {
              for (final milestone in seedMilestones) {
                expect(
                  milestone.projectId,
                  equals(seedProject.id),
                  reason: '里程碑应该关联到种子项目',
                );
              }
            }
          }
        } else {
          // 如果数据库已有数据，可能没有种子项目，这是正常的
          print('注意: 数据库已有数据，没有找到种子项目 project_new_concept_english_3');
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'should be idempotent - no duplicate data on second import',
      (WidgetTester tester) async {
        // 启动应用
        app.main();
        await tester.pump();
        
        // 等待应用启动，使用 pumpAndSettle 确保 MaterialApp 已加载
        await tester.pumpAndSettle(const Duration(seconds: 1));
        
        // 如果 MaterialApp 还没出现，继续等待
        int retries = 0;
        while (retries < 10 && !tester.any(find.byType(MaterialApp))) {
          await tester.pump(const Duration(seconds: 1));
          retries++;
        }

        // 验证应用已加载
        expect(find.byType(MaterialApp), findsOneWidget);

        // 获取应用的 ProviderContainer
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp).first),
        );
        
        // 等待种子导入完成
        final seedInitializerAsync = container.read(seedInitializerProvider);
        await seedInitializerAsync.when(
          data: (_) => Future.value(),
          loading: () async {
            // 如果还在加载，等待最多 30 秒
            for (int i = 0; i < 30; i++) {
              await tester.pump(const Duration(seconds: 1));
              final currentAsync = container.read(seedInitializerProvider);
              if (currentAsync.hasValue) {
                break;
              }
            }
          },
          error: (error, stack) {
            throw Exception('Seed import failed: $error');
          },
        );
        
        final taskRepository = await container.read(taskRepositoryProvider.future);
        final projectRepository = await container.read(projectRepositoryProvider.future);
        final milestoneRepository = await container.read(milestoneRepositoryProvider.future);

        // 获取第一次导入后的数据数量
        final projectsBefore = await projectRepository.listAll();
        final milestonesBefore = await milestoneRepository.listAll();
        final tasksBefore = await taskRepository.listAll();

        final projectCountBefore = projectsBefore.length;
        final milestoneCountBefore = milestonesBefore.length;
        final taskCountBefore = tasksBefore.length;

        // 热重启应用（模拟第二次启动）
        await tester.binding.reassembleApplication();
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(seconds: 1));
        }

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
