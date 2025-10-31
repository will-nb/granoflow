import 'package:flutter/material.dart';

import '../config/app_constants.dart';
import '../theme/ocean_breeze_color_schemes.dart';
import '../../data/models/tag.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../presentation/widgets/tag_data.dart';

/// 统一的标签服务
///
/// 提供标签的查找、规范化、样式获取等统一功能
/// 所有标签信息都从 AppConstants.tags 配置中查找，不依赖前缀推断
class TagService {
  TagService._();

  // 缓存配置映射，避免每次查找都遍历列表
  static final Map<String, TagDefinition> _slugToDefinition = {};
  static bool _initialized = false;

  /// 初始化缓存
  static void _initializeCache() {
    if (_initialized) return;
    for (final definition in AppConstants.tags) {
      _slugToDefinition[definition.slug] = definition;
    }
    _initialized = true;
  }

  /// 规范化 slug（去除前缀，兼容旧数据）
  ///
  /// 如果 slug 以 @ 或 # 开头，自动去除前缀
  /// 例如: '@home' -> 'home', '#urgent' -> 'urgent'
  static String normalizeSlug(String slug) {
    if (slug.startsWith('@') || slug.startsWith('#')) {
      return slug.substring(1);
    }
    return slug;
  }

  /// 通过 slug 查找 TagDefinition（兼容旧格式，自动去除前缀）
  ///
  /// 如果找不到，返回 null
  static TagDefinition? findDefinition(String slug) {
    _initializeCache();
    final normalized = normalizeSlug(slug);
    return _slugToDefinition[normalized];
  }

  /// 获取 TagKind（从配置查找，不依赖前缀推断）
  ///
  /// 如果找不到，返回 TagKind.special
  static TagKind getKind(String slug) {
    final definition = findDefinition(slug);
    return definition?.kind ?? TagKind.special;
  }

  /// 根据类型返回显示前缀
  ///
  /// 前缀已废弃，不再在 UI 中显示（仅通过图标和颜色区分标签类型）
  /// 始终返回 null
  static String? getDisplayPrefix(TagKind kind) {
    return null;
  }

  /// 根据 slug 获取标签的本地化文本
  ///
  /// 使用 AppLocalizations 进行本地化，自动处理前缀
  static String getLocalizedLabel(AppLocalizations l10n, String slug) {
    final definition = findDefinition(slug);
    if (definition == null) {
      // 找不到配置，返回原始 slug（去掉前缀）
      return normalizeSlug(slug);
    }

    // 通过 translationKey 获取翻译
    switch (definition.translationKey) {
      case 'tag_anywhere':
        return l10n.tag_anywhere;
      case 'tag_home':
        return l10n.tag_home;
      case 'tag_company':
        return l10n.tag_company;
      case 'tag_school':
        return l10n.tag_school;
      case 'tag_local':
        return l10n.tag_local;
      case 'tag_travel':
        return l10n.tag_travel;
      case 'tag_urgent':
        return l10n.tag_urgent;
      case 'tag_not_urgent':
        return l10n.tag_not_urgent;
      case 'tag_important':
        return l10n.tag_important;
      case 'tag_not_important':
        return l10n.tag_not_important;
      case 'tag_timed':
        return l10n.tag_timed;
      case 'tag_fragmented':
        return l10n.tag_fragmented;
      case 'tag_waiting':
        return l10n.tag_waiting;
      case 'tag_wasted':
        return l10n.tag_wasted;
      default:
        return normalizeSlug(slug);
    }
  }

  /// 根据 slug 和类型获取标签样式（颜色、图标）
  ///
  /// 返回 (颜色, 图标) 元组
  static (Color, IconData?) getTagStyle(String slug, TagKind kind) {
    final normalized = normalizeSlug(slug);

    // 上下文标签
    if (kind == TagKind.context) {
      switch (normalized) {
        case 'anywhere':
          return (OceanBreezeColorSchemes.lakeCyan, Icons.public);
        case 'home':
          return (OceanBreezeColorSchemes.seaSaltBlue, Icons.home);
        case 'company':
          return (OceanBreezeColorSchemes.warmYellow, Icons.business);
        case 'school':
          return (OceanBreezeColorSchemes.softPink, Icons.school);
        case 'local':
          return (OceanBreezeColorSchemes.lightBlueGray, Icons.location_on);
        case 'travel':
          return (OceanBreezeColorSchemes.lakeCyan, Icons.flight);
        default:
          return (OceanBreezeColorSchemes.lakeCyan, Icons.place_outlined);
      }
    }

    // 紧急程度标签
    if (kind == TagKind.urgency) {
      switch (normalized) {
        case 'urgent':
          return (OceanBreezeColorSchemes.softPink, Icons.priority_high);
        case 'not_urgent':
          return (OceanBreezeColorSchemes.lightBlueGray, Icons.event_available);
        default:
          return (OceanBreezeColorSchemes.seaSaltBlue, Icons.tag);
      }
    }

    // 重要程度标签
    if (kind == TagKind.importance) {
      switch (normalized) {
        case 'important':
          return (OceanBreezeColorSchemes.warmYellow, Icons.star);
        case 'not_important':
          return (OceanBreezeColorSchemes.silverGray, Icons.star_outline);
        default:
          return (OceanBreezeColorSchemes.seaSaltBlue, Icons.tag);
      }
    }

    // 执行方式标签
    if (kind == TagKind.execution) {
      switch (normalized) {
        case 'timed':
          return (OceanBreezeColorSchemes.softPink, Icons.schedule);
        case 'fragmented':
          return (OceanBreezeColorSchemes.lakeCyan, Icons.flash_on_outlined);
        case 'waiting':
          return (OceanBreezeColorSchemes.disabledGray, Icons.hourglass_empty);
        default:
          return (OceanBreezeColorSchemes.seaSaltBlue, Icons.tag);
      }
    }

    // 特殊标签
    if (kind == TagKind.special) {
      switch (normalized) {
        case 'wasted':
          return (OceanBreezeColorSchemes.secondaryText, Icons.delete_outline);
        default:
          return (OceanBreezeColorSchemes.seaSaltBlue, Icons.tag);
      }
    }

    // 默认样式
    return (OceanBreezeColorSchemes.seaSaltBlue, Icons.tag);
  }

  /// 从 slug 创建 TagData（统一的入口）
  ///
  /// 自动规范化 slug，从配置查找类型和样式信息
  static TagData? getTagData(BuildContext context, String slug) {
    final normalized = normalizeSlug(slug);
    final definition = findDefinition(slug);
    
    // 如果找不到定义，返回 null（表示无效标签）
    if (definition == null) {
      return null;
    }

    final l10n = AppLocalizations.of(context);
    final label = getLocalizedLabel(l10n, slug);
    final (color, icon) = getTagStyle(normalized, definition.kind);
    final prefix = getDisplayPrefix(definition.kind);

    return TagData(
      slug: normalized, // 使用规范化后的 slug（无前缀）
      label: label,
      color: color,
      icon: icon,
      prefix: prefix,
      kind: definition.kind,
    );
  }

  /// 检查两个标签是否属于同一组（互斥关系）
  ///
  /// 例如：urgent 和 not_urgent 属于同一组，不能同时存在
  static bool areInSameGroup(String slug1, String slug2) {
    final kind1 = getKind(slug1);
    final kind2 = getKind(slug2);
    
    // 只有相同类型的标签才可能在同一组
    if (kind1 != kind2) return false;
    
    // 同类型的标签都互斥（紧急程度、重要程度、执行方式、上下文）
    return kind1 == TagKind.urgency ||
        kind1 == TagKind.importance ||
        kind1 == TagKind.execution ||
        kind1 == TagKind.context;
  }

  /// 获取指定类型的所有标签 slug 列表
  static List<String> getSlugsByKind(TagKind kind) {
    _initializeCache();
    return AppConstants.tags
        .where((def) => def.kind == kind)
        .map((def) => def.slug)
        .toList(growable: false);
  }
}
