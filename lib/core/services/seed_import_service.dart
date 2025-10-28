import 'package:flutter/foundation.dart';

import '../../data/models/task.dart';
import '../../data/models/task_template.dart';
import '../../data/repositories/seed_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/task_template_repository.dart';
import 'metric_orchestrator.dart';
import 'sort_index_reset_service.dart';
import '../constants/task_constants.dart';

class SeedImportService {
  SeedImportService({
    required SeedRepository seedRepository,
    required TagRepository tagRepository,
    required TaskRepository taskRepository,
    required TaskTemplateRepository templateRepository,
    required MetricOrchestrator metricOrchestrator,
  }) : _seedRepository = seedRepository,
       _tags = tagRepository,
       _tasks = taskRepository,
       _templates = templateRepository,
       _metricOrchestrator = metricOrchestrator,
       _sortIndexResetService = SortIndexResetService(taskRepository: taskRepository);

  final SeedRepository _seedRepository;
  final TagRepository _tags;
  final TaskRepository _tasks;
  final TaskTemplateRepository _templates;
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
    
    debugPrint('SeedImportService: Loading payload for locale=$localeCode');
    final payload = await loadSeedPayload(localeCode);
    debugPrint('SeedImportService: Payload loaded, version=${payload.version}');
    debugPrint('SeedImportService: Tasks count=${payload.tasks.length}');
    debugPrint('SeedImportService: Templates count=${payload.templates.length}');
    debugPrint('SeedImportService: Inbox items count=${payload.inboxItems.length}');
    
    final alreadyImported = await _seedRepository.wasImported(payload.version);
    debugPrint('SeedImportService: Already imported=$alreadyImported');
    
    if (alreadyImported) {
      debugPrint('SeedImportService: Already imported=true, but reinitializing tags...');
      // 即使已经导入过，也要重新初始化标签，确保标签分类正确
      try {
        // 先清空所有标签，然后重新创建
        await _clearAllTags();
        await _tags.initializeTags();
        debugPrint('SeedImportService: Tags cleared and reinitialized from config');
      } catch (error) {
        debugPrint('SeedImportService: Error reinitializing tags: $error');
      }
      _isImporting = false;
      return;
    }
    
    try {
      debugPrint('SeedImportService: Starting import...');
      
      // 标签现在通过配置文件初始化，不再从种子数据导入
      // 总是重新初始化标签，确保标签分类正确
      await _tags.initializeTags();
      debugPrint('SeedImportService: Tags initialized from config');
      
      final slugToId = await _applyTasks(payload.tasks);
      debugPrint('SeedImportService: Tasks applied');
      
      await _applyInboxItems(payload.inboxItems, slugToId);
      debugPrint('SeedImportService: Inbox items applied');
      
      await _applyTemplates(payload.templates, slugToId);
      debugPrint('SeedImportService: Templates applied');
      
      // 重置所有任务的 sortIndex 为默认值
      await _sortIndexResetService.resetAllSortIndexes();
      debugPrint('SeedImportService: SortIndex reset complete');
      
      await _seedRepository.importSeeds(payload);
      await _seedRepository.recordVersion(payload.version);
      debugPrint('SeedImportService: Version recorded, import complete!');
      
      await _metricOrchestrator.requestRecompute(
        MetricRecomputeReason.seedImport,
      );
    } finally {
      _isImporting = false;
    }
  }

  // 移除 _applyTags 方法，标签现在通过配置文件初始化
  
  Future<void> _clearAllTags() async {
    debugPrint('SeedImportService: Clearing all tags...');
    await _tags.clearAll();
    debugPrint('SeedImportService: All tags cleared');
  }

  Future<Map<String, int>> _applyTasks(List<SeedTask> tasks) async {
    final Map<String, int> slugToId = <String, int>{};
    for (final seed in tasks) {
      // 避免重复：如果同 slug 已存在则跳过
      final existing = await _tasks.findBySlug(seed.slug);
      if (existing != null) {
        slugToId[seed.slug] = existing.id;
        continue;
      }

      final draft = TaskDraft(
        title: seed.title,
        status: seed.status,
        // 为无 dueAt 的种子任务指定“今天”的到期时间，确保在 Task 列表可见
        dueAt: DateTime.now(),
        parentId: null,
        tags: seed.tags,
        allowInstantComplete: seed.allowInstantComplete,
        seedSlug: seed.slug,
        sortIndex: TaskConstants.DEFAULT_SORT_INDEX,
      );
      final task = await _tasks.createTask(draft);
      slugToId[seed.slug] = task.id;
    }

    for (final seed in tasks.where((task) => task.parentSlug != null)) {
      final taskId = slugToId[seed.slug];
      final parentId = seed.parentSlug == null
          ? null
          : slugToId[seed.parentSlug!];
      if (taskId != null) {
        await _tasks.updateTask(
          taskId,
          TaskUpdate(parentId: parentId, sortIndex: seed.sortIndex),
        );
      }
    }
    return slugToId;
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
      // 避免重复导入
      final existing = await _tasks.findBySlug(seed.slug);
      if (existing != null) {
        slugToId[seed.slug] = existing.id;
        continue;
      }
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
