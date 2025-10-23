import '../../data/models/task.dart';
import '../../data/models/task_template.dart';
import '../../data/models/tag.dart';
import '../../data/repositories/seed_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/task_template_repository.dart';
import 'metric_orchestrator.dart';

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
       _metricOrchestrator = metricOrchestrator;

  final SeedRepository _seedRepository;
  final TagRepository _tags;
  final TaskRepository _tasks;
  final TaskTemplateRepository _templates;
  final MetricOrchestrator _metricOrchestrator;

  Future<void> importIfNeeded(String localeCode) async {
    final payload = await loadSeedPayload(localeCode);
    final alreadyImported = await _seedRepository.wasImported(payload.version);
    if (alreadyImported) {
      return;
    }
    await _applyTags(payload.tags);
    final slugToId = await _applyTasks(payload.tasks);
    await _applyInboxItems(payload.inboxItems, slugToId);
    await _applyTemplates(payload.templates, slugToId);
    await _seedRepository.importSeeds(payload);
    await _seedRepository.recordVersion(payload.version);
    await _metricOrchestrator.requestRecompute(
      MetricRecomputeReason.seedImport,
    );
  }

  Future<void> _applyTags(List<SeedTag> tags) async {
    final tagModels = tags
        .map(
          (tag) => Tag(
            id: 0,
            slug: tag.slug,
            kind: tag.kind,
            localizedLabels: tag.labels,
          ),
        )
        .toList();
    await _tags.ensureSeeded(tagModels);
  }

  Future<Map<String, int>> _applyTasks(List<SeedTask> tasks) async {
    final Map<String, int> slugToId = <String, int>{};
    var order = 0;
    for (final seed in tasks) {
      final draft = TaskDraft(
        title: seed.title,
        status: seed.status,
        parentId: null,
        tags: seed.tags,
        allowInstantComplete: seed.allowInstantComplete,
        seedSlug: seed.slug,
        sortIndex: seed.sortIndex == 0 ? order.toDouble() : seed.sortIndex,
      );
      final task = await _tasks.createTask(draft);
      slugToId[seed.slug] = task.id;
      order++;
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
