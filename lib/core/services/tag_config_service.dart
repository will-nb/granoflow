import '../../data/models/tag.dart';

/// 标签配置服务
/// 直接定义标签配置，配合ARB翻译使用
class TagConfigService {
  static TagConfigService? _instance;
  static TagConfigService get instance => _instance ??= TagConfigService._();
  
  TagConfigService._();
  
  List<TagConfig>? _cachedTags;
  
  /// 获取所有标签配置
  Future<List<TagConfig>> getTags() async {
    if (_cachedTags != null) {
      return _cachedTags!;
    }
    
    // 直接定义标签配置，不依赖外部文件
    _cachedTags = [
      // 上下文标签 (Context Tags)
      TagConfig(slug: "@anywhere", kind: TagKind.context, translationKey: "tag_anywhere"),
      TagConfig(slug: "@home", kind: TagKind.context, translationKey: "tag_home"),
      TagConfig(slug: "@workplace", kind: TagKind.context, translationKey: "tag_workplace"),
      TagConfig(slug: "@local", kind: TagKind.context, translationKey: "tag_local"),
      TagConfig(slug: "@travel", kind: TagKind.context, translationKey: "tag_travel"),
      
      // 优先级标签 (Priority Tags)
      TagConfig(slug: "#urgent", kind: TagKind.priority, translationKey: "tag_urgent"),
      TagConfig(slug: "#important", kind: TagKind.priority, translationKey: "tag_important"),
      TagConfig(slug: "#not_urgent", kind: TagKind.priority, translationKey: "tag_not_urgent"),
      TagConfig(slug: "#not_important", kind: TagKind.priority, translationKey: "tag_not_important"),
      
      // 特殊标签 (Special Tags)
      TagConfig(slug: "#waiting", kind: TagKind.special, translationKey: "tag_waiting"),
      TagConfig(slug: "wasted", kind: TagKind.special, translationKey: "tag_wasted"),
    ];
    
    return _cachedTags!;
  }
  
  /// 根据类型获取标签
  Future<List<TagConfig>> getTagsByKind(TagKind kind) async {
    final allTags = await getTags();
    return allTags.where((tag) => tag.kind == kind).toList();
  }
  
  /// 根据slug获取标签配置
  Future<TagConfig?> getTagBySlug(String slug) async {
    final allTags = await getTags();
    try {
      return allTags.firstWhere((tag) => tag.slug == slug);
    } catch (e) {
      return null;
    }
  }
  
  /// 清除缓存
  void clearCache() {
    _cachedTags = null;
  }
}

/// 标签配置数据类
class TagConfig {
  const TagConfig({
    required this.slug,
    required this.kind,
    required this.translationKey,
  });
  
  final String slug;
  final TagKind kind;
  final String translationKey;
  
  @override
  String toString() => 'TagConfig(slug: $slug, kind: $kind, key: $translationKey)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagConfig &&
          runtimeType == other.runtimeType &&
          slug == other.slug &&
          kind == other.kind &&
          translationKey == other.translationKey;
  
  @override
  int get hashCode => slug.hashCode ^ kind.hashCode ^ translationKey.hashCode;
}

// 移除TagKind枚举，使用data/models/tag.dart中的定义
