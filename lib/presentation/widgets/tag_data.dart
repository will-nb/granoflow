import 'package:flutter/material.dart';

import '../../core/theme/ocean_breeze_color_schemes.dart';
import '../../data/models/tag.dart';

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

  /// 标签唯一标识（如 @home, #urgent）
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
  factory TagData.fromTag(Tag tag, String locale) {
    final label = tag.labelForLocale(locale);
    final (color, icon, prefix) = _getTagStyle(tag.slug, tag.kind);

    return TagData(
      slug: tag.slug,
      label: label,
      color: color,
      icon: icon,
      prefix: prefix,
      kind: tag.kind,
    );
  }

  /// 根据 slug 和 kind 获取标签样式
  ///
  /// 返回 (颜色, 图标, 前缀) 元组
  ///
  /// 注意：prefix 现在返回 null，因为 ARB 翻译文件中已经包含了前缀
  static (Color, IconData?, String?) _getTagStyle(String slug, TagKind kind) {
    // Context tags - 上下文标签（场景）
    if (slug.startsWith('@')) {
      return (
        OceanBreezeColorSchemes.lakeCyan,
        Icons.place_outlined,
        null, // ARB 文件中已包含 @ 前缀
      );
    }

    // Priority tags - 优先级标签
    if (slug.startsWith('#')) {
      switch (slug) {
        case '#urgent':
          return (
            OceanBreezeColorSchemes.softPink,
            Icons.priority_high,
            null, // ARB 文件中已包含 # 前缀
          );
        case '#not_urgent':
          return (
            OceanBreezeColorSchemes.lightBlueGray,
            Icons.schedule,
            null, // ARB 文件中已包含 # 前缀
          );
        case '#important':
          return (
            OceanBreezeColorSchemes.warmYellow,
            Icons.star_outline,
            null, // ARB 文件中已包含 # 前缀
          );
        case '#not_important':
          return (
            OceanBreezeColorSchemes.silverGray,
            Icons.star_border,
            null, // ARB 文件中已包含 # 前缀
          );
        case '#waiting':
          return (
            OceanBreezeColorSchemes.disabledGray,
            Icons.hourglass_empty,
            null, // ARB 文件中已包含 # 前缀
          );
        case '#timed':
          return (OceanBreezeColorSchemes.softPink, Icons.timelapse, null);
        case '#fragmented':
          return (
            OceanBreezeColorSchemes.lakeCyan,
            Icons.flash_on_outlined,
            null,
          );
        default:
          // 未知的优先级标签，使用默认样式
          return (
            OceanBreezeColorSchemes.seaSaltBlue,
            Icons.tag,
            null, // ARB 文件中已包含 # 前缀
          );
      }
    }

    // Special tags - 特殊标签
    if (slug == 'wasted') {
      return (
        OceanBreezeColorSchemes.secondaryText,
        Icons.delete_outline,
        null,
      );
    }

    // Default - 默认样式
    return (OceanBreezeColorSchemes.seaSaltBlue, Icons.tag, null);
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
