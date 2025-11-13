import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/node.dart';
import '../../data/models/task.dart';
import '../../core/providers/node_providers.dart';
import '../../core/providers/service_providers.dart';
import '../widgets/utils/node_editor_helper.dart';
import 'dismissible_node_tile.dart';

/// 任务节点列表组件
class TaskNodesList extends ConsumerStatefulWidget {
  const TaskNodesList({
    super.key,
    required this.task,
  });

  final Task task;

  @override
  ConsumerState<TaskNodesList> createState() => _TaskNodesListState();
}

class _TaskNodesListState extends ConsumerState<TaskNodesList> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final nodesAsync = ref.watch(taskNodesProvider(widget.task.id));

    return nodesAsync.when(
      data: (nodes) {
        // 过滤掉已删除的节点（根据设计，已删除的节点应该显示，但这里先显示所有节点）
        final visibleNodes = nodes.where((n) => n.status != NodeStatus.deleted || true).toList();
        
        // 如果节点列表为空，显示空状态
        if (visibleNodes.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 折叠/展开按钮（如果有子节点）
            if (_hasChildren(visibleNodes))
              _buildCollapseButton(context),
            // 分隔线
            if (visibleNodes.isNotEmpty)
              const Divider(height: 24),
            // 节点树
            if (!_isCollapsed)
              _buildNodesTree(context, visibleNodes),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCollapseButton(BuildContext context) {
    return IconButton(
      icon: Icon(_isCollapsed ? Icons.expand_more : Icons.expand_less),
      onPressed: () {
        setState(() {
          _isCollapsed = !_isCollapsed;
        });
      },
    );
  }

  bool _hasChildren(List<Node> nodes) {
    return nodes.any((n) => n.parentId != null);
  }

  Widget _buildNodesTree(BuildContext context, List<Node> nodes) {
    // 构建根节点列表
    final rootNodes = nodes.where((n) => n.parentId == null).toList();
    rootNodes.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    if (rootNodes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: rootNodes.map((node) => _buildNodeItem(context, node, nodes, 0)).toList(),
    );
  }

  Widget _buildNodeItem(BuildContext context, Node node, List<Node> allNodes, int depth) {
    final children = allNodes.where((n) => n.parentId == node.id).toList();
    children.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 节点瓦片
        DismissibleNodeTile(
          node: node,
          depth: depth,
          onTap: () async {
            await NodeEditorHelper.showNodeEditor(
              context,
              ref,
              taskId: widget.task.id,
              nodeId: node.id,
              initialTitle: node.title,
            );
          },
          onAddChild: () async {
            await NodeEditorHelper.showNodeEditor(
              context,
              ref,
              taskId: widget.task.id,
              parentId: node.id,
            );
          },
          onStatusChange: (status) => _updateNodeStatus(node.id, status),
        ),
        // 子节点
        if (children.isNotEmpty)
          ...children.map((child) => _buildNodeItem(context, child, allNodes, depth + 1)),
      ],
    );
  }


  Future<void> _updateNodeStatus(String nodeId, NodeStatus status) async {
    try {
      final nodeService = await ref.read(nodeServiceProvider.future);
      if (status == NodeStatus.deleted) {
        await nodeService.deleteNode(nodeId);
      } else {
        await nodeService.updateNodeStatus(nodeId, status);
      }
      // 刷新节点列表
      ref.invalidate(taskNodesProvider(widget.task.id));
    } catch (e) {
      // 错误处理
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update node: $e')),
        );
      }
    }
  }
}

