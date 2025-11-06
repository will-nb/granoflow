import 'package:flutter/foundation.dart';
import '../../data/models/tag.dart';

/// 应用级常量定义
///
/// 包含标签配置、默认值、限制等应用级别的常量。
/// 这些常量在编译时确定，运行时不可变。
class AppConstants {
  const AppConstants._();

  /// 任务完成时默认记录的时间（分钟）
  /// 
  /// 当通过滑动完成一个没有运行时间记录的任务时，会自动记录此默认时间
  static const int defaultTaskCompletionMinutes = 10;

  /// 标签定义
  ///
  /// 注意：
  /// - slug 不包含前缀，是纯标识符（如 'home', 'urgent'）
  /// - 标签类型通过 kind 字段定义，不依赖前缀推断
  /// - 前缀已废弃，不再在 UI 中显示（仅通过图标和颜色区分标签类型）
  /// - slug 在整个系统中保持一致：数据库、种子数据使用无前缀格式
  /// - translationKey 对应 ARB 文件中的键，ARB 文件中的翻译不包含前缀
  static const List<TagDefinition> tags = [
    // 上下文标签
    TagDefinition(
      slug: 'anywhere',
      kind: TagKind.context,
      translationKey: 'tag_anywhere',
    ),
    TagDefinition(
      slug: 'home',
      kind: TagKind.context,
      translationKey: 'tag_home',
    ),
    TagDefinition(
      slug: 'company',
      kind: TagKind.context,
      translationKey: 'tag_company',
    ),
    TagDefinition(
      slug: 'school',
      kind: TagKind.context,
      translationKey: 'tag_school',
    ),
    TagDefinition(
      slug: 'local',
      kind: TagKind.context,
      translationKey: 'tag_local',
    ),
    TagDefinition(
      slug: 'travel',
      kind: TagKind.context,
      translationKey: 'tag_travel',
    ),

    // 紧急程度标签
    TagDefinition(
      slug: 'urgent',
      kind: TagKind.urgency,
      translationKey: 'tag_urgent',
    ),
    TagDefinition(
      slug: 'not_urgent',
      kind: TagKind.urgency,
      translationKey: 'tag_not_urgent',
    ),

    // 重要程度标签
    TagDefinition(
      slug: 'important',
      kind: TagKind.importance,
      translationKey: 'tag_important',
    ),
    TagDefinition(
      slug: 'not_important',
      kind: TagKind.importance,
      translationKey: 'tag_not_important',
    ),

    // 特殊标签
    TagDefinition(
      slug: 'wasted',
      kind: TagKind.special,
      translationKey: 'tag_wasted',
    ),

    // 执行方式标签（互斥）
    TagDefinition(
      slug: 'timed',
      kind: TagKind.execution,
      translationKey: 'tag_timed',
    ),
    TagDefinition(
      slug: 'fragmented',
      kind: TagKind.execution,
      translationKey: 'tag_fragmented',
    ),
    TagDefinition(
      slug: 'waiting',
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

  /// 标签唯一标识符（不包含前缀，纯标识符如 'home', 'urgent'）
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
