import '../models/task_template.dart';

abstract class TaskTemplateRepository {
  Future<List<TaskTemplate>> listRecent({int limit});

  Future<List<TaskTemplate>> search({required String query, int limit});

  Future<TaskTemplate> createTemplate(TaskTemplateDraft draft);

  Future<TaskTemplate> createTemplateWithSeed({
    required TaskTemplateDraft draft,
    required String? parentTaskId,
  });

  Future<void> updateTemplate({
    required String templateId,
    required TaskTemplateUpdate payload,
  });

  Future<void> deleteTemplate(String templateId);

  Future<void> markUsed(String templateId, DateTime usedAt);

  Future<TaskTemplate?> findBySlug(String slug);

  Future<TaskTemplate?> findById(String id);
}
