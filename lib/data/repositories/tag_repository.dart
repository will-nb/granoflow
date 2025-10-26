import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../../core/services/tag_config_service.dart';
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
    debugPrint('TagRepository.initializeTags: Loading tags from config...');
    
    final configService = TagConfigService.instance;
    final tagConfigs = await configService.getTags();
    
    debugPrint('TagRepository.initializeTags: Found ${tagConfigs.length} tag configs');
    for (final config in tagConfigs) {
      debugPrint('TagRepository.initializeTags: Config - slug=${config.slug}, kind=${config.kind}');
    }
    
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
          debugPrint('TagRepository.initializeTags: Updating existing tag ${config.slug} from ${existing.kind} to ${config.kind}');
          existing.kind = config.kind;
          await _isar.tagEntitys.put(existing);
          updated++;
        } else {
          // 创建新标签
          debugPrint('TagRepository.initializeTags: Creating new tag ${config.slug} with kind ${config.kind}');
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
    debugPrint('TagRepository.initializeTags: done (created=$created, updated=$updated, total=$total)');
    
    // 验证结果
    for (final kind in TagKind.values) {
      final entities = await _isar.tagEntitys
          .filter()
          .kindEqualTo(kind)
          .findAll();
      debugPrint('TagRepository.initializeTags: After init - $kind: count=${entities.length}, slugs=${entities.map((e)=>e.slug).join(', ')}');
    }
  }

  @override
  Future<void> clearAll() async {
    debugPrint('TagRepository.clearAll: Clearing all tags...');
    await _isar.writeTxn(() async {
      await _isar.tagEntitys.clear();
    });
    debugPrint('TagRepository.clearAll: All tags cleared');
  }

  @override
  Future<List<Tag>> listByKind(TagKind kind) async {
    final entities = await _isar.tagEntitys
        .filter()
        .kindEqualTo(kind)
        .findAll();
    debugPrint('TagRepository.listByKind($kind): count=${entities.length}, slugs=${entities.map((e)=>e.slug).join(', ')}');
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
