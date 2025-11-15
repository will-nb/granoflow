import 'package:flutter/foundation.dart';

import '../../data/repositories/milestone_repository.dart';
import '../../data/repositories/seed_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/task_template_repository.dart';
import '../utils/database_instrumentation.dart';
import 'metric_orchestrator.dart';
import 'node_service.dart';
import 'project_service.dart';
import 'seed_item_applier.dart';
import 'seed_node_applier.dart';
import 'seed_task_applier.dart';
import 'sort_index_reset_service.dart';

class SeedImportService {
  SeedImportService({
    required SeedRepository seedRepository,
    required TagRepository tagRepository,
    required TaskRepository taskRepository,
    required TaskTemplateRepository templateRepository,
    required ProjectService projectService,
    required MilestoneRepository milestoneRepository,
    required MetricOrchestrator metricOrchestrator,
    required NodeService nodeService,
  }) : _seedRepository = seedRepository,
       _tags = tagRepository,
       _tasks = taskRepository,
       _projectService = projectService,
       _milestones = milestoneRepository,
       _metricOrchestrator = metricOrchestrator,
       _sortIndexResetService = SortIndexResetService(taskRepository: taskRepository) {
    // 创建共享的 nodeApplier 实例
    final nodeApplier = SeedNodeApplier(nodeService: nodeService);
    _taskApplier = SeedTaskApplier(
      projectService: projectService,
      taskRepository: taskRepository,
      milestoneRepository: milestoneRepository,
      nodeApplier: nodeApplier,
    );
    _itemApplier = SeedItemApplier(
      taskRepository: taskRepository,
      templateRepository: templateRepository,
    );
  }

  final SeedRepository _seedRepository;
  final TagRepository _tags;
  final TaskRepository _tasks;
  final ProjectService _projectService;
  final MilestoneRepository _milestones;
  final MetricOrchestrator _metricOrchestrator;
  final SortIndexResetService _sortIndexResetService;
  late final SeedTaskApplier _taskApplier;
  late final SeedItemApplier _itemApplier;

  // 防止重复导入的标志
  bool _isImporting = false;

  Future<void> importIfNeeded(String localeCode) async {
    // 防止并发导入：在任何 await 之前抢占标志位
    if (_isImporting) {
      debugPrint('SeedImportService: Import already in progress, skipping');
      return;
    }
    _isImporting = true;

    final importStartTime = DateTime.now();
    debugPrint('SeedImportService: Starting import for locale: $localeCode');

    // 导入前核查：记录当前数据状态（在 try 块外，以便 catch 块可以访问）
    var tasksCountBefore = 0;
    var projectsCountBefore = 0;

    try {
      // 导入前核查：记录当前数据状态
      final tasksBefore = await _tasks.listAll();
      final projectsBefore = await _projectService.listAll();
      tasksCountBefore = tasksBefore.length;
      projectsCountBefore = projectsBefore.length;

      debugPrint(
        'SeedImportService: Pre-import state - Tasks: $tasksCountBefore, Projects: $projectsCountBefore',
      );

      final payload = await loadSeedPayload(localeCode);
      debugPrint('SeedImportService: Loaded seed payload, version: ${payload.version}');
      debugPrint(
        'SeedImportService: Seed data - Tasks: ${payload.tasks.length}, Projects: ${payload.tasks.where((t) => t.taskKind?.toLowerCase() == 'project').length}, Milestones: ${payload.tasks.where((t) => t.taskKind?.toLowerCase() == 'milestone').length}, Templates: ${payload.templates.length}, InboxItems: ${payload.inboxItems.length}',
      );

      final alreadyImported = await _seedRepository.wasImported(payload.version);
      debugPrint('SeedImportService: Already imported: $alreadyImported');

      if (alreadyImported) {
        // 即使已经导入过，也要重新初始化标签，确保标签分类正确
        debugPrint(
          'SeedImportService: Version ${payload.version} already imported, checking seed data',
        );

        // 计算预期的种子数据数量
        final expectedRegularTasks = payload.tasks
            .where(
              (t) =>
                  t.taskKind == null ||
                  t.taskKind?.toLowerCase() == 'regular' ||
                  (t.taskKind?.toLowerCase() != 'project' &&
                      t.taskKind?.toLowerCase() != 'milestone'),
            )
            .length;
        final expectedProjects = payload.tasks
            .where((t) => t.taskKind?.toLowerCase() == 'project')
            .length;
        final expectedMilestones = payload.tasks
            .where((t) => t.taskKind?.toLowerCase() == 'milestone')
            .length;

        // 检查是否真的有种子数据（通过检查 seedSlug），而不是简单地检查是否有数据
        // 这样可以避免因为数据库中有非种子数据而跳过导入
        final allTasks = await _tasks.listAll();
        final allProjects = await _projectService.listAll();
        final allMilestones = await _milestones.listAll();

        // 检查是否有种子项目（通过 seedSlug）
        final seedProjects = allProjects
            .where((p) => p.seedSlug != null && p.seedSlug!.isNotEmpty)
            .toList();
        final seedTasks = allTasks
            .where((t) => t.seedSlug != null && t.seedSlug!.isNotEmpty)
            .toList();
        final seedMilestones = allMilestones
            .where((m) => m.seedSlug != null && m.seedSlug!.isNotEmpty)
            .toList();

        debugPrint(
          'SeedImportService: Data state - Total tasks: ${allTasks.length}, Total projects: ${allProjects.length}, Total milestones: ${allMilestones.length}',
        );
        debugPrint(
          'SeedImportService: Seed data state - Seed tasks: ${seedTasks.length}, Seed projects: ${seedProjects.length}, Seed milestones: ${seedMilestones.length}',
        );
        debugPrint(
          'SeedImportService: Expected seed data - Regular tasks: $expectedRegularTasks, Projects: $expectedProjects, Milestones: $expectedMilestones',
        );

        // 检查是否有足够的种子数据
        // 只要存在种子数据（即使数量不完全匹配），就认为已经导入过
        // 因为种子数据只在首次安装时导入，不应该每次启动都重新导入
        final hasSeedData =
            seedProjects.isNotEmpty || seedTasks.isNotEmpty || seedMilestones.isNotEmpty;

        if (!hasSeedData) {
          debugPrint(
            'SeedImportService: Version marked as imported but no seed data found, re-importing',
          );
          debugPrint(
            'SeedImportService: Expected: $expectedRegularTasks regular tasks, $expectedProjects projects, $expectedMilestones milestones',
          );
          debugPrint(
            'SeedImportService: Found: ${seedTasks.length} seed tasks, ${seedProjects.length} seed projects, ${seedMilestones.length} seed milestones',
          );
          debugPrint('SeedImportService: Clearing version record to force re-import');
          // 清除版本记录，强制重新导入
          await _seedRepository.clearVersion(payload.version);
          debugPrint('SeedImportService: Version record cleared, will re-import');
          // 继续执行导入流程，不返回
        } else {
          // 有种子数据，但数量可能不匹配（比如有重复或额外数据）
          // 这是正常的，因为种子数据只在首次安装时导入
          if (seedTasks.length != expectedRegularTasks ||
              seedProjects.length != expectedProjects ||
              seedMilestones.length != expectedMilestones) {
            debugPrint(
              'SeedImportService: Seed data exists but count mismatch (expected: $expectedRegularTasks tasks, $expectedProjects projects, $expectedMilestones milestones; found: ${seedTasks.length} tasks, ${seedProjects.length} projects, ${seedMilestones.length} milestones)',
            );
            debugPrint(
              'SeedImportService: This is normal if seed data was imported multiple times or from different versions',
            );
          }
          debugPrint(
            'SeedImportService: Seed data exists, skipping import (seed data is only imported on first install)',
          );
          try {
            // 先清空所有标签，然后重新创建
            await _clearAllTags();
            await _tags.initializeTags();
            debugPrint('SeedImportService: Tags reinitialized successfully');
          } catch (error, stackTrace) {
            debugPrint('SeedImportService: Error reinitializing tags: $error');
            debugPrint('SeedImportService: Stack trace: $stackTrace');
          }
          _isImporting = false;
          return;
        }
      }

      // 标签现在通过配置文件初始化，不再从种子数据导入
      // 总是重新初始化标签，确保标签分类正确
      debugPrint('SeedImportService: Initializing tags from configuration');
      await _tags.initializeTags();
      debugPrint('SeedImportService: Tags initialized successfully');

      // 导入执行阶段
      final tasksStartTime = DateTime.now();
      final tasksTimer = DatabaseOpTimer(slowQueryThresholdMs: 1000);
      tasksTimer.start();

      debugPrint('SeedImportService: Applying tasks (${payload.tasks.length} tasks)');
      debugPrint(
        'SeedImportService: Breakdown - Projects: ${payload.tasks.where((t) => t.taskKind?.toLowerCase() == 'project').length}, Milestones: ${payload.tasks.where((t) => t.taskKind?.toLowerCase() == 'milestone').length}, Regular tasks: ${payload.tasks.where((t) => t.taskKind?.toLowerCase() != 'project' && t.taskKind?.toLowerCase() != 'milestone').length}',
      );
      debugPrint('SeedImportService: Query descriptor - findAll tasks and projects');

      final slugToId = await _taskApplier.applyTasks(payload.tasks);
      debugPrint(
        'SeedImportService: Applied tasks, slugToId map contains ${slugToId.length} entries',
      );
      final tasksDuration = tasksTimer.stop();
      final tasksDurationMs = DateTime.now().difference(tasksStartTime).inMilliseconds;

      debugPrint(
        'SeedImportService: Tasks applied in ${tasksDurationMs}ms, slugToId map size: ${slugToId.length}',
      );
      if (tasksTimer.isSlow(tasksDuration)) {
        debugPrint(
          'SeedImportService: WARNING - Task application was slow (${tasksDuration}ms > 1000ms threshold)',
        );
      }

      final inboxStartTime = DateTime.now();
      debugPrint('SeedImportService: Applying inbox items (${payload.inboxItems.length} items)');
      await _itemApplier.applyInboxItems(payload.inboxItems, slugToId);
      final inboxDuration = DateTime.now().difference(inboxStartTime);
      debugPrint('SeedImportService: Inbox items applied in ${inboxDuration.inMilliseconds}ms');

      final templatesStartTime = DateTime.now();
      debugPrint('SeedImportService: Applying templates (${payload.templates.length} templates)');
      await _itemApplier.applyTemplates(payload.templates, slugToId);
      final templatesDuration = DateTime.now().difference(templatesStartTime);
      debugPrint('SeedImportService: Templates applied in ${templatesDuration.inMilliseconds}ms');

      // 重置所有任务的 sortIndex 为默认值
      final sortIndexStartTime = DateTime.now();
      debugPrint('SeedImportService: Resetting sort indexes');
      await _sortIndexResetService.resetAllSortIndexes();
      final sortIndexDuration = DateTime.now().difference(sortIndexStartTime);
      debugPrint('SeedImportService: Sort indexes reset in ${sortIndexDuration.inMilliseconds}ms');

      // 导入后校验：验证导入数量
      final tasksAfter = await _tasks.listAll();
      final projectsAfter = await _projectService.listAll();
      final tasksCountAfter = tasksAfter.length;
      final projectsCountAfter = projectsAfter.length;

      final expectedRegularTasks =
          payload.tasks
              .where(
                (t) =>
                    t.taskKind == null ||
                    t.taskKind?.toLowerCase() == 'regular' ||
                    (t.taskKind?.toLowerCase() != 'project' &&
                        t.taskKind?.toLowerCase() != 'milestone'),
              )
              .length +
          payload.inboxItems.length;
      final expectedProjects = payload.tasks
          .where((t) => t.taskKind?.toLowerCase() == 'project')
          .length;

      final tasksAdded = tasksCountAfter - tasksCountBefore;
      final projectsAdded = projectsCountAfter - projectsCountBefore;

      debugPrint(
        'SeedImportService: Post-import state - Tasks: $tasksCountAfter (+$tasksAdded), Projects: $projectsCountAfter (+$projectsAdded)',
      );
      debugPrint(
        'SeedImportService: Expected - Regular tasks: $expectedRegularTasks, Projects: $expectedProjects',
      );

      // 验证导入结果
      if (tasksAdded < expectedRegularTasks) {
        debugPrint(
          'SeedImportService: WARNING - Expected $expectedRegularTasks regular tasks, but only $tasksAdded were added',
        );
      }
      if (projectsAdded < expectedProjects) {
        debugPrint(
          'SeedImportService: WARNING - Expected $expectedProjects projects, but only $projectsAdded were added',
        );
      }

      final recordStartTime = DateTime.now();
      debugPrint('SeedImportService: Recording seed import');
      await _seedRepository.importSeeds(payload);
      await _seedRepository.recordVersion(payload.version);
      final recordDuration = DateTime.now().difference(recordStartTime);
      debugPrint('SeedImportService: Seed import recorded in ${recordDuration.inMilliseconds}ms');

      debugPrint('SeedImportService: Requesting metric recompute');
      await _metricOrchestrator.requestRecompute(MetricRecomputeReason.seedImport);

      final totalDuration = DateTime.now().difference(importStartTime);
      debugPrint(
        'SeedImportService: Import completed successfully in ${totalDuration.inMilliseconds}ms',
      );
      debugPrint(
        'SeedImportService: Summary - Tasks: $tasksCountBefore -> $tasksCountAfter (+$tasksAdded), Projects: $projectsCountBefore -> $projectsCountAfter (+$projectsAdded)',
      );
    } catch (error, stackTrace) {
      final totalDuration = DateTime.now().difference(importStartTime);
      debugPrint('SeedImportService: Import failed after ${totalDuration.inMilliseconds}ms');
      debugPrint('SeedImportService: Error: $error');
      debugPrint('SeedImportService: Error type: ${error.runtimeType}');
      debugPrint('SeedImportService: Stack trace: $stackTrace');

      // 导入后校验：检查是否有部分数据被写入
      try {
        final tasksAfter = await _tasks.listAll();
        final projectsAfter = await _projectService.listAll();
        final tasksCountAfter = tasksAfter.length;
        final projectsCountAfter = projectsAfter.length;
        debugPrint(
          'SeedImportService: Post-failure state - Tasks: $tasksCountAfter, Projects: $projectsCountAfter',
        );

        if (tasksCountAfter > tasksCountBefore || projectsCountAfter > projectsCountBefore) {
          debugPrint(
            'SeedImportService: WARNING - Partial data may have been written before failure',
          );
          debugPrint('SeedImportService: Tasks before: $tasksCountBefore, after: $tasksCountAfter');
          debugPrint(
            'SeedImportService: Projects before: $projectsCountBefore, after: $projectsCountAfter',
          );
        }
      } catch (e) {
        debugPrint('SeedImportService: Failed to check post-failure state: $e');
      }

      rethrow; // 重新抛出异常以便上层处理
    } finally {
      _isImporting = false;
    }
  }

  Future<void> _clearAllTags() async {
    await _tags.clearAll();
  }
}
