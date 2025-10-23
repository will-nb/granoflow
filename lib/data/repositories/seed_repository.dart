import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:isar/isar.dart';

import '../models/tag.dart';
import '../models/task.dart';
import '../isar/seed_import_log_entity.dart';

class SeedPayload {
  const SeedPayload({
    required this.version,
    required this.tags,
    required this.tasks,
    required this.templates,
    required this.inboxItems,
  });

  final String version;
  final List<SeedTag> tags;
  final List<SeedTask> tasks;
  final List<SeedTemplate> templates;
  final List<SeedInboxItem> inboxItems;
}

class SeedTag {
  const SeedTag({required this.slug, required this.kind, required this.labels});

  final String slug;
  final TagKind kind;
  final Map<String, String> labels;
}

class SeedTask {
  const SeedTask({
    required this.slug,
    required this.title,
    required this.status,
    required this.tags,
    required this.allowInstantComplete,
    this.parentSlug,
    this.sortIndex = 0,
  });

  final String slug;
  final String title;
  final TaskStatus status;
  final String? parentSlug;
  final List<String> tags;
  final bool allowInstantComplete;
  final double sortIndex;
}

class SeedTemplate {
  const SeedTemplate({
    required this.slug,
    required this.title,
    required this.parentSlug,
    required this.defaultTags,
    this.suggestedEstimateMinutes,
  });

  final String slug;
  final String title;
  final String? parentSlug;
  final List<String> defaultTags;
  final int? suggestedEstimateMinutes;
}

class SeedInboxItem {
  const SeedInboxItem({
    required this.slug,
    required this.title,
    required this.note,
    required this.suggestedTemplateSlug,
  });

  final String slug;
  final String title;
  final String note;
  final String suggestedTemplateSlug;
}

abstract class SeedRepository {
  Future<bool> wasImported(String version);

  Future<void> importSeeds(SeedPayload payload);

  Future<String?> latestVersion();

  Future<void> recordVersion(String version);
}

class IsarSeedRepository implements SeedRepository {
  IsarSeedRepository(this._isar);

  final Isar _isar;

  static const int _logId = 1;

  @override
  Future<bool> wasImported(String version) async {
    final log = await _isar.seedImportLogEntitys.get(_logId);
    return log?.version == version;
  }

  @override
  Future<void> importSeeds(SeedPayload payload) async {
    // Seed application handled by SeedImportService; repository persists metadata only.
  }

  @override
  Future<String?> latestVersion() async {
    final log = await _isar.seedImportLogEntitys.get(_logId);
    return log?.version;
  }

  @override
  Future<void> recordVersion(String version) async {
    await _isar.writeTxn(() async {
      final entity = SeedImportLogEntity()
        ..id = _logId
        ..version = version
        ..importedAt = DateTime.now();
      await _isar.seedImportLogEntitys.put(entity);
    });
  }
}

Future<SeedPayload> loadSeedPayload(String localeCode) async {
  final normalized = switch (localeCode) {
    final code when code.startsWith('zh_Hant') => 'zh_Hant',
    final code when code.startsWith('zh') => 'zh_Hans',
    final code when code.startsWith('en') => 'en',
    _ => 'en',
  };

  final versionJson = await rootBundle
      .loadString('assets/seeds/version.json')
      .then((value) => jsonDecode(value) as Map<String, dynamic>);
  final tagsJson = await rootBundle
      .loadString('assets/seeds/tags.json')
      .then((value) => jsonDecode(value) as Map<String, dynamic>);
  final tasksJson = await rootBundle
      .loadString('assets/seeds/$normalized/tasks.json')
      .then((value) => jsonDecode(value) as Map<String, dynamic>);
  final templatesJson = await rootBundle
      .loadString('assets/seeds/$normalized/templates.json')
      .then((value) => jsonDecode(value) as Map<String, dynamic>);
  final inboxJson = await rootBundle
      .loadString('assets/seeds/$normalized/inbox.json')
      .then((value) => jsonDecode(value) as Map<String, dynamic>);

  return SeedPayload(
    version: versionJson['version'] as String,
    tags: (tagsJson['tags'] as List<dynamic>)
        .map((raw) => raw as Map<String, dynamic>)
        .map(
          (raw) => SeedTag(
            slug: raw['slug'] as String,
            kind: TagKind.values.byName(raw['kind'] as String),
            labels: (raw['localizations'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, value as String),
            ),
          ),
        )
        .toList(),
    tasks: (tasksJson['tasks'] as List<dynamic>)
        .map((raw) => raw as Map<String, dynamic>)
        .map((raw) {
          final statusRaw = ((raw['status'] as String?) ?? 'pending')
              .replaceAll('_', '')
              .toLowerCase();
          final status = TaskStatus.values.firstWhere(
            (value) => value.name.toLowerCase() == statusRaw,
            orElse: () => TaskStatus.pending,
          );
          return SeedTask(
            slug: raw['slug'] as String,
            title: raw['title'] as String,
            status: status,
            parentSlug: raw['parentSlug'] as String?,
            tags: ((raw['tags'] as List<dynamic>?) ?? const <dynamic>[])
                .cast<String>(),
            allowInstantComplete:
                (raw['allowInstantComplete'] as bool?) ?? false,
            sortIndex: (raw['sortIndex'] as num?)?.toDouble() ?? 0,
          );
        })
        .toList(),
    templates: (templatesJson['templates'] as List<dynamic>)
        .map((raw) => raw as Map<String, dynamic>)
        .map(
          (raw) => SeedTemplate(
            slug: raw['slug'] as String,
            title: raw['title'] as String,
            parentSlug: raw['parentSlug'] as String?,
            defaultTags:
                ((raw['defaultTags'] as List<dynamic>?) ?? const <dynamic>[])
                    .cast<String>(),
            suggestedEstimateMinutes: (raw['suggestedEstimateMinutes'] as int?),
          ),
        )
        .toList(),
    inboxItems: (inboxJson['items'] as List<dynamic>)
        .map((raw) => raw as Map<String, dynamic>)
        .map(
          (raw) => SeedInboxItem(
            slug: raw['slug'] as String,
            title: raw['title'] as String,
            note: raw['note'] as String,
            suggestedTemplateSlug: raw['suggestedTemplateSlug'] as String,
          ),
        )
        .toList(),
  );
}
