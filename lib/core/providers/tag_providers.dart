import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/tag.dart';
import 'repository_providers.dart';

/// 根据标签类型获取标签列表
final tagsByKindProvider = FutureProvider.family<List<Tag>, TagKind>((ref, kind) async {
  final repo = ref.watch(tagRepositoryProvider);
  return await repo.listByKind(kind);
});

/// 获取所有标签
final allTagsProvider = FutureProvider<List<Tag>>((ref) async {
  final repo = ref.watch(tagRepositoryProvider);
  final allTags = <Tag>[];
  
  for (final kind in TagKind.values) {
    final tags = await repo.listByKind(kind);
    allTags.addAll(tags);
  }
  
  return allTags;
});
