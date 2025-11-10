import 'dart:async';

import 'package:drift/drift.dart';

import '../../database/database_adapter.dart';
import '../../drift/database.dart' hide TaskTemplate;
import '../../drift/database.dart' as drift show TaskTemplate;
import '../../drift/converters.dart';
import '../../models/task_template.dart';
import '../task_template_repository.dart';

/// Drift 版本的 TaskTemplateRepository 实现
class DriftTaskTemplateRepository implements TaskTemplateRepository {
  DriftTaskTemplateRepository(this._adapter);

  final DatabaseAdapter _adapter;

  /// 获取 AppDatabase 实例
  AppDatabase get _db => AppDatabase.instance;

  @override
  Future<List<TaskTemplate>> listRecent({int limit = 6}) async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.taskTemplates)
        ..where((t) => t.lastUsedAt.isNotNull())
        ..orderBy([(t) => OrderingTerm(expression: t.lastUsedAt, mode: OrderingMode.desc)])
        ..limit(limit);
      final entities = await query.get();
      return entities.map(_toTaskTemplate).toList();
    });
  }

  @override
  Future<List<TaskTemplate>> search({
    required String query,
    int limit = 10,
  }) async {
    return await _adapter.readTransaction(() async {
      final dbQuery = _db.select(_db.taskTemplates)
        ..where((t) => t.title.like('%$query%'))
        ..limit(limit);
      final entities = await dbQuery.get();
      return entities.map(_toTaskTemplate).toList();
    });
  }

  @override
  Future<TaskTemplate> createTemplate(TaskTemplateDraft draft) async {
    final now = DateTime.now();
    final templateId = generateUuid();
    return createTemplateWithSeed(draft: draft, parentTaskId: draft.parentTaskId);
  }

  @override
  Future<TaskTemplate> createTemplateWithSeed({
    required TaskTemplateDraft draft,
    required String? parentTaskId,
  }) async {
    return await _adapter.writeTransaction(() async {
      final now = DateTime.now();
      final templateId = generateUuid();

      final entity = drift.TaskTemplate(
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

      await _db.into(_db.taskTemplates).insert(entity);
      return _toTaskTemplate(entity);
    });
  }

  @override
  Future<void> updateTemplate({
    required String templateId,
    required TaskTemplateUpdate payload,
  }) async {
    await _adapter.writeTransaction(() async {
      final companion = TaskTemplatesCompanion(
        title: payload.title != null ? Value(payload.title!) : const Value.absent(),
        parentTaskId: payload.parentTaskId != null ? Value(payload.parentTaskId) : const Value.absent(),
        defaultTags: payload.defaultTags != null ? Value(payload.defaultTags!) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
        suggestedEstimateMinutes: payload.suggestedEstimateMinutes != null ? Value(payload.suggestedEstimateMinutes) : const Value.absent(),
      );

      await (_db.update(_db.taskTemplates)..where((t) => t.id.equals(templateId))).write(companion);
    });
  }

  @override
  Future<void> deleteTemplate(String templateId) async {
    await _adapter.writeTransaction(() async {
      await (_db.delete(_db.taskTemplates)..where((t) => t.id.equals(templateId))).go();
    });
  }

  @override
  Future<void> markUsed(String templateId, DateTime usedAt) async {
    await _adapter.writeTransaction(() async {
      await (_db.update(_db.taskTemplates)..where((t) => t.id.equals(templateId))).write(
        TaskTemplatesCompanion(
          lastUsedAt: Value(usedAt),
        ),
      );
    });
  }

  @override
  Future<TaskTemplate?> findBySlug(String slug) async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.taskTemplates)..where((t) => t.seedSlug.equals(slug));
      final entity = await query.getSingleOrNull();
      if (entity == null) return null;
      return _toTaskTemplate(entity);
    });
  }

  @override
  Future<TaskTemplate?> findById(String id) async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.taskTemplates)..where((t) => t.id.equals(id));
      final entity = await query.getSingleOrNull();
      if (entity == null) return null;
      return _toTaskTemplate(entity);
    });
  }

  /// 将 Drift TaskTemplate 实体转换为领域模型 TaskTemplate
  TaskTemplate _toTaskTemplate(drift.TaskTemplate entity) {
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
}
