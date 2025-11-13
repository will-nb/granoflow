import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/node.dart';
import '../../data/models/task.dart';
import '../../core/providers/node_providers.dart';
import '../../core/providers/service_providers.dart';
import 'tri_state_checkbox.dart';
import 'utils/node_editor_helper.dart';

/// 任务节点列表组件（支持交互）
/// 
/// 用于在任务展开内容中显示节点，支持状态切换和编辑
class TaskNodesListReadonly extends ConsumerStatefulWidget {
  const TaskNodesListReadonly({
    super.key,
    required this.task,
  });

  final Task task;

  @override
  ConsumerState<TaskNodesListReadonly> createState() => _TaskNodesListReadonlyState();
}

class _TaskNodesListReadonlyState extends ConsumerState<TaskNodesListReadonly> {

  @override
  Widget build(BuildContext context) {
    final nodesAsync = ref.watch(taskNodesProvider(widget.task.id));

    return nodesAsync.when(
      data: (nodes) {
        // 显示所有节点（包括已删除和已完成的）
        final visibleNodes = nodes.where((n) => n.status != NodeStatus.deleted || true).toList();
        
        if (visibleNodes.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: _buildNodesTree(context, visibleNodes),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildNodesTree(BuildContext context, List<Node> nodes) {
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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDeleted = node.status == NodeStatus.deleted;
    final isFinished = node.status == NodeStatus.finished;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 节点瓦片（可交互）
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await NodeEditorHelper.showNodeEditor(
                context,
                ref,
                taskId: widget.task.id,
                nodeId: node.id,
                initialTitle: node.title,
              );
            },
            child: Padding(
              padding: EdgeInsets.only(
                left: depth * 24.0 + 16.0,
                right: 16.0,
                top: 6.0,
                bottom: 6.0,
              ),
              child: Row(
                children: [
                  // 三态复选框（可交互）
                  TriStateCheckbox(
                    value: _nodeStatusToTriState(node.status),
                    onChanged: (newState) {
                      final newStatus = _triStateToNodeStatus(newState);
                      _updateNodeStatus(node.id, newStatus);
                    },
                  ),
                  const SizedBox(width: 12),
                  // 节点标题（可点击编辑）
                  Expanded(
                    child: Text(
                      node.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        decoration: isDeleted || isFinished
                            ? TextDecoration.lineThrough
                            : null,
                        color: isDeleted
                            ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                            : colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 子节点
        if (children.isNotEmpty)
          ...children.map((child) => _buildNodeItem(context, child, allNodes, depth + 1)),
      ],
    );
  }

  TriState _nodeStatusToTriState(NodeStatus status) {
    return switch (status) {
      NodeStatus.pending => TriState.pending,
      NodeStatus.finished => TriState.finished,
      NodeStatus.deleted => TriState.deleted,
    };
  }

  NodeStatus _triStateToNodeStatus(TriState state) {
    return switch (state) {
      TriState.pending => NodeStatus.pending,
      TriState.finished => NodeStatus.finished,
      TriState.deleted => NodeStatus.deleted,
    };
  }

  Future<void> _updateNodeStatus(String nodeId, NodeStatus status) async {
    try {
      final nodeService = await ref.read(nodeServiceProvider.future);
      
      // 获取当前节点状态
      final nodes = await ref.read(taskNodesProvider(widget.task.id).future);
      final currentNode = nodes.firstWhere((n) => n.id == nodeId);
      final currentStatus = currentNode.status;
      
      // 根据新状态和当前状态决定调用哪个方法
      if (status == NodeStatus.deleted) {
        // 删除节点时，所有子节点也会一起删除
        await nodeService.deleteNode(nodeId);
      } else if (status == NodeStatus.finished) {
        // 完成节点时，所有子节点也会一起完成
        await nodeService.updateNodeStatusWithChildren(nodeId, status);
      } else if (status == NodeStatus.pending && currentStatus == NodeStatus.deleted) {
        // 如果当前是 deleted 状态，且新状态是 pending，则还原节点
        await nodeService.restoreNode(nodeId);
      } else {
        // 其他情况（如 pending -> pending，或 finished -> pending）使用普通更新
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

