import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/node.dart';
import 'repository_providers.dart';

/// 监听任务的所有节点
///
/// [taskId] 任务 ID
/// 返回 StreamProvider，按 sortIndex 排序
final taskNodesProvider = StreamProvider.family<List<Node>, String>((ref, taskId) async* {
  final nodeRepository = await ref.read(nodeRepositoryProvider.future);
  yield* nodeRepository.watchNodesByTaskId(taskId);
});

/// 构建节点树结构
///
/// [taskId] 任务 ID
/// 返回 Provider，构建 Map<parentId, List<Node>> 结构
/// parentId 为 null 表示根节点
final taskNodesTreeProvider = Provider.family<Map<String?, List<Node>>, String>((ref, taskId) {
  final nodesAsync = ref.watch(taskNodesProvider(taskId));
  
  return nodesAsync.when(
    data: (nodes) {
      final tree = <String?, List<Node>>{};
      
      // 按 parentId 分组
      for (final node in nodes) {
        tree.putIfAbsent(node.parentId, () => []).add(node);
      }
      
      // 对每个父节点的子节点列表按 sortIndex 排序
      for (final children in tree.values) {
        children.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
      }
      
      return tree;
    },
    loading: () => <String?, List<Node>>{},
    error: (_, __) => <String?, List<Node>>{},
  );
});

