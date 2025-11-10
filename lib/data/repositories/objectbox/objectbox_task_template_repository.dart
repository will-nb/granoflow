import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

import '../../database/database_adapter.dart';
import '../../database/objectbox_adapter.dart';
import '../../models/task_template.dart';
import '../../objectbox/task_entity.dart';
import '../../objectbox/task_template_entity.dart';
import '../task_template_repository.dart';

class ObjectBoxTaskTemplateRepository implements TaskTemplateRepository {
  const ObjectBoxTaskTemplateRepository(this._adapter);

  final DatabaseAdapter _adapter;
  static const _uuid = Uuid();

  ObjectBoxAdapter get _objectBoxAdapter {
    final adapter = _adapter;
    if (adapter is! ObjectBoxAdapter) {
      throw StateError(
        'ObjectBoxTaskTemplateRepository requires ObjectBoxAdapter',
      );
    }
    return adapter;
  }

  Box<TaskTemplateEntity> get _templateBox =>
      _objectBoxAdapter.store.box<TaskTemplateEntity>();

  @override
  Future<TaskTemplate> createTemplate(TaskTemplateDraft draft) {
    throw UnimplementedError('ObjectBoxTaskTemplateRepository.createTemplate');
  }

  @override
  Future<TaskTemplate> createTemplateWithSeed({
    required TaskTemplateDraft draft,
    required String? parentTaskId,
  }) async {
    return await _adapter.writeTransaction(() async {
      final box = _templateBox;
      final now = DateTime.now();
      final templateId = _uuid.v4();

      final entity = TaskTemplateEntity(
        id: templateId,
        title: draft.title,
        parentTaskId: parentTaskId ?? draft.parentTaskId,
        defaultTags: List<String>.from(draft.defaultTags),
        createdAt: now,
        updatedAt: now,
        lastUsedAt: null,
        seedSlug: draft.seedSlug,
        suggestedEstimateMinutes: draft.suggestedEstimateMinutes,
      );

      box.put(entity);

      // 如果设置了 parentTaskId，需要设置 ObjectBox 关系
      if (entity.parentTaskId != null) {
        // 查找父任务的 obxId
        final taskBox = _objectBoxAdapter.store.box<TaskEntity>();
        final parentTask = taskBox.getAll().firstWhere(
              (task) => task.id == entity.parentTaskId,
              orElse: () => throw StateError(
                'Parent task ${entity.parentTaskId} not found',
              ),
            );
        entity.parentTask.targetId = parentTask.obxId;
        box.put(entity);
      }

      return _toTaskTemplate(entity);
    });
  }

  /// 将 TaskTemplateEntity 转换为 TaskTemplate
  TaskTemplate _toTaskTemplate(TaskTemplateEntity entity) {
    return TaskTemplate(
      id: entity.id,
      title: entity.title,
      parentTaskId: entity.parentTaskId,
      defaultTags: List<String>.unmodifiable(entity.defaultTags),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastUsedAt: entity.lastUsedAt,
      seedSlug: entity.seedSlug,
      suggestedEstimateMinutes: entity.suggestedEstimateMinutes,
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
