import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:granoflow/presentation/tasks/utils/tree_flattening_utils.dart';
import 'package:granoflow/presentation/tasks/widgets/depth_bars.dart';
import 'package:granoflow/presentation/widgets/task_row_content.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';

class TaskHierarchyList extends StatelessWidget {
  const TaskHierarchyList({super.key, required this.nodes});

  final List<FlattenedTaskNode> nodes;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: nodes
          .map((node) => TaskHierarchyTile(node: node))
          .toList(growable: false),
    );
  }
}

class TaskHierarchyTile extends StatelessWidget {
  const TaskHierarchyTile({super.key, required this.node});

  final FlattenedTaskNode node;

  @override
  Widget build(BuildContext context) {
    final task = node.task;
    final theme = Theme.of(context);
    final isTrashed = task.status == TaskStatus.trashed;
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DepthBars(depth: node.depth),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TaskRowContent(
                  task: task,
                  compact: true,
                  useBodyText: true,
                  taskLevel: node.depth + 1, // level = depth + 1
                ),
                // 删除时间（如果是 trashed 状态）
                if (isTrashed)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatDeletedTime(task.updatedAt, l10n, context),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化删除时间（年月日时分，不显示秒）
  String _formatDeletedTime(
    DateTime deletedAt,
    AppLocalizations l10n,
    BuildContext context,
  ) {
    final locale = Localizations.localeOf(context);
    // 格式：年月日 时分（不显示秒）
    // 中文格式：2025年11月3日 14:30
    // 英文格式：Nov 3, 2025 14:30
    final dateFormat = DateFormat.yMMMd(locale.toString()).add_Hm();
    return dateFormat.format(deletedAt);
  }
}

