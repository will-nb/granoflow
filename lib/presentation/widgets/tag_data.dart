import 'package:flutter/material.dart';

import '../../core/services/tag_service.dart';
import '../../data/models/tag.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';

/// 标签的UI数据模型
///
/// 包含标签显示所需的所有信息：文本、颜色、图标、前缀等
@immutable
class TagData {
  const TagData({
    required this.slug,
    required this.label,
    required this.color,
    required this.kind,
    this.icon,
    this.prefix,
  });

  /// 标签唯一标识（无前缀，如 home, urgent）
  final String slug;

  /// 标签显示文本（已本地化）
  final String label;

  /// 标签主题色
  final Color color;

  /// 标签图标（可选）
  final IconData? icon;

  /// 标签前缀（如 @、#）
  final String? prefix;

  /// 标签类型
  final TagKind kind;

  /// 从 Tag 模型转换为 TagData
  ///
  /// 自动根据 slug 和 kind 分配合适的颜色和图标
  /// 注意：tag.slug 可能包含前缀（旧数据），会自动规范化
  factory TagData.fromTag(Tag tag, String locale) {
    // 由于 Tag.localizedLabels 为空，我们需要使用 slug 作为回退
    // 实际的本地化会在 UI 层通过 AppLocalizations 处理
    final label = tag.labelForLocale(locale);
    final normalizedSlug = TagService.normalizeSlug(tag.slug);
    final (color, icon) = TagService.getTagStyle(normalizedSlug, tag.kind);

    return TagData(
      slug: normalizedSlug, // 使用规范化后的 slug（无前缀）
      label: label,
      color: color,
      icon: icon,
      prefix: null, // 前缀已废弃，不再显示
      kind: tag.kind,
    );
  }

  /// 从 Tag 模型转换为 TagData（使用 AppLocalizations 进行本地化）
  ///
  /// 这是推荐的方法，用于在 UI 层获取正确的本地化标签
  /// 使用 TagService 统一处理，自动兼容旧数据（带前缀的 slug）
  factory TagData.fromTagWithLocalization(Tag tag, BuildContext context) {
    final tagData = TagService.getTagData(context, tag.slug);
    
    // 如果 TagService 找不到，使用 tag.kind 作为回退
    if (tagData != null) {
      return tagData;
    }
    
    // 回退方案：使用 Tag 的 kind，但 slug 规范化
    final l10n = AppLocalizations.of(context);
    final normalizedSlug = TagService.normalizeSlug(tag.slug);
    final label = TagService.getLocalizedLabel(l10n, tag.slug);
    final (color, icon) = TagService.getTagStyle(normalizedSlug, tag.kind);

    return TagData(
      slug: normalizedSlug,
      label: label,
      color: color,
      icon: icon,
      prefix: null, // 前缀已废弃，不再显示
      kind: tag.kind,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagData &&
          runtimeType == other.runtimeType &&
          slug == other.slug &&
          label == other.label &&
          color == other.color &&
          icon == other.icon &&
          prefix == other.prefix &&
          kind == other.kind;

  @override
  int get hashCode =>
      slug.hashCode ^
      label.hashCode ^
      color.hashCode ^
      icon.hashCode ^
      prefix.hashCode ^
      kind.hashCode;

  @override
  String toString() => 'TagData(slug: $slug, label: $label, kind: $kind)';
}
