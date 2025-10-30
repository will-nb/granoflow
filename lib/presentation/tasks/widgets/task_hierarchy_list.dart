import 'package:flutter/material.dart';
import 'package:granoflow/presentation/tasks/utils/tree_flattening_utils.dart';
import 'package:granoflow/presentation/tasks/widgets/depth_bars.dart';
import 'package:granoflow/presentation/widgets/task_row_content.dart';

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
            child: TaskRowContent(
              task: task,
              compact: true,
              useBodyText: true,
            ),
          ),
        ],
      ),
    );
  }
}

