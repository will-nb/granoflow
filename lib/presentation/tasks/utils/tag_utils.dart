import 'package:flutter/material.dart';
import '../../../core/services/tag_service.dart';
import '../../../data/models/tag.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../widgets/modern_tag.dart';
import '../../widgets/tag_data.dart';

// Tag constants - 使用无前缀的 slug
const executionTags = <String>{'timed', 'fragmented', 'waiting'};
const urgencyTags = <String>{'urgent', 'not_urgent'};
const importanceTags = <String>{'important', 'not_important'};

const quadrantOptionSlugs = <String>[
  'urgent',
  'important',
  'not_urgent',
  'not_important',
];

const executionOptionSlugs = <String>[
  'timed',
  'fragmented',
  'waiting',
];

/// Builds a list of tag chips for a task.
List<Widget> buildTagChips(BuildContext context, Task task) {
  if (task.tags.isEmpty) {
    return const [];
  }
  return task.tags
      .map((slug) => buildModernTag(context, slug))
      .whereType<Widget>()
      .toList(growable: false);
}

/// Builds a modern tag widget from a slug.
Widget? buildModernTag(BuildContext context, String slug) {
  final tagData = slugToTagData(context, slug);
  if (tagData == null) return null;

  return ModernTag(
    label: tagData.label,
    color: tagData.color,
    icon: tagData.icon,
    prefix: tagData.prefix,
    selected: false,
    variant: TagVariant.pill,
    size: TagSize.small,
  );
}

/// Creates TagData from a slug for display.
/// 使用 TagService 统一处理，自动兼容旧数据（带前缀的 slug）
TagData? slugToTagData(BuildContext context, String slug) {
  return TagService.getTagData(context, slug);
}

/// Determines TagKind from a slug.
/// 使用 TagService 从配置查找，不再依赖前缀推断
TagKind getTagKindFromSlug(String slug) {
  return TagService.getKind(slug);
}

/// Returns tag style (color, icon, prefix).
/// 使用 TagService 统一处理
/// 前缀已废弃，始终返回 null
(Color, IconData?, String?) getTagStyle(String slug, TagKind kind) {
  final (color, icon) = TagService.getTagStyle(slug, kind);
  return (color, icon, null); // 前缀已废弃，不再使用
}

/// Returns the localized label for a tag slug.
/// 使用 TagService 统一处理
String tagLabel(AppLocalizations l10n, String slug) {
  return TagService.getLocalizedLabel(l10n, slug);
}

/// Builds an execution type leading widget for a task.
/// Returns null if the task has no execution tags.
Widget? buildExecutionLeading(BuildContext context, Task task) {
  // 查找执行方式标签（兼容旧数据，自动规范化）
  final slug = task.tags.firstWhere(
    (tag) {
      final normalized = TagService.normalizeSlug(tag);
      return executionTags.contains(normalized);
    },
    orElse: () => '',
  );
  if (slug.isEmpty) {
    return null;
  }
  
  final tagData = TagService.getTagData(context, slug);
  if (tagData == null || tagData.icon == null) {
    return null;
  }
  
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: tagData.color.withValues(alpha: 0.18),
    ),
    padding: const EdgeInsets.all(8),
    child: Icon(tagData.icon, color: tagData.color, size: 20),
  );
}

