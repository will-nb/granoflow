import '../models/tag.dart';

abstract class TagRepository {
  /// 初始化标签数据（从配置文件加载）
  Future<void> initializeTags();

  /// 清空所有标签数据
  Future<void> clearAll();

  Future<List<Tag>> listByKind(TagKind kind);

  Future<Tag?> findBySlug(String slug);
}
