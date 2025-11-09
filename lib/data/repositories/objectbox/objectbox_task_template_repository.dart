import '../../database/database_adapter.dart';
import '../../models/task_template.dart';
import '../task_template_repository.dart';

class ObjectBoxTaskTemplateRepository implements TaskTemplateRepository {
  const ObjectBoxTaskTemplateRepository(this._adapter);

  final DatabaseAdapter _adapter;

  @override
  Future<TaskTemplate> createTemplate(TaskTemplateDraft draft) {
    throw UnimplementedError('ObjectBoxTaskTemplateRepository.createTemplate');
  }

  @override
  Future<TaskTemplate> createTemplateWithSeed({
    required TaskTemplateDraft draft,
    required String? parentTaskId,
  }) {
    throw UnimplementedError(
      'ObjectBoxTaskTemplateRepository.createTemplateWithSeed',
    );
  }

  @override
  Future<void> deleteTemplate(String templateId) {
    throw UnimplementedError('ObjectBoxTaskTemplateRepository.deleteTemplate');
  }

  @override
  Future<TaskTemplate?> findById(String id) {
    throw UnimplementedError('ObjectBoxTaskTemplateRepository.findById');
  }

  @override
  Future<TaskTemplate?> findBySlug(String slug) {
    throw UnimplementedError('ObjectBoxTaskTemplateRepository.findBySlug');
  }

  @override
  Future<List<TaskTemplate>> listRecent({int limit = 6}) {
    throw UnimplementedError('ObjectBoxTaskTemplateRepository.listRecent');
  }

  @override
  Future<List<TaskTemplate>> search({
    required String query,
    int limit = 10,
  }) {
    throw UnimplementedError('ObjectBoxTaskTemplateRepository.search');
  }

  @override
  Future<void> updateTemplate({
    required String templateId,
    required TaskTemplateUpdate payload,
  }) {
    throw UnimplementedError('ObjectBoxTaskTemplateRepository.updateTemplate');
  }

  @override
  Future<void> markUsed(String templateId, DateTime usedAt) {
    throw UnimplementedError('ObjectBoxTaskTemplateRepository.markUsed');
  }
}
