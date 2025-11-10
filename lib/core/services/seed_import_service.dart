import 'package:flutter/foundation.dart';

import '../../data/models/milestone.dart';
import '../../data/models/project.dart';
import '../../data/models/task.dart';
import '../../data/models/task_template.dart';
import '../../data/repositories/milestone_repository.dart';
import '../../data/repositories/seed_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/task_template_repository.dart';
import '../utils/id_generator.dart';
import '../utils/objectbox_diagnostics.dart';
import 'metric_orchestrator.dart';
import 'project_models.dart';
import 'project_service.dart';
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
  }) : _seedRepository = seedRepository,
       _tags = tagRepository,
       _tasks = taskRepository,
       _templates = templateRepository,
       _projectService = projectService,
       _milestones = milestoneRepository,
       _metricOrchestrator = metricOrchestrator,
       _sortIndexResetService = SortIndexResetService(
         taskRepository: taskRepository,
       );

  final SeedRepository _seedRepository;
  final TagRepository _tags;
  final TaskRepository _tasks;
  final TaskTemplateRepository _templates;
  final ProjectService _projectService;
  final MilestoneRepository _milestones;
  final MetricOrchestrator _metricOrchestrator;
  final SortIndexResetService _sortIndexResetService;

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
      
      debugPrint('SeedImportService: Pre-import state - Tasks: $tasksCountBefore, Projects: $projectsCountBefore');
      
      final payload = await loadSeedPayload(localeCode);
      debugPrint('SeedImportService: Loaded seed payload, version: ${payload.version}');
      debugPrint('SeedImportService: Seed data - Tasks: ${payload.tasks.length}, Projects: ${payload.tasks.where((t) => t.taskKind?.toLowerCase() == 'project').length}, Milestones: ${payload.tasks.where((t) => t.taskKind?.toLowerCase() == 'milestone').length}, Templates: ${payload.templates.length}, InboxItems: ${payload.inboxItems.length}');
      
      final alreadyImported = await _seedRepository.wasImported(payload.version);
      debugPrint('SeedImportService: Already imported: $alreadyImported');

      if (alreadyImported) {
        // 即使已经导入过，也要重新初始化标签，确保标签分类正确
        debugPrint('SeedImportService: Version ${payload.version} already imported, checking seed data');
        
        // 计算预期的种子数据数量
        final expectedRegularTasks = payload.tasks.where((t) =>
            t.taskKind == null ||
            t.taskKind?.toLowerCase() == 'regular' ||
            (t.taskKind?.toLowerCase() != 'project' &&
                t.taskKind?.toLowerCase() != 'milestone')).length;
        final expectedProjects = payload.tasks.where((t) => t.taskKind?.toLowerCase() == 'project').length;
        final expectedMilestones = payload.tasks.where((t) => t.taskKind?.toLowerCase() == 'milestone').length;
        
        // 检查是否真的有种子数据（通过检查 seedSlug），而不是简单地检查是否有数据
        // 这样可以避免因为数据库中有非种子数据而跳过导入
        final allTasks = await _tasks.listAll();
        final allProjects = await _projectService.listAll();
        final allMilestones = await _milestones.listAll();
        
        // 检查是否有种子项目（通过 seedSlug）
        final seedProjects = allProjects.where((p) => p.seedSlug != null && p.seedSlug!.isNotEmpty).toList();
        final seedTasks = allTasks.where((t) => t.seedSlug != null && t.seedSlug!.isNotEmpty).toList();
        final seedMilestones = allMilestones.where((m) => m.seedSlug != null && m.seedSlug!.isNotEmpty).toList();
        
        debugPrint('SeedImportService: Data state - Total tasks: ${allTasks.length}, Total projects: ${allProjects.length}, Total milestones: ${allMilestones.length}');
        debugPrint('SeedImportService: Seed data state - Seed tasks: ${seedTasks.length}, Seed projects: ${seedProjects.length}, Seed milestones: ${seedMilestones.length}');
        debugPrint('SeedImportService: Expected seed data - Regular tasks: $expectedRegularTasks, Projects: $expectedProjects, Milestones: $expectedMilestones');
        
        // 检查是否有足够的种子数据
        // 只要存在种子数据（即使数量不完全匹配），就认为已经导入过
        // 因为种子数据只在首次安装时导入，不应该每次启动都重新导入
        final hasSeedData = seedProjects.isNotEmpty || seedTasks.isNotEmpty || seedMilestones.isNotEmpty;
        
        if (!hasSeedData) {
          debugPrint('SeedImportService: Version marked as imported but no seed data found, re-importing');
          debugPrint('SeedImportService: Expected: $expectedRegularTasks regular tasks, $expectedProjects projects, $expectedMilestones milestones');
          debugPrint('SeedImportService: Found: ${seedTasks.length} seed tasks, ${seedProjects.length} seed projects, ${seedMilestones.length} seed milestones');
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
            debugPrint('SeedImportService: Seed data exists but count mismatch (expected: $expectedRegularTasks tasks, $expectedProjects projects, $expectedMilestones milestones; found: ${seedTasks.length} tasks, ${seedProjects.length} projects, ${seedMilestones.length} milestones)');
            debugPrint('SeedImportService: This is normal if seed data was imported multiple times or from different versions');
          }
          debugPrint('SeedImportService: Seed data exists, skipping import (seed data is only imported on first install)');
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
      debugPrint('SeedImportService: Breakdown - Projects: ${payload.tasks.where((t) => t.taskKind?.toLowerCase() == 'project').length}, Milestones: ${payload.tasks.where((t) => t.taskKind?.toLowerCase() == 'milestone').length}, Regular tasks: ${payload.tasks.where((t) => t.taskKind?.toLowerCase() != 'project' && t.taskKind?.toLowerCase() != 'milestone').length}');
      debugPrint('SeedImportService: Query descriptor - findAll tasks and projects');
      
      final slugToId = await _applyTasks(payload.tasks);
      debugPrint('SeedImportService: Applied tasks, slugToId map contains ${slugToId.length} entries');
      final tasksDuration = tasksTimer.stop();
      final tasksDurationMs = DateTime.now().difference(tasksStartTime).inMilliseconds;
      
      debugPrint('SeedImportService: Tasks applied in ${tasksDurationMs}ms, slugToId map size: ${slugToId.length}');
      if (tasksTimer.isSlow(tasksDuration)) {
        debugPrint('SeedImportService: WARNING - Task application was slow (${tasksDuration}ms > 1000ms threshold)');
      }

      final inboxStartTime = DateTime.now();
      debugPrint('SeedImportService: Applying inbox items (${payload.inboxItems.length} items)');
      await _applyInboxItems(payload.inboxItems, slugToId);
      final inboxDuration = DateTime.now().difference(inboxStartTime);
      debugPrint('SeedImportService: Inbox items applied in ${inboxDuration.inMilliseconds}ms');

      final templatesStartTime = DateTime.now();
      debugPrint('SeedImportService: Applying templates (${payload.templates.length} templates)');
      await _applyTemplates(payload.templates, slugToId);
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
      
      final expectedRegularTasks = payload.tasks.where((t) =>
          t.taskKind == null ||
          t.taskKind?.toLowerCase() == 'regular' ||
          (t.taskKind?.toLowerCase() != 'project' &&
              t.taskKind?.toLowerCase() != 'milestone')).length +
          payload.inboxItems.length;
      final expectedProjects = payload.tasks.where((t) => t.taskKind?.toLowerCase() == 'project').length;
      
      final tasksAdded = tasksCountAfter - tasksCountBefore;
      final projectsAdded = projectsCountAfter - projectsCountBefore;
      
      debugPrint('SeedImportService: Post-import state - Tasks: $tasksCountAfter (+$tasksAdded), Projects: $projectsCountAfter (+$projectsAdded)');
      debugPrint('SeedImportService: Expected - Regular tasks: $expectedRegularTasks, Projects: $expectedProjects');
      
      // 验证导入结果
      if (tasksAdded < expectedRegularTasks) {
        debugPrint('SeedImportService: WARNING - Expected $expectedRegularTasks regular tasks, but only $tasksAdded were added');
      }
      if (projectsAdded < expectedProjects) {
        debugPrint('SeedImportService: WARNING - Expected $expectedProjects projects, but only $projectsAdded were added');
      }

      final recordStartTime = DateTime.now();
      debugPrint('SeedImportService: Recording seed import');
      await _seedRepository.importSeeds(payload);
      await _seedRepository.recordVersion(payload.version);
      final recordDuration = DateTime.now().difference(recordStartTime);
      debugPrint('SeedImportService: Seed import recorded in ${recordDuration.inMilliseconds}ms');

      debugPrint('SeedImportService: Requesting metric recompute');
      await _metricOrchestrator.requestRecompute(
        MetricRecomputeReason.seedImport,
      );

      final totalDuration = DateTime.now().difference(importStartTime);
      debugPrint('SeedImportService: Import completed successfully in ${totalDuration.inMilliseconds}ms');
      debugPrint('SeedImportService: Summary - Tasks: $tasksCountBefore -> $tasksCountAfter (+$tasksAdded), Projects: $projectsCountBefore -> $projectsCountAfter (+$projectsAdded)');
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
        debugPrint('SeedImportService: Post-failure state - Tasks: $tasksCountAfter, Projects: $projectsCountAfter');
        
        if (tasksCountAfter > tasksCountBefore || projectsCountAfter > projectsCountBefore) {
          debugPrint('SeedImportService: WARNING - Partial data may have been written before failure');
          debugPrint('SeedImportService: Tasks before: $tasksCountBefore, after: $tasksCountAfter');
          debugPrint('SeedImportService: Projects before: $projectsCountBefore, after: $projectsCountAfter');
        }
      } catch (e) {
        debugPrint('SeedImportService: Failed to check post-failure state: $e');
      }
      
      rethrow; // 重新抛出异常以便上层处理
    } finally {
      _isImporting = false;
    }
  }

  // 移除 _applyTags 方法，标签现在通过配置文件初始化

  Future<void> _clearAllTags() async {
    await _tags.clearAll();
  }

  Future<Map<String, String>> _applyTasks(List<SeedTask> tasks) async {
    // slug -> id 映射，支持项目、里程碑和任务的混合映射
    final Map<String, String> slugToId = <String, String>{};
    // slug -> projectId 映射（字符串 ID）
    final Map<String, String> slugToProjectId = <String, String>{};
    // slug -> milestoneId 映射（字符串 ID）
    final Map<String, String> slugToMilestoneId = <String, String>{};

    // 第一遍：处理所有项目（project 类型）
    // 使用字符串比较来区分项目类型
    final projectTasks = tasks
        .where((t) => t.taskKind?.toLowerCase() == 'project')
        .toList();
    
    // 先检查已存在的项目（通过 seedSlug）
    final allProjects = await _projectService.listAll();
    final existingProjectsBySlug = <String, Project>{};
    for (final project in allProjects) {
      if (project.seedSlug != null) {
        existingProjectsBySlug[project.seedSlug!] = project;
      }
    }
    
    debugPrint('SeedImportService: Processing ${projectTasks.length} project seeds');
    for (final seed in projectTasks) {
      // 检查是否已存在相同 seedSlug 的项目
      if (existingProjectsBySlug.containsKey(seed.slug)) {
        debugPrint('SeedImportService: Project with seedSlug "${seed.slug}" already exists, skipping');
        final existingProject = existingProjectsBySlug[seed.slug]!;
        slugToProjectId[seed.slug] = existingProject.id;
        slugToId[seed.slug] = existingProject.id;
        continue;
      }
      
      // 创建新项目
      final dueAt = _parseDueAt(seed.dueAt) ?? DateTime.now();
      debugPrint('SeedImportService: Creating project with seedSlug "${seed.slug}", title: "${seed.title}"');

      final project = await _projectService.createProject(
        ProjectBlueprint(
          title: seed.title,
          dueDate: dueAt,
          description: null,
          tags: seed.tags,
          milestones: const <ProjectMilestoneBlueprint>[],
        ),
      );
      
      // 更新项目的 seedSlug（createProject 不会设置 seedSlug，需要手动更新）
      await _projectService.updateProject(project.id, ProjectUpdate(seedSlug: seed.slug));

      slugToProjectId[seed.slug] = project.id;
      slugToId[seed.slug] = project.id;
    }

    // 第二遍：处理所有里程碑（milestone 类型）
    // 使用字符串比较来区分里程碑类型
    final milestoneTasks = tasks
        .where((t) => t.taskKind?.toLowerCase() == 'milestone')
        .toList();
    for (final seed in milestoneTasks) {
      // 里程碑必须有父项目
      if (seed.parentSlug == null ||
          !slugToProjectId.containsKey(seed.parentSlug)) {
        debugPrint(
          'SeedImportService: Milestone ${seed.slug} has no valid parent project, skipping',
        );
        continue;
      }

      final projectId = slugToProjectId[seed.parentSlug]!;
      final dueAt = _parseDueAt(seed.dueAt);

      // 生成 milestoneId（使用 UUID v4）
      final milestoneId = IdGenerator.generateId();

      await _milestones.createMilestoneWithId(
        MilestoneDraft(
          projectId: projectId,
          title: seed.title,
          status: seed.status,
          dueAt: dueAt,
          startedAt: null,
          endedAt: null,
          sortIndex: seed.sortIndex,
          tags: seed.tags,
          templateLockCount: 0,
          seedSlug: seed.slug,
          allowInstantComplete: seed.allowInstantComplete,
          description: null,
          logs: const <MilestoneLogEntry>[],
        ),
        milestoneId,
        DateTime.now(),
        DateTime.now(),
      );

      slugToMilestoneId[seed.slug] = milestoneId;
      slugToId[seed.slug] = milestoneId;
    }

    // 第三遍：处理所有普通任务（regular 类型或未指定类型）
    // 使用字符串比较来区分普通任务
    final regularTasks = tasks
        .where((t) =>
            t.taskKind == null ||
            t.taskKind?.toLowerCase() == 'regular' ||
            t.taskKind?.toLowerCase() != 'project' &&
                t.taskKind?.toLowerCase() != 'milestone')
        .toList();

    // 先检查已存在的任务（通过 seedSlug）
    final allTasks = await _tasks.listAll();
    final existingTasksBySlug = <String, Task>{};
    for (final task in allTasks) {
      if (task.seedSlug != null) {
        existingTasksBySlug[task.seedSlug!] = task;
      }
    }

    debugPrint('SeedImportService: Processing ${regularTasks.length} regular task seeds');
    for (final seed in regularTasks) {
      // 检查是否已存在相同 seedSlug 的任务
      if (existingTasksBySlug.containsKey(seed.slug)) {
        debugPrint('SeedImportService: Task with seedSlug "${seed.slug}" already exists, skipping');
        final existingTask = existingTasksBySlug[seed.slug]!;
        slugToId[seed.slug] = existingTask.id;
        continue;
      }

      // 创建新任务
      final dueAt = _parseDueAt(seed.dueAt);
      debugPrint('SeedImportService: Creating task with seedSlug "${seed.slug}", title: "${seed.title}"');

      // 确定任务的 projectId 和 milestoneId
      String? projectId;
      String? milestoneId;

      // 如果 parentSlug 指向里程碑，则设置 milestoneId
      if (seed.parentSlug != null &&
          slugToMilestoneId.containsKey(seed.parentSlug)) {
        milestoneId = slugToMilestoneId[seed.parentSlug];
        // 里程碑必须属于某个项目，通过里程碑找到项目
        final milestoneSlug = seed.parentSlug!;
        final parentMilestoneMatches = milestoneTasks.where(
          (t) => t.slug == milestoneSlug,
        );
        if (parentMilestoneMatches.isNotEmpty) {
          final parentMilestoneTask = parentMilestoneMatches.first;
          if (parentMilestoneTask.parentSlug != null) {
            projectId = slugToProjectId[parentMilestoneTask.parentSlug];
          }
        }
      } else if (seed.parentSlug != null &&
          slugToProjectId.containsKey(seed.parentSlug)) {
        // 如果 parentSlug 指向项目，则设置 projectId
        projectId = slugToProjectId[seed.parentSlug];
      }

      final draft = TaskDraft(
        title: seed.title,
        status: seed.status,
        dueAt: dueAt,
          parentId: null,
        projectId: projectId,
        milestoneId: milestoneId,
        tags: seed.tags,
        allowInstantComplete: seed.allowInstantComplete,
        seedSlug: seed.slug,
        sortIndex: seed.sortIndex,
      );
        final task = await _tasks.createTask(draft);
        slugToId[seed.slug] = task.id;
    }

    // 第四遍：处理普通任务的父子关系（parentTaskId）
    for (final seed in regularTasks.where((task) => task.parentSlug != null)) {
      final taskId = slugToId[seed.slug];
      final parentId = seed.parentSlug == null
          ? null
          : slugToId[seed.parentSlug];

      // 只有当父级也是普通任务时才设置 parentTaskId
      if (taskId != null && parentId != null && seed.parentSlug != null) {
        final parentSeedMatches = tasks.where((t) => t.slug == seed.parentSlug);
        // 如果父级是普通任务，设置 parentTaskId
        // 使用字符串比较来判断是否为普通任务
        if (parentSeedMatches.isNotEmpty) {
          final parentSeed = parentSeedMatches.first;
          final parentTaskKind = parentSeed.taskKind?.toLowerCase();
          if (parentTaskKind == null ||
              parentTaskKind == 'regular' ||
              (parentTaskKind != 'project' && parentTaskKind != 'milestone')) {
            await _tasks.updateTask(
              taskId,
              TaskUpdate(
                  parentId: parentId,
                sortIndex: seed.sortIndex,
              ),
            );
          }
        }
      }
    }

    return slugToId;
  }

  /// 解析 dueAt 字段（支持相对天数或绝对日期）
  DateTime? _parseDueAt(dynamic dueAt) {
    if (dueAt == null) {
      // 无 dueAt：默认今天 23:59:59
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, 23, 59, 59);
    }

    if (dueAt is int) {
      // 相对天数：计算绝对日期（设置为目标日期的 23:59:59）
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final targetDay = today.add(Duration(days: dueAt));
      return DateTime(
        targetDay.year,
        targetDay.month,
        targetDay.day,
        23,
        59,
        59,
      );
    } else if (dueAt is DateTime) {
      // 绝对日期：直接使用
      return dueAt;
    }

    return null;
  }

  Future<void> _applyTemplates(
    List<SeedTemplate> templates,
    Map<String, String> slugToId,
  ) async {
    for (final seed in templates) {
      final draft = TaskTemplateDraft(
        title: seed.title,
        parentTaskId: null,
        defaultTags: seed.defaultTags,
        seedSlug: seed.slug,
        suggestedEstimateMinutes: seed.suggestedEstimateMinutes,
      );
      final template = await _templates.createTemplateWithSeed(
        draft: draft,
          parentTaskId:
              seed.parentSlug == null ? null : slugToId[seed.parentSlug!],
      );
      if (template.parentTaskId != null) {
        await _tasks.adjustTemplateLock(
          taskId: template.parentTaskId!,
          delta: 1,
        );
      }
    }
  }

  Future<void> _applyInboxItems(
    List<SeedInboxItem> inboxItems,
    Map<String, String> slugToId,
  ) async {
    for (final seed in inboxItems) {
      // 全新安装场景：直接创建 inbox 任务，无需检查重复
      final draft = TaskDraft(
        title: seed.title,
        status: TaskStatus.inbox,
        seedSlug: seed.slug,
        allowInstantComplete: false,
      );
      final task = await _tasks.createTask(draft);
      slugToId[seed.slug] = task.id;
    }
  }
}
