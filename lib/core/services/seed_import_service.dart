import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../data/models/milestone.dart';
import '../../data/models/task.dart';
import '../../data/models/task_template.dart';
import '../../data/repositories/milestone_repository.dart';
import '../../data/repositories/seed_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/task_template_repository.dart';
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
  final Random _random = Random();

  // 防止重复导入的标志
  bool _isImporting = false;

  Future<void> importIfNeeded(String localeCode) async {
    // 防止并发导入：在任何 await 之前抢占标志位
    if (_isImporting) {
      return;
    }
    _isImporting = true;

    final payload = await loadSeedPayload(localeCode);
    final alreadyImported = await _seedRepository.wasImported(payload.version);

    if (alreadyImported) {
      // 即使已经导入过，也要重新初始化标签，确保标签分类正确
      try {
        // 先清空所有标签，然后重新创建
        await _clearAllTags();
        await _tags.initializeTags();
      } catch (error) {
        debugPrint('SeedImportService: Error reinitializing tags: $error');
      }
      _isImporting = false;
      return;
    }

    try {
      // 标签现在通过配置文件初始化，不再从种子数据导入
      // 总是重新初始化标签，确保标签分类正确
      await _tags.initializeTags();

      final slugToId = await _applyTasks(payload.tasks);
      await _applyInboxItems(payload.inboxItems, slugToId);
      await _applyTemplates(payload.templates, slugToId);

      // 重置所有任务的 sortIndex 为默认值
      await _sortIndexResetService.resetAllSortIndexes();

      await _seedRepository.importSeeds(payload);
      await _seedRepository.recordVersion(payload.version);

      await _metricOrchestrator.requestRecompute(
        MetricRecomputeReason.seedImport,
      );
    } catch (error, stackTrace) {
      debugPrint('SeedImportService: Import failed with error: $error');
      debugPrint('SeedImportService: Stack trace: $stackTrace');
      rethrow; // 重新抛出异常以便上层处理
    } finally {
      _isImporting = false;
    }
  }

  // 移除 _applyTags 方法，标签现在通过配置文件初始化

  Future<void> _clearAllTags() async {
    await _tags.clearAll();
  }

  Future<Map<String, int>> _applyTasks(List<SeedTask> tasks) async {
    // slug -> id 映射，支持项目、里程碑和任务的混合映射
    final Map<String, int> slugToId = <String, int>{};
    // slug -> projectId 映射（字符串 ID）
    final Map<String, String> slugToProjectId = <String, String>{};
    // slug -> milestoneId 映射（字符串 ID）
    final Map<String, String> slugToMilestoneId = <String, String>{};

    // 第一遍：处理所有项目（project 类型）
    // 使用字符串比较来区分项目类型
    final projectTasks = tasks
        .where((t) => t.taskKind?.toLowerCase() == 'project')
        .toList();
    for (final seed in projectTasks) {
      // 全新安装场景：直接创建项目，无需检查重复
      final dueAt = _parseDueAt(seed.dueAt) ?? DateTime.now();

      final project = await _projectService.createProject(
        ProjectBlueprint(
          title: seed.title,
          dueDate: dueAt,
          description: null,
          tags: seed.tags,
          milestones: const <ProjectMilestoneBlueprint>[],
        ),
      );

      slugToProjectId[seed.slug] = project.projectId;
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

      // 生成 milestoneId（使用类似 ProjectService 的生成逻辑）
      final now = DateTime.now();
      final suffix = _random.nextInt(1 << 20).toRadixString(16).padLeft(5, '0');
      final milestoneId = 'mil-${now.millisecondsSinceEpoch}-$suffix';

      final milestone = await _milestones.create(
        MilestoneDraft(
          milestoneId: milestoneId,
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
      );

      slugToMilestoneId[seed.slug] = milestone.milestoneId;
      slugToId[seed.slug] = milestone.id;
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

    for (final seed in regularTasks) {
      // 全新安装场景：直接创建任务，无需检查重复
      final dueAt = _parseDueAt(seed.dueAt);

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
        parentTaskId: null,
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
              TaskUpdate(parentTaskId: parentId, sortIndex: seed.sortIndex),
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
    Map<String, int> slugToId,
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
        parentId: seed.parentSlug == null ? null : slugToId[seed.parentSlug!],
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
    Map<String, int> slugToId,
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
