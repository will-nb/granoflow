import 'package:flutter/foundation.dart';

import '../../data/repositories/seed_repository.dart';
import 'node_service.dart';
import 'seed_import_utils.dart';

/// 种子节点应用器
/// 负责将种子数据中的节点导入到任务中
class SeedNodeApplier {
  SeedNodeApplier({required NodeService nodeService}) : _nodeService = nodeService;

  final NodeService _nodeService;

  /// 为任务导入节点
  Future<void> applyNodesForTask(String taskId, List<SeedNode> nodes, String taskSlug) async {
    debugPrint('SeedNodeApplier: Applying ${nodes.length} nodes for task $taskSlug');

    // 第一遍：创建所有根节点（parentSlug 为 null）
    final Map<String, String> nodeSlugToId = {};
    for (final seedNode in nodes) {
      if (seedNode.parentSlug == null) {
        final node = await _nodeService.createNode(
          taskId: taskId,
          title: seedNode.title,
          parentId: null,
        );
        nodeSlugToId[seedNode.slug] = node.id;
        debugPrint('SeedNodeApplier: Root node created - id: ${node.id}, slug: ${seedNode.slug}');

        // 如果节点状态不是 'pending'，更新状态
        if (seedNode.status != 'pending') {
          final status = SeedImportUtils.parseNodeStatus(seedNode.status);
          if (status != null) {
            await _nodeService.updateNodeStatus(node.id, status);
          }
        }
      }
    }

    // 第二遍：创建所有子节点（parentSlug 不为 null）
    // 需要递归处理，因为可能有多层嵌套
    bool hasMoreNodes = true;
    while (hasMoreNodes) {
      hasMoreNodes = false;
      for (final seedNode in nodes) {
        if (seedNode.parentSlug != null && !nodeSlugToId.containsKey(seedNode.slug)) {
          // 检查父节点是否已创建
          if (nodeSlugToId.containsKey(seedNode.parentSlug)) {
            final parentNodeId = nodeSlugToId[seedNode.parentSlug]!;
            final node = await _nodeService.createNode(
              taskId: taskId,
              title: seedNode.title,
              parentId: parentNodeId,
            );
            nodeSlugToId[seedNode.slug] = node.id;
            debugPrint(
              'SeedNodeApplier: Child node created - id: ${node.id}, slug: ${seedNode.slug}, parent: ${seedNode.parentSlug}',
            );

            // 如果节点状态不是 'pending'，更新状态
            if (seedNode.status != 'pending') {
              final status = SeedImportUtils.parseNodeStatus(seedNode.status);
              if (status != null) {
                await _nodeService.updateNodeStatus(node.id, status);
              }
            }
          } else {
            // 父节点还未创建，下一轮再处理
            hasMoreNodes = true;
          }
        }
      }
    }

    // 检查是否有未创建的节点（可能是循环引用或无效的 parentSlug）
    final createdCount = nodeSlugToId.length;
    if (createdCount < nodes.length) {
      final missingNodes = nodes.where((n) => !nodeSlugToId.containsKey(n.slug)).toList();
      debugPrint(
        'SeedNodeApplier: WARNING - ${missingNodes.length} nodes were not created for task $taskSlug',
      );
      for (final missing in missingNodes) {
        debugPrint(
          'SeedNodeApplier: Missing node - slug: ${missing.slug}, parentSlug: ${missing.parentSlug}',
        );
      }
    }

    debugPrint(
      'SeedNodeApplier: Nodes import complete for task $taskSlug - Created: $createdCount/${nodes.length}',
    );
  }
}
