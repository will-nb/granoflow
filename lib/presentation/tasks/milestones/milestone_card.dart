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
import '../projects/widgets/milestone_edit_sheet.dart';
import '../../../core/providers/service_providers.dart';

class MilestoneCard extends ConsumerWidget {
  const MilestoneCard({super.key, required this.milestone});

  final Milestone milestone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(milestoneTasksProvider(milestone.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onLongPress: () => _showMilestoneMenu(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: MilestoneHeaderRow(milestone: milestone),
                  ),
                  Builder(
                    builder: (menuContext) {
                      final menuL10n = AppLocalizations.of(menuContext);
                      return PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (value) => _handleMenuAction(context, ref, value),
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 20),
                                const SizedBox(width: 12),
                                Text(menuL10n.commonEdit),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline, size: 20),
                                const SizedBox(width: 12),
                                Text(menuL10n.commonDelete),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
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
      ),
    );
  }

  Future<void> _showMilestoneMenu(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2,
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 20),
              const SizedBox(width: 12),
              Text(l10n.commonEdit),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 20),
              const SizedBox(width: 12),
              Text(l10n.commonDelete),
            ],
          ),
        ),
      ],
    );
    if (result != null) {
      _handleMenuAction(context, ref, result);
    }
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    switch (action) {
      case 'edit':
        await _editMilestone(context, ref);
        break;
      case 'delete':
        await _deleteMilestone(context, ref);
        break;
    }
  }

  Future<void> _editMilestone(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => MilestoneEditSheet(
        projectId: milestone.projectId,
        milestone: milestone,
      ),
    );
    if (updated == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.milestoneUpdated)),
      );
    }
  }

  Future<void> _deleteMilestone(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.milestoneDeleteTitle),
        content: Text(l10n.milestoneDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      final milestoneService = await ref.read(milestoneServiceProvider.future);
      await milestoneService.delete(milestone.id);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.milestoneDeleted)),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to delete milestone: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.operationFailed)),
      );
    }
  }

  List<TaskTreeNode> _buildTaskForest(List<Task> tasks) {
    if (tasks.isEmpty) {
      return const <TaskTreeNode>[];
    }

    tasks.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    final byParent = <String?, List<Task>>{};
    final taskIds = tasks.map((task) => task.id).toSet();
    for (final task in tasks) {
      // 层级功能已移除，不再需要 parentKey
      final parentKey = null;
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
      // 层级功能已移除，不再需要 parentKey
      final parentKey = null;
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
