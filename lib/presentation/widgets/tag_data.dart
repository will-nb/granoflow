import 'package:flutter/material.dart';

import '../../core/theme/ocean_breeze_color_schemes.dart';
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
    // 由于 Tag.localizedLabels 为空，我们需要使用 slug 作为回退
    // 实际的本地化会在 UI 层通过 AppLocalizations 处理
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

  /// 从 Tag 模型转换为 TagData（使用 AppLocalizations 进行本地化）
  ///
  /// 这是推荐的方法，用于在 UI 层获取正确的本地化标签
  factory TagData.fromTagWithLocalization(Tag tag, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = _getLocalizedLabel(l10n, tag.slug);
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

  /// 获取本地化标签文本
  static String _getLocalizedLabel(AppLocalizations l10n, String slug) {
    switch (slug) {
      case '#urgent':
        return l10n.tag_urgent;
      case '#not_urgent':
        return l10n.tag_not_urgent;
      case '#important':
        return l10n.tag_important;
      case '#not_important':
        return l10n.tag_not_important;
      case '#timed':
        return l10n.tag_timed;
      case '#fragmented':
        return l10n.tag_fragmented;
      case '#waiting':
        return l10n.tag_waiting;
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
      default:
        return slug;
    }
  }

  /// 根据 slug 和 kind 获取标签样式
  ///
  /// 返回 (颜色, 图标, 前缀) 元组
  ///
  /// 注意：prefix 现在返回 null，因为 ARB 翻译文件中已经包含了前缀
  static (Color, IconData?, String?) _getTagStyle(String slug, TagKind kind) {
    // Context tags - 上下文标签（场景）
    if (slug.startsWith('@')) {
      switch (slug) {
        case '@anywhere':
          return (
            OceanBreezeColorSchemes.lakeCyan,
            Icons.public,
            null,
          );
        case '@home':
          return (
            OceanBreezeColorSchemes.seaSaltBlue,
            Icons.home,
            null,
          );
        case '@company':
          return (
            OceanBreezeColorSchemes.warmYellow,
            Icons.business,
            null,
          );
        case '@school':
          return (
            OceanBreezeColorSchemes.softPink,
            Icons.school,
            null,
          );
        case '@local':
          return (
            OceanBreezeColorSchemes.lightBlueGray,
            Icons.location_on,
            null,
          );
        case '@travel':
          return (
            OceanBreezeColorSchemes.lakeCyan,
            Icons.flight,
            null,
          );
        default:
          return (
            OceanBreezeColorSchemes.lakeCyan,
            Icons.place_outlined,
            null, // ARB 文件中已包含 @ 前缀
          );
      }
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
            Icons.event_available,
            null, // ARB 文件中已包含 # 前缀
          );
        case '#important':
          return (
            OceanBreezeColorSchemes.warmYellow,
            Icons.star,
            null, // ARB 文件中已包含 # 前缀
          );
        case '#not_important':
          return (
            OceanBreezeColorSchemes.silverGray,
            Icons.star_outline,
            null, // ARB 文件中已包含 # 前缀
          );
        case '#waiting':
          return (
            OceanBreezeColorSchemes.disabledGray,
            Icons.hourglass_empty,
            null, // ARB 文件中已包含 # 前缀
          );
        case '#timed':
          return (OceanBreezeColorSchemes.softPink, Icons.schedule, null);
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
