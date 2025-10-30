import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../widgets/dismissible_task_tile.dart';
import '../../widgets/swipe_action_handler.dart';
import '../../widgets/swipe_action_type.dart';
import '../../widgets/swipe_configs.dart';
import '../utils/tag_utils.dart';
import '../utils/tree_flattening_utils.dart';
import '../widgets/description_block.dart';
import '../widgets/empty_placeholder.dart';
import '../widgets/error_banner.dart';
import '../widgets/task_hierarchy_list.dart';
import '../widgets/task_header_row.dart';

class QuickTasksCollapsibleSection extends ConsumerWidget {
  const QuickTasksCollapsibleSection({
    super.key,
    required this.asyncTasks,
  });

  final AsyncValue<List<Task>> asyncTasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(quickTasksExpandedProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            final notifier = ref.read(quickTasksExpandedProvider.notifier);
            notifier.state = !isExpanded;
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: asyncTasks.when(
              data: (tasks) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QuickTasksHeaderRow(
                      isExpanded: isExpanded,
                      taskCount: tasks.length,
                    ),
                    if (isExpanded && tasks.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: QuickTasksList(tasks: tasks),
                      ),
                    if (isExpanded && tasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: EmptyPlaceholder(
                          message: l10n.projectQuickTasksEmpty,
                        ),
                      ),
                  ],
                );
              },
              loading: () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  QuickTasksHeaderRow(isExpanded: isExpanded, taskCount: 0),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(
                        color: theme.colorScheme.primary,
                        minHeight: 2,
                      ),
                    ),
                ],
              ),
              error: (error, stackTrace) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  QuickTasksHeaderRow(isExpanded: isExpanded, taskCount: 0),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ErrorBanner(message: '$error'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuickTasksHeaderRow extends StatelessWidget {
  const QuickTasksHeaderRow({
    super.key,
    required this.isExpanded,
    required this.taskCount,
  });

  final bool isExpanded;
  final int taskCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.projectQuickTasksTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.projectQuickTasksSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
        if (!isExpanded && taskCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '$taskCount ${l10n.projectQuickTasksTitle}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class QuickTasksList extends StatelessWidget {
  const QuickTasksList({
    super.key,
    required this.tasks,
  });

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tasks
          .map((task) => QuickTaskItem(task: task))
          .toList(growable: false),
    );
  }
}

class QuickTaskItem extends ConsumerWidget {
  const QuickTaskItem({
    super.key,
    required this.task,
  });

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(taskTreeProvider(task.id));
    final theme = Theme.of(context);

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
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TaskHeaderRow(
                task: task,
                showConvertAction: true,
                leading: buildExecutionLeading(context, task),
              ),
              if (task.description != null && task.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: DescriptionBlock(description: task.description!),
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
