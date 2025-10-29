import 'package:flutter/foundation.dart';
import '../../data/models/tag.dart';

/// 应用级常量定义
///
/// 包含标签配置、默认值、限制等应用级别的常量。
/// 这些常量在编译时确定，运行时不可变。
class AppConstants {
  const AppConstants._();

  /// 标签定义
  ///
  /// 注意：
  /// - slug 包含前缀（@ 或 #），这是标签的唯一标识符
  /// - 前缀是业务规则的一部分，用于类型识别和视觉呈现
  /// - @ 表示上下文标签（Context），# 表示优先级标签（Priority）
  /// - slug 在整个系统中保持一致：数据库、种子数据、UI 显示
  /// - translationKey 对应 ARB 文件中的键，ARB 文件中的翻译应包含前缀
  static const List<TagDefinition> tags = [
    // 上下文标签 - @ 前缀
    TagDefinition(
      slug: '@anywhere',
      kind: TagKind.context,
      translationKey: 'tag_anywhere',
    ),
    TagDefinition(
      slug: '@home',
      kind: TagKind.context,
      translationKey: 'tag_home',
    ),
    TagDefinition(
      slug: '@workplace',
      kind: TagKind.context,
      translationKey: 'tag_workplace',
    ),
    TagDefinition(
      slug: '@local',
      kind: TagKind.context,
      translationKey: 'tag_local',
    ),
    TagDefinition(
      slug: '@travel',
      kind: TagKind.context,
      translationKey: 'tag_travel',
    ),

    // 紧急程度标签 - # 前缀
    TagDefinition(
      slug: '#urgent',
      kind: TagKind.urgency,
      translationKey: 'tag_urgent',
    ),
    TagDefinition(
      slug: '#not_urgent',
      kind: TagKind.urgency,
      translationKey: 'tag_not_urgent',
    ),

    // 重要程度标签 - # 前缀
    TagDefinition(
      slug: '#important',
      kind: TagKind.importance,
      translationKey: 'tag_important',
    ),
    TagDefinition(
      slug: '#not_important',
      kind: TagKind.importance,
      translationKey: 'tag_not_important',
    ),

    // 特殊标签
    TagDefinition(
      slug: 'wasted',
      kind: TagKind.special,
      translationKey: 'tag_wasted',
    ),

    // 执行方式标签 - # 前缀（互斥）
    TagDefinition(
      slug: '#timed',
      kind: TagKind.execution,
      translationKey: 'tag_timed',
    ),
    TagDefinition(
      slug: '#fragmented',
      kind: TagKind.execution,
      translationKey: 'tag_fragmented',
    ),
    TagDefinition(
      slug: '#waiting',
      kind: TagKind.execution,
      translationKey: 'tag_waiting',
    ),
  ];
}

/// 标签定义数据类
///
/// 用于定义标签的基本属性：唯一标识符、类型、翻译键。
@immutable
class TagDefinition {
  const TagDefinition({
    required this.slug,
    required this.kind,
    required this.translationKey,
  });

  /// 标签唯一标识符（包含 @ 或 # 前缀）
  final String slug;

  /// 标签类型（context、urgency、importance、special）
  final TagKind kind;

  /// ARB 文件中的翻译键（如 tag_home）
  final String translationKey;

  @override
  String toString() =>
      'TagDefinition(slug: $slug, kind: $kind, key: $translationKey)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagDefinition &&
          runtimeType == other.runtimeType &&
          slug == other.slug &&
          kind == other.kind &&
          translationKey == other.translationKey;

  @override
  int get hashCode => slug.hashCode ^ kind.hashCode ^ translationKey.hashCode;
}
