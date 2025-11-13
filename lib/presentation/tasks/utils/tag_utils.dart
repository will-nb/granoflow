import 'package:flutter/material.dart';
import '../../../core/services/tag_service.dart';
import '../../../data/models/tag.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../widgets/modern_tag.dart';
import '../../widgets/tag_data.dart';

// Tag constants - 使用无前缀的 slug
const urgencyTags = <String>{'urgent', 'not_urgent'};
const importanceTags = <String>{'important', 'not_important'};

const quadrantOptionSlugs = <String>[
  'urgent',
  'important',
  'not_urgent',
  'not_important',
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

