import 'dart:convert';

import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_constants.dart';
import '../../database/database_adapter.dart';
import '../../database/objectbox_adapter.dart';
import '../../models/tag.dart';
import '../../objectbox/tag_entity.dart';
import '../tag_repository.dart';

class ObjectBoxTagRepository implements TagRepository {
  const ObjectBoxTagRepository(this._adapter);

  final DatabaseAdapter _adapter;
  static const _uuid = Uuid();

  ObjectBoxAdapter get _objectBoxAdapter {
    final adapter = _adapter;
    if (adapter is! ObjectBoxAdapter) {
      throw StateError('ObjectBoxTagRepository requires ObjectBoxAdapter');
    }
    return adapter;
  }

  Box<TagEntity> get _tagBox => _objectBoxAdapter.store.box<TagEntity>();

  @override
  Future<void> clearAll() async {
    await _adapter.writeTransaction(() async {
      final box = _tagBox;
      box.removeAll();
    });
  }

  @override
  Future<Tag?> findBySlug(String slug) async {
    return await _adapter.readTransaction(() async {
      final box = _tagBox;
      for (final entity in box.getAll()) {
        if (entity.slug == slug) {
          return _toTag(entity);
        }
      }
      return null;
    });
  }

  @override
  Future<void> initializeTags() async {
    await _adapter.writeTransaction(() async {
      final box = _tagBox;
      
      // 从配置文件加载标签定义
      final tagDefinitions = AppConstants.tags;
      
      // 为每个标签定义创建或更新 TagEntity
      for (final definition in tagDefinitions) {
        // 检查是否已存在
        TagEntity? existingEntity;
        for (final entity in box.getAll()) {
          if (entity.slug == definition.slug) {
            existingEntity = entity;
            break;
          }
        }
        
        // 创建本地化标签映射（使用 slug 作为默认值，实际本地化在 UI 层处理）
        final localizedLabels = <String, String>{
          'en': definition.slug, // 默认使用 slug
        };
        final localizedLabelsJson = jsonEncode(localizedLabels);
        
        if (existingEntity != null) {
          // 更新现有实体
          final updatedEntity = TagEntity(
            obxId: existingEntity.obxId,
            id: existingEntity.id,
            slug: definition.slug,
            kindIndex: definition.kind.index,
            localizedLabelsJson: localizedLabelsJson,
          );
          box.put(updatedEntity);
        } else {
          // 创建新实体
          final tagId = _uuid.v4();
          final entity = TagEntity(
            id: tagId,
            slug: definition.slug,
            kindIndex: definition.kind.index,
            localizedLabelsJson: localizedLabelsJson,
          );
          box.put(entity);
        }
      }
    });
  }

  @override
  Future<List<Tag>> listByKind(TagKind kind) async {
    return await _adapter.readTransaction(() async {
      final box = _tagBox;
      final kindIndex = kind.index;
      final entities = box.getAll().where((e) => e.kindIndex == kindIndex).toList();
      return entities.map(_toTag).toList();
    });
  }

  Tag _toTag(TagEntity entity) {
    // 解析 JSON 字符串为 Map<String, String>
    Map<String, String> localizedLabels;
    try {
      final decoded = jsonDecode(entity.localizedLabelsJson) as Map<String, dynamic>;
      localizedLabels = decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      // 如果解析失败，使用空映射
      localizedLabels = {};
    }

    return Tag(
      id: entity.id,
      slug: entity.slug,
      kind: TagKind.values[entity.kindIndex],
      localizedLabels: localizedLabels,
    );
  }
}
