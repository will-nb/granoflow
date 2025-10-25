import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../isar/tag_entity.dart';
import '../models/tag.dart';

abstract class TagRepository {
  Future<void> ensureSeeded(List<Tag> tags);

  Future<List<Tag>> listByKind(TagKind kind);

  Future<Tag?> findBySlug(String slug);
}

class IsarTagRepository implements TagRepository {
  IsarTagRepository(this._isar);

  final Isar _isar;

  @override
  Future<void> ensureSeeded(List<Tag> tags) async {
    debugPrint('TagRepository.ensureSeeded: incoming=${tags.length}, slugs=${tags.map((t)=>t.slug).join(', ')}');
    var created = 0;
    var updated = 0;
    await _isar.writeTxn(() async {
      for (final tag in tags) {
        final existing = await _isar.tagEntitys
            .filter()
            .slugEqualTo(tag.slug)
            .findFirst();
        if (existing != null) {
          existing
            ..kind = tag.kind
            ..localizedLabels = tag.localizedLabels.entries
                .map(
                  (entry) => TagLocalizationEntry()
                    ..locale = entry.key
                    ..label = entry.value,
                )
                .toList();
          await _isar.tagEntitys.put(existing);
          updated++;
          continue;
        }
        final entity = TagEntity()
          ..slug = tag.slug
          ..kind = tag.kind
          ..localizedLabels = tag.localizedLabels.entries
              .map(
                (entry) => TagLocalizationEntry()
                  ..locale = entry.key
                  ..label = entry.value,
              )
              .toList();
        await _isar.tagEntitys.put(entity);
        created++;
      }
    });
    final total = await _isar.tagEntitys.count();
    debugPrint('TagRepository.ensureSeeded: done (created=$created, updated=$updated, total=$total)');
  }

  @override
  Future<List<Tag>> listByKind(TagKind kind) async {
    final entities = await _isar.tagEntitys
        .filter()
        .kindEqualTo(kind)
        .findAll();
    debugPrint('TagRepository.listByKind($kind): count=${entities.length}, slugs=${entities.map((e)=>e.slug).join(', ')}');
    return entities.map(_toDomain).toList(growable: false);
  }

  @override
  Future<Tag?> findBySlug(String slug) async {
    final entity = await _isar.tagEntitys
        .filter()
        .slugEqualTo(slug)
        .findFirst();
    return entity == null ? null : _toDomain(entity);
  }

  Tag _toDomain(TagEntity entity) {
    final map = <String, String>{
      for (final entry in entity.localizedLabels) entry.locale: entry.label,
    };
    return Tag(
      id: entity.id,
      slug: entity.slug,
      kind: entity.kind,
      localizedLabels: map,
    );
  }
}
