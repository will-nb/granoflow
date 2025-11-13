import 'package:flutter/material.dart';
import '../../data/models/node.dart';
import '../../generated/l10n/app_localizations.dart';
import 'tri_state_checkbox.dart';

/// 可滑动的节点瓦片组件
class DismissibleNodeTile extends StatelessWidget {
  const DismissibleNodeTile({
    super.key,
    required this.node,
    required this.depth,
    required this.onTap,
    required this.onAddChild,
    required this.onReorder,
    required this.onStatusChange,
  });

  final Node node;
  final int depth;
  final VoidCallback onTap;
  final VoidCallback onAddChild;
  final Function(int, int) onReorder;
  final ValueChanged<NodeStatus>? onStatusChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDeleted = node.status == NodeStatus.deleted;
    final isFinished = node.status == NodeStatus.finished;

    return Dismissible(
      key: Key('node_${node.id}'),
      direction: DismissDirection.horizontal,
      // 右侧背景：在 LTR 下"右滑"（startToEnd）时显示，用于完成操作
      background: _buildRightBackground(context, theme, l10n),
      // 左侧背景：在 LTR 下"左滑"（endToStart）时显示，用于删除操作
      secondaryBackground: _buildLeftBackground(context, theme, l10n),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // 右滑：完成
          onStatusChange?.call(NodeStatus.finished);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          // 左滑：删除
          onStatusChange?.call(NodeStatus.deleted);
          return false;
        }
        return false;
      },
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(
            left: depth * 24.0 + 16.0,
            right: 16.0,
            top: 8.0,
            bottom: 8.0,
          ),
          child: Row(
            children: [
              // 拖拽手柄
              const Icon(Icons.drag_indicator_rounded, size: 20),
              const SizedBox(width: 8),
              // 三态复选框
              TriStateCheckbox(
                value: _nodeStatusToTriState(node.status),
                onChanged: (newState) {
                  onStatusChange?.call(_triStateToNodeStatus(newState));
                },
              ),
              const SizedBox(width: 12),
              // 节点标题
              Expanded(
                child: Text(
                  node.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    decoration: isDeleted || isFinished
                        ? TextDecoration.lineThrough
                        : null,
                    color: isDeleted
                        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                        : null,
                  ),
                ),
              ),
              // 添加子节点按钮
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: onAddChild,
                tooltip: l10n.nodeAddButton,
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildRightBackground(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return Container(
      color: theme.colorScheme.primary,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 16),
      child: Icon(
        Icons.check,
        color: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildLeftBackground(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return Container(
      color: theme.colorScheme.error,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 16),
      child: Icon(
        Icons.delete,
        color: theme.colorScheme.onError,
      ),
    );
  }
}

