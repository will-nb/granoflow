import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/task.dart';
import '../../widgets/dismissible_task_tile.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/swipe_action_handler.dart';
import '../../widgets/swipe_action_type.dart';
import '../../widgets/swipe_configs.dart';
import '../utils/tag_utils.dart';
import '../utils/tree_flattening_utils.dart';
import '../widgets/task_hierarchy_list.dart';
import '../widgets/task_header_row.dart';

class QuickTaskCard extends ConsumerWidget {
  const QuickTaskCard({
    super.key,
    required this.task,
  });

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(taskTreeProvider(task.id));
    final theme = Theme.of(context);
    final executionLeading = buildExecutionLeading(context, task);

    return DismissibleTaskTile(
      task: task,
      config: SwipeConfigs.tasksConfig,
      onLeftAction: (task) => SwipeActionHandler.handleAction(
        context,
        ref,
        SwipeActionType.postpone,
        task,
      ),
      onRightAction: (task) => SwipeActionHandler.handleAction(
        context,
        ref,
        SwipeActionType.archive,
        task,
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TaskHeaderRow(
                task: task,
                showConvertAction: true,
                leading: executionLeading,
                useBodyText: true,
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
      ),
    );
  }
}
