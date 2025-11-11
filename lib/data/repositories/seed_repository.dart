import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/task.dart';

class SeedPayload {
  const SeedPayload({
    required this.version,
    required this.tasks,
    required this.templates,
    required this.inboxItems,
  });

  final String version;
  final List<SeedTask> tasks;
  final List<SeedTemplate> templates;
  final List<SeedInboxItem> inboxItems;
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
    this.dueAt,
    this.taskKind,
  });

  final String slug;
  final String title;
  final TaskStatus status;
  final String? parentSlug;
  final List<String> tags;
  final bool allowInstantComplete;
  final double sortIndex;
  final dynamic dueAt;
  final String? taskKind; // 从种子文件中读取的字符串，用于区分项目/里程碑/普通任务
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
    this.suggestedTemplateSlug,
  });

  final String slug;
  final String title;
  final String note;
  final String? suggestedTemplateSlug;
}

abstract class SeedRepository {
  Future<bool> wasImported(String version);

  Future<void> importSeeds(SeedPayload payload);

  Future<String?> latestVersion();

  Future<void> recordVersion(String version);

  /// 清除指定版本的导入记录（用于强制重新导入）
  Future<void> clearVersion(String version);
}

Future<SeedPayload> loadSeedPayload(String localeCode) async {
  debugPrint('🔵 loadSeedPayload: Loading seed data for locale: $localeCode');
  final normalized = switch (localeCode) {
    final code when code.startsWith('zh_HK') => 'zh_HK',
    final code when code.startsWith('zh_CN') => 'zh_CN',
    final code when code.startsWith('zh') => 'zh_CN', // 兜底中文使用简体中文
    final code when code.startsWith('en') => 'en',
    _ => 'en',
  };
  debugPrint('🔵 loadSeedPayload: Normalized locale: $normalized');

  debugPrint('🔵 loadSeedPayload: Loading version.json...');
  final versionJson = await rootBundle
      .loadString('assets/seeds/version.json')
      .then((value) => jsonDecode(value) as Map<String, dynamic>);
  debugPrint('🔵 loadSeedPayload: Version loaded: ${versionJson['version']}');
  
  debugPrint('🔵 loadSeedPayload: Loading tasks.json from assets/seeds/$normalized/tasks.json...');
  final tasksJson = await rootBundle
      .loadString('assets/seeds/$normalized/tasks.json')
      .then((value) => jsonDecode(value) as Map<String, dynamic>);
  debugPrint('🔵 loadSeedPayload: Tasks loaded: ${(tasksJson['tasks'] as List?)?.length ?? 0} tasks');
  
  debugPrint('🔵 loadSeedPayload: Loading templates.json from assets/seeds/$normalized/templates.json...');
  final templatesJson = await rootBundle
      .loadString('assets/seeds/$normalized/templates.json')
      .then((value) => jsonDecode(value) as Map<String, dynamic>);
  debugPrint('🔵 loadSeedPayload: Templates loaded: ${(templatesJson['templates'] as List?)?.length ?? 0} templates');
  
  debugPrint('🔵 loadSeedPayload: Loading inbox.json from assets/seeds/$normalized/inbox.json...');
  final inboxJson = await rootBundle
      .loadString('assets/seeds/$normalized/inbox.json')
      .then((value) => jsonDecode(value) as Map<String, dynamic>);
  debugPrint('🔵 loadSeedPayload: Inbox items loaded: ${(inboxJson['inbox'] as List?)?.length ?? 0} items');

  return SeedPayload(
    version: versionJson['version'] as String,
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
            dueAt: raw['dueAt'],
            taskKind: raw['taskKind'] as String?,
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
            suggestedTemplateSlug: raw['suggestedTemplateSlug'] as String?,
          ),
        )
        .toList(),
  );
}
