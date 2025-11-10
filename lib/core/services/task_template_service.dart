import '../../data/models/task.dart';
import '../../data/models/task_template.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/task_template_repository.dart';
import 'task_service.dart';
import '../constants/task_constants.dart';

class TaskTemplateService {
  TaskTemplateService({
    required TaskTemplateRepository templateRepository,
    required TaskRepository taskRepository,
    required TaskService taskService,
  }) : _templates = templateRepository,
       _tasks = taskRepository,
       _taskService = taskService;

  final TaskTemplateRepository _templates;
  final TaskRepository _tasks;
  final TaskService _taskService;

  Future<TaskTemplate> createTemplate(TaskTemplateDraft draft) async {
    final template = await _templates.createTemplate(draft);
    if (template.parentTaskId != null) {
      await _tasks.adjustTemplateLock(taskId: template.parentTaskId!, delta: 1);
    }
    return template;
  }

  Future<void> updateTemplate(int templateId, TaskTemplateUpdate payload) {
    return _updateTemplateInternal(templateId, payload);
  }

  Future<void> deleteTemplate(int templateId) async {
    final template = await _templates.findById(templateId);
    if (template?.parentTaskId != null) {
      await _tasks.adjustTemplateLock(
        taskId: template!.parentTaskId!,
        delta: -1,
      );
    }
    await _templates.deleteTemplate(templateId);
  }

  Future<List<TaskTemplate>> listRecent(int limit) {
    return _templates.listRecent(limit: limit);
  }

  Future<List<TaskTemplate>> search(String query, {int limit = 10}) {
    if (query.isEmpty) {
      return listRecent(limit);
    }
    return _templates.search(query: query, limit: limit);
  }

  Future<Task> applyTemplate({
    required String templateId,
    TaskTemplateOverrides? overrides,
  }) async {
    final template = await _templates.findById(templateId);
    if (template == null) {
      throw StateError('Template not found');
    }
    final parentId = overrides?.parentTaskId ?? template.parentTaskId;
    if (parentId != null) {
      await _tasks.adjustTemplateLock(taskId: parentId, delta: 0);
    }
    final task = await _taskService.captureInboxTask(
      title: template.title,
      tags: overrides?.tags ?? template.defaultTags,
    );
    if (parentId != null) {
      await _tasks.updateTask(
        task.id,
        TaskUpdate(parentId: parentId, sortIndex: TaskConstants.DEFAULT_SORT_INDEX),
      );
    }
    await _taskService.updateDetails(
      taskId: task.id,
      payload: TaskUpdate(
        status: TaskStatus.pending,
        allowInstantComplete: overrides?.allowInstantComplete,
      ),
    );
    if (overrides?.dueAt != null) {
      final due = overrides!.dueAt!;
      final now = DateTime.now();
      final normalizedNow = DateTime(now.year, now.month, now.day);
      final normalizedDue = DateTime(due.year, due.month, due.day);
      final difference = normalizedDue.difference(normalizedNow).inDays;
      final section = difference <= 0
          ? TaskSection.today
          : difference == 1
          ? TaskSection.tomorrow
          : TaskSection.later;
      await _taskService.planTask(
        taskId: task.id,
        dueDateLocal: due,
        section: section,
      );
    }
    await _templates.markUsed(templateId, DateTime.now());
    return task;
  }

  Future<void> _updateTemplateInternal(
    String templateId,
    TaskTemplateUpdate payload,
  ) async {
    final existing = await _templates.findById(templateId);
    if (existing == null) {
      return;
    }
    final previousParent = existing.parentTaskId;
    await _templates.updateTemplate(templateId: templateId, payload: payload);
    final updated = await _templates.findById(templateId);
    if (updated == null) {
      return;
    }
    if (previousParent != updated.parentTaskId) {
      if (previousParent != null) {
        await _tasks.adjustTemplateLock(taskId: previousParent, delta: -1);
      }
      if (updated.parentTaskId != null) {
        await _tasks.adjustTemplateLock(
          taskId: updated.parentTaskId!,
          delta: 1,
        );
      }
    }
  }
}

}
