import 'package:flutter/material.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import '../../../data/models/tag.dart';
import '../../../data/models/task.dart';
import '../../widgets/modern_tag.dart';
import '../../widgets/tag_data.dart';

// Tag constants
const executionTags = <String>{'#timed', '#fragmented', '#waiting'};
const urgencyTags = <String>{'#urgent', '#not_urgent'};
const importanceTags = <String>{'#important', '#not_important'};

const quadrantOptionSlugs = <String>[
  '#urgent',
  '#important',
  '#not_urgent',
  '#not_important',
];

const executionOptionSlugs = <String>[
  '#timed',
  '#fragmented',
  '#waiting',
];

// 标签名称（不带前缀）
const contextTagNames = <String>{'anywhere', 'home', 'workplace', 'local', 'travel'};
const urgencyTagNames = <String>{'urgent', 'not_urgent'};
const importanceTagNames = <String>{'important', 'not_important'};
const executionTagNames = <String>{'timed', 'fragmented', 'waiting'};

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
TagData? slugToTagData(BuildContext context, String slug) {
  final l10n = AppLocalizations.of(context);
  
  // 如果slug没有前缀，根据内容添加适当的前缀
  String normalizedSlug = slug;
  if (!slug.startsWith('@') && !slug.startsWith('#')) {
    // 根据标签内容判断类型并添加前缀
    if (contextTagNames.contains(slug)) {
      normalizedSlug = '@$slug';
    } else if (urgencyTagNames.contains(slug)) {
      normalizedSlug = '#$slug';
    } else if (importanceTagNames.contains(slug)) {
      normalizedSlug = '#$slug';
    } else if (executionTagNames.contains(slug)) {
      normalizedSlug = '#$slug';
    }
  }
  
  final kind = getTagKindFromSlug(normalizedSlug);
  final label = tagLabel(l10n, normalizedSlug);
  final (color, icon, prefix) = getTagStyle(normalizedSlug, kind);
  
  return TagData(
    slug: normalizedSlug,
    label: label,
    color: color,
    icon: icon,
    prefix: prefix,
    kind: kind,
  );
}

/// Determines TagKind from a slug.
TagKind getTagKindFromSlug(String slug) {
  if (slug.startsWith('@')) return TagKind.context;
  if (urgencyTags.contains(slug)) return TagKind.urgency;
  if (importanceTags.contains(slug)) return TagKind.importance;
  if (executionTags.contains(slug)) return TagKind.execution;
  return TagKind.special;
}

/// Returns tag style (color, icon, prefix).
(Color, IconData?, String?) getTagStyle(String slug, TagKind kind) {
  // Context tags - 上下文标签（场景）
  if (slug.startsWith('@')) {
    return (
      const Color(0xFF5AC9B0), // OceanBreezeColorSchemes.lakeCyan
      Icons.place_outlined,
      null,
    );
  }

  // Priority tags - 优先级标签
  if (slug.startsWith('#')) {
    switch (slug) {
      case '#urgent':
        return (
          const Color(0xFFFF6B9D), // OceanBreezeColorSchemes.softPink
          Icons.priority_high,
          null,
        );
      case '#not_urgent':
        return (
          const Color(0xFF9E9E9E), // OceanBreezeColorSchemes.lightBlueGray
          Icons.event_available,
          null,
        );
      case '#important':
        return (
          const Color(0xFFFFB74D), // OceanBreezeColorSchemes.warmYellow
          Icons.star,
          null,
        );
      case '#not_important':
        return (
          const Color(0xFFBDBDBD), // OceanBreezeColorSchemes.silverGray
          Icons.star_outline,
          null,
        );
      case '#waiting':
        return (
          const Color(0xFF9E9E9E), // OceanBreezeColorSchemes.disabledGray
          Icons.hourglass_empty,
          null,
        );
      case '#timed':
        return (const Color(0xFFFF6B9D), Icons.schedule, null); // OceanBreezeColorSchemes.softPink
      case '#fragmented':
        return (
          const Color(0xFF5AC9B0), // OceanBreezeColorSchemes.lakeCyan
          Icons.flash_on_outlined,
          null,
        );
      default:
        // 未知的优先级标签，使用默认样式
        return (
          const Color(0xFF64B5F6), // OceanBreezeColorSchemes.seaSaltBlue
          Icons.tag,
          null,
        );
    }
  }

  // Special tags - 特殊标签
  if (slug == 'wasted') {
    return (
      const Color(0xFF757575), // OceanBreezeColorSchemes.secondaryText
      Icons.delete_outline,
      null,
    );
  }

  // Default - 默认样式
  return (const Color(0xFF64B5F6), Icons.tag, null); // OceanBreezeColorSchemes.seaSaltBlue
}

/// Returns the localized label for a tag slug.
String tagLabel(AppLocalizations l10n, String slug) {
  switch (slug) {
    // 上下文标签
    case '@anywhere':
      return l10n.tag_anywhere;
    case '@home':
      return l10n.tag_home;
      case '@company':
        return l10n.tag_company;
      case '@school':
        return l10n.tag_school;
    case '@local':
      return l10n.tag_local;
    case '@travel':
      return l10n.tag_travel;
    // 紧急程度标签
    case '#urgent':
      return l10n.tag_urgent;
    case '#not_urgent':
      return l10n.tag_not_urgent;
    // 重要程度标签
    case '#important':
      return l10n.tag_important;
    case '#not_important':
      return l10n.tag_not_important;
    // 执行方式标签
    case '#timed':
      return l10n.tag_timed;
    case '#fragmented':
      return l10n.tag_fragmented;
    case '#waiting':
      return l10n.tag_waiting;
    default:
      return slug;
  }
}

/// Builds an execution type leading widget for a task.
/// Returns null if the task has no execution tags.
Widget? buildExecutionLeading(BuildContext context, Task task) {
  final slug = task.tags.firstWhere(
    (tag) => executionTags.contains(tag),
    orElse: () => '',
  );
  if (slug.isEmpty) {
    return null;
  }
  final kind = getTagKindFromSlug(slug);
  final (color, icon, _) = getTagStyle(slug, kind);
  if (icon == null) {
    return null;
  }
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: 0.18),
    ),
    padding: const EdgeInsets.all(8),
    child: Icon(icon, color: color, size: 20),
  );
}

