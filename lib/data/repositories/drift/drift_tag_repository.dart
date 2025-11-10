import 'dart:async';

import 'package:drift/drift.dart';

import '../../../core/config/app_constants.dart';
import '../../database/database_adapter.dart';
import '../../drift/database.dart' hide Tag;
import '../../drift/database.dart' as drift show Tag;
import '../../drift/converters.dart';
import '../../models/tag.dart';
import '../tag_repository.dart';

/// Drift 版本的 TagRepository 实现
class DriftTagRepository implements TagRepository {
  DriftTagRepository(this._adapter);

  final DatabaseAdapter _adapter;

  /// 获取 AppDatabase 实例
  AppDatabase get _db => AppDatabase.instance;

  @override
  Future<void> initializeTags() async {
    await _adapter.writeTransaction(() async {
      // 从配置文件加载标签定义
      final tagDefinitions = AppConstants.tags;

      // 为每个标签定义创建或更新 TagEntity
      for (final definition in tagDefinitions) {
        // 检查是否已存在
        final existingQuery = _db.select(_db.tags)
          ..where((t) => t.slug.equals(definition.slug));
        final existing = await existingQuery.getSingleOrNull();

        // 创建本地化标签映射（使用 slug 作为默认值，实际本地化在 UI 层处理）
        final localizedLabels = <String, String>{
          'en': definition.slug, // 默认使用 slug
        };

        if (existing != null) {
          // 更新现有实体
          await (_db.update(_db.tags)..where((t) => t.id.equals(existing.id))).write(
            TagsCompanion(
              slug: Value(definition.slug),
              kindIndex: Value(definition.kind.index),
              localizedLabelsJson: Value(localizedLabels),
            ),
          );
        } else {
          // 创建新实体
          final tagId = generateUuid();
          await _db.into(_db.tags).insert(TagsCompanion.insert(
            id: tagId,
            slug: definition.slug,
            kindIndex: definition.kind.index,
            localizedLabelsJson: localizedLabels,
          ));
        }
      }
    });
  }

  @override
  Future<void> clearAll() async {
    await _adapter.writeTransaction(() async {
      await (_db.delete(_db.tags)).go();
    });
  }

  @override
  Future<List<Tag>> listByKind(TagKind kind) async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.tags)
        ..where((t) => t.kindIndex.equals(kind.index));
      final entities = await query.get();
      return entities.map(_toTag).toList();
    });
  }

  @override
  Future<Tag?> findBySlug(String slug) async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.tags)..where((t) => t.slug.equals(slug));
      final entity = await query.getSingleOrNull();
      if (entity == null) return null;
      return _toTag(entity);
    });
  }

  /// 将 Drift Tag 实体转换为领域模型 Tag
  Tag _toTag(drift.Tag entity) {
    return Tag(
      id: entity.id,
      slug: entity.slug,
      kind: TagKind.values[entity.kindIndex],
      localizedLabels: entity.localizedLabelsJson,
    );
  }
}
