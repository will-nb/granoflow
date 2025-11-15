import 'package:flutter/foundation.dart';

import '../../data/models/task.dart';
import '../../data/models/task_template.dart';
import '../../data/repositories/seed_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/task_template_repository.dart';

/// 种子项应用器
/// 负责将种子数据中的模板和收件箱项导入到数据库
class SeedItemApplier {
  SeedItemApplier({
    required TaskRepository taskRepository,
    required TaskTemplateRepository templateRepository,
  }) : _tasks = taskRepository,
       _templates = templateRepository;

  final TaskRepository _tasks;
  final TaskTemplateRepository _templates;

  /// 应用模板列表
  Future<void> applyTemplates(List<SeedTemplate> templates, Map<String, String> slugToId) async {
    debugPrint('SeedItemApplier: Applying ${templates.length} templates...');
    int createdTemplates = 0;
    for (final seed in templates) {
      debugPrint(
        'SeedItemApplier: Creating template with seedSlug "${seed.slug}", title: "${seed.title}", parentSlug: ${seed.parentSlug}',
      );
      final parentTaskId = seed.parentSlug == null ? null : slugToId[seed.parentSlug!];
      debugPrint('SeedItemApplier: Template parentTaskId resolved: $parentTaskId');
      final draft = TaskTemplateDraft(
        title: seed.title,
        parentTaskId: null,
        defaultTags: seed.defaultTags,
        seedSlug: seed.slug,
        suggestedEstimateMinutes: seed.suggestedEstimateMinutes,
      );
      final template = await _templates.createTemplateWithSeed(
        draft: draft,
        parentTaskId: parentTaskId,
      );
      debugPrint(
        'SeedItemApplier: Template created successfully - id: ${template.id}, slug: ${seed.slug}',
      );
      if (template.parentTaskId != null) {
        debugPrint('SeedItemApplier: Adjusting template lock for task ${template.parentTaskId}');
        await _tasks.adjustTemplateLock(taskId: template.parentTaskId!, delta: 1);
      }
      createdTemplates++;
    }
    debugPrint(
      'SeedItemApplier: Templates processing complete - Created: $createdTemplates, Total: ${templates.length}',
    );
  }

  /// 应用收件箱项列表
  Future<void> applyInboxItems(List<SeedInboxItem> inboxItems, Map<String, String> slugToId) async {
    debugPrint('SeedItemApplier: Applying ${inboxItems.length} inbox items...');
    int createdInboxItems = 0;
    for (final seed in inboxItems) {
      // 全新安装场景：直接创建 inbox 任务，无需检查重复
      debugPrint(
        'SeedItemApplier: Creating inbox item with seedSlug "${seed.slug}", title: "${seed.title}"',
      );
      final draft = TaskDraft(
        title: seed.title,
        status: TaskStatus.inbox,
        seedSlug: seed.slug,
        allowInstantComplete: false,
      );
      final task = await _tasks.createTask(draft);
      slugToId[seed.slug] = task.id;
      createdInboxItems++;
      debugPrint(
        'SeedItemApplier: Inbox item created successfully - id: ${task.id}, slug: ${seed.slug}',
      );
    }
    debugPrint(
      'SeedItemApplier: Inbox items processing complete - Created: $createdInboxItems, Total: ${inboxItems.length}',
    );
  }
}
