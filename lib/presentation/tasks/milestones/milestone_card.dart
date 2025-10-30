import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/task.dart';
import '../utils/tree_flattening_utils.dart';
import '../widgets/description_block.dart';
import '../widgets/error_banner.dart';
import '../widgets/task_hierarchy_list.dart';
import '../widgets/task_header_row.dart';

class MilestoneCard extends ConsumerWidget {
  const MilestoneCard({
    super.key,
    required this.milestone,
  });

  final Task milestone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final treeAsync = ref.watch(taskTreeProvider(milestone.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaskHeaderRow(task: milestone),
            if (milestone.description != null && milestone.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: DescriptionBlock(description: milestone.description!),
              ),
            treeAsync.when(
              data: (tree) {
                final nodes = flattenTree(tree, includeRoot: false);
                if (nodes.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TaskHierarchyList(nodes: nodes),
                );
              },
              loading: () => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(
                  color: theme.colorScheme.primary,
                  minHeight: 2,
                ),
              ),
              error: (error, stackTrace) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ErrorBanner(message: '$error'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

