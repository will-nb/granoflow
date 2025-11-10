import '../../database/database_adapter.dart';
import '../../models/tag.dart';
import '../tag_repository.dart';

class ObjectBoxTagRepository implements TagRepository {
  const ObjectBoxTagRepository(this._adapter);

  // ignore: unused_field
  final DatabaseAdapter _adapter;

  @override
  Future<void> clearAll() {
    throw UnimplementedError('ObjectBoxTagRepository.clearAll');
  }

  @override
  Future<Tag?> findBySlug(String slug) {
    throw UnimplementedError('ObjectBoxTagRepository.findBySlug');
  }

  @override
  Future<void> initializeTags() async {
    // 预留接口：后续实现将使用 ObjectBox 存储标签定义
    throw UnimplementedError('ObjectBoxTagRepository.initializeTags');
  }

  @override
  Future<List<Tag>> listByKind(TagKind kind) {
    throw UnimplementedError('ObjectBoxTagRepository.listByKind');
  }
}
