import 'package:collection/collection.dart';
import 'package:isar/isar.dart';

import '../isar/task_template_entity.dart';
import '../models/task_template.dart';

abstract class TaskTemplateRepository {
  Future<List<TaskTemplate>> listRecent({int limit});

  Future<List<TaskTemplate>> search({required String query, int limit});

  Future<TaskTemplate> createTemplate(TaskTemplateDraft draft);

  Future<TaskTemplate> createTemplateWithSeed({
    required TaskTemplateDraft draft,
    required int? parentId,
  });

  Future<void> updateTemplate({
    required int templateId,
    required TaskTemplateUpdate payload,
  });

  Future<void> deleteTemplate(int templateId);

  Future<void> markUsed(int templateId, DateTime usedAt);

  Future<TaskTemplate?> findBySlug(String slug);

  Future<TaskTemplate?> findById(int id);
}

class IsarTaskTemplateRepository implements TaskTemplateRepository {
  IsarTaskTemplateRepository(this._isar);

  final Isar _isar;

  @override
  Future<TaskTemplate> createTemplate(TaskTemplateDraft draft) {
    return _insertTemplate(draft, draft.parentTaskId);
  }

  @override
  Future<TaskTemplate> createTemplateWithSeed({
    required TaskTemplateDraft draft,
    required int? parentId,
  }) {
    return _insertTemplate(draft, parentId);
  }

  @override
  Future<void> deleteTemplate(int templateId) async {
    await _isar.writeTxn(() async {
      await _isar.taskTemplateEntitys.delete(templateId);
    });
  }

  @override
  Future<TaskTemplate?> findById(int id) async {
    final entity = await _isar.taskTemplateEntitys.get(id);
    return entity == null ? null : _toDomain(entity);
  }

  @override
  Future<TaskTemplate?> findBySlug(String slug) async {
    final entity = await _isar.taskTemplateEntitys
        .filter()
        .seedSlugEqualTo(slug)
        .findFirst();
    return entity == null ? null : _toDomain(entity);
  }

  @override
  Future<void> markUsed(int templateId, DateTime usedAt) async {
    await _isar.writeTxn(() async {
      final entity = await _isar.taskTemplateEntitys.get(templateId);
      if (entity == null) {
        return;
      }
      entity
        ..lastUsedAt = usedAt
        ..updatedAt = usedAt;
      await _isar.taskTemplateEntitys.put(entity);
    });
  }

  @override
  Future<List<TaskTemplate>> listRecent({int limit = 6}) async {
    final templates = await _isar.taskTemplateEntitys
        .where()
        .sortByLastUsedAtDesc()
        .thenByUpdatedAtDesc()
        .findAll();
    return templates.map(_toDomain).take(limit).toList(growable: false);
  }

  @override
  Future<List<TaskTemplate>> search({
    required String query,
    int limit = 10,
  }) async {
    final lower = query.toLowerCase();
    final all = await _isar.taskTemplateEntitys.where().findAll();
    final filtered = all
        .where((template) => template.title.toLowerCase().contains(lower))
        .sorted(
          (a, b) => (b.lastUsedAt ?? b.updatedAt).compareTo(
            a.lastUsedAt ?? a.updatedAt,
          ),
        )
        .toList();
    return filtered.map(_toDomain).take(limit).toList(growable: false);
  }

  @override
  Future<void> updateTemplate({
    required int templateId,
    required TaskTemplateUpdate payload,
  }) async {
    await _isar.writeTxn(() async {
      final entity = await _isar.taskTemplateEntitys.get(templateId);
      if (entity == null) {
        return;
      }
      entity
        ..title = payload.title ?? entity.title
        ..parentTaskId = payload.parentTaskId ?? entity.parentTaskId
        ..defaultTags = payload.defaultTags ?? entity.defaultTags
        ..suggestedEstimateMinutes =
            payload.suggestedEstimateMinutes ?? entity.suggestedEstimateMinutes
        ..updatedAt = DateTime.now();
      await _isar.taskTemplateEntitys.put(entity);
    });
  }

  Future<TaskTemplate> _insertTemplate(
    TaskTemplateDraft draft,
    int? parentId,
  ) async {
    return _isar.writeTxn<TaskTemplate>(() async {
      final now = DateTime.now();
      final entity = TaskTemplateEntity()
        ..title = draft.title
        ..parentTaskId = parentId
        ..defaultTags = draft.defaultTags.toList()
        ..createdAt = now
        ..updatedAt = now
        ..lastUsedAt = null
        ..seedSlug = draft.seedSlug
        ..suggestedEstimateMinutes = draft.suggestedEstimateMinutes;
      final id = await _isar.taskTemplateEntitys.put(entity);
      entity.id = id;
      return _toDomain(entity);
    });
  }

  TaskTemplate _toDomain(TaskTemplateEntity entity) {
    return TaskTemplate(
      id: entity.id,
      title: entity.title,
      parentTaskId: entity.parentTaskId,
      defaultTags: List.unmodifiable(entity.defaultTags),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastUsedAt: entity.lastUsedAt,
      seedSlug: entity.seedSlug,
      suggestedEstimateMinutes: entity.suggestedEstimateMinutes,
    );
  }
}
