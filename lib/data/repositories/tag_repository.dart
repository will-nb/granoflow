import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../../core/config/app_constants.dart';
import '../isar/tag_entity.dart';
import '../models/tag.dart';

abstract class TagRepository {
  /// 初始化标签数据（从配置文件加载）
  Future<void> initializeTags();

  /// 清空所有标签数据
  Future<void> clearAll();

  Future<List<Tag>> listByKind(TagKind kind);

  Future<Tag?> findBySlug(String slug);
}

class IsarTagRepository implements TagRepository {
  IsarTagRepository(this._isar);

  final Isar _isar;

  @override
  Future<void> initializeTags() async {
    // 直接从 AppConstants 读取（同步、零开销）
    final tagConfigs = AppConstants.tags;
    
    var created = 0;
    var updated = 0;
    
    await _isar.writeTxn(() async {
      for (final config in tagConfigs) {
        final existing = await _isar.tagEntitys
            .filter()
            .slugEqualTo(config.slug)
            .findFirst();
            
        if (existing != null) {
          // 更新现有标签
          existing.kind = config.kind;
          await _isar.tagEntitys.put(existing);
          updated++;
        } else {
          // 创建新标签
          final entity = TagEntity()
            ..slug = config.slug
            ..kind = config.kind
            ..localizedLabels = []; // 翻译通过ARB处理，这里不需要存储
          await _isar.tagEntitys.put(entity);
          created++;
        }
      }
    });
    
    final total = await _isar.tagEntitys.count();
    
    // 验证结果：只在错误时记录
    if (created + updated != total) {
      debugPrint(
        'TagRepository.initializeTags: Warning - mismatch: created=$created, updated=$updated, total=$total',
      );
    }
  }

  @override
  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.tagEntitys.clear();
    });
  }

  @override
  Future<List<Tag>> listByKind(TagKind kind) async {
    final entities = await _isar.tagEntitys
        .filter()
        .kindEqualTo(kind)
        .findAll();
    return entities.map((entity) => _toDomain(entity, null)).toList(growable: false);
  }

  @override
  Future<Tag?> findBySlug(String slug) async {
    final entity = await _isar.tagEntitys
        .filter()
        .slugEqualTo(slug)
        .findFirst();
    return entity == null ? null : _toDomain(entity, null);
  }

  Tag _toDomain(TagEntity entity, dynamic l10n) {
    // 翻译通过ARB处理，这里返回空的localizedLabels
    // 实际显示时通过TagConfigService获取翻译key，然后在UI层使用Localizations
    return Tag(
      id: entity.id,
      slug: entity.slug,
      kind: entity.kind,
      localizedLabels: const {}, // 不再存储翻译，通过ARB处理
    );
  }
}
