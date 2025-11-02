import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/milestone.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../utils/tree_flattening_utils.dart';
import '../widgets/description_block.dart';
import '../widgets/error_banner.dart';
import '../widgets/task_hierarchy_list.dart';
import '../utils/date_utils.dart';
import '../utils/tag_utils.dart';
import '../widgets/status_chip.dart';

class MilestoneCard extends ConsumerWidget {
  const MilestoneCard({super.key, required this.milestone});

  final Milestone milestone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(milestoneTasksProvider(milestone.milestoneId));

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
            MilestoneHeaderRow(milestone: milestone),
            if (milestone.description != null &&
                milestone.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: DescriptionBlock(description: milestone.description!),
              ),
            tasksAsync.when(
              data: (tasks) {
                final forest = _buildTaskForest(tasks);
                if (forest.isEmpty) {
                  return const SizedBox.shrink();
                }
                final flattened = <FlattenedTaskNode>[];
                for (final node in forest) {
                  flattened.addAll(flattenTree(node));
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TaskHierarchyList(nodes: flattened),
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

  List<TaskTreeNode> _buildTaskForest(List<Task> tasks) {
    if (tasks.isEmpty) {
      return const <TaskTreeNode>[];
    }

    tasks.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    final byParent = <int?, List<Task>>{};
    final taskIds = tasks.map((task) => task.id).toSet();
    for (final task in tasks) {
      final parentKey = task.parentTaskId ?? task.parentId;
      byParent.putIfAbsent(parentKey, () => <Task>[]).add(task);
    }

    TaskTreeNode buildNode(Task task) {
      final children = byParent[task.id] ?? const <Task>[];
      return TaskTreeNode(
        task: task,
        children: children.map(buildNode).toList(growable: false),
      );
    }

    final roots = <Task>[];
    for (final task in tasks) {
      final parentKey = task.parentTaskId ?? task.parentId;
      if (parentKey == null || !taskIds.contains(parentKey)) {
        roots.add(task);
      }
    }

    return roots.map(buildNode).toList(growable: false);
  }
}

class MilestoneHeaderRow extends StatelessWidget {
  const MilestoneHeaderRow({super.key, required this.milestone});

  final Milestone milestone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final deadlineLabel = formatDeadline(context, milestone.dueAt);
    final tagChips = milestone.tags
        .map((slug) => buildModernTag(context, slug))
        .whereType<Widget>()
        .toList(growable: false);
    final overdue =
        milestone.dueAt != null && milestone.dueAt!.isBefore(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(milestone.title, style: theme.textTheme.titleMedium),
        if (deadlineLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${l10n.projectDeadlineLabel} $deadlineLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
        if (tagChips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(spacing: 8, runSpacing: 6, children: tagChips),
          ),
        if (overdue)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: StatusChip(
              label: l10n.projectStatusOverdue,
              color: theme.colorScheme.error,
            ),
          ),
      ],
    );
  }
}
