import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../utils/tree_flattening_utils.dart';
import '../utils/list_comparison_utils.dart' as task_list_utils;
import '../widgets/task_header_row.dart';

class ProjectTreeView extends ConsumerWidget {
  const ProjectTreeView({
    super.key,
    required this.tree,
    required this.section,
    this.padding,
  });

  final TaskTreeNode tree;
  final TaskSection section;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expansionState = ref.watch(expandedRootTaskIdProvider);
    final expanded = expansionState == tree.task.id;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: ExpansionPanelList.radio(
        elevation: 0,
        expandedHeaderPadding: EdgeInsets.zero,
        initialOpenPanelValue: expanded ? tree.task.id : null,
        expansionCallback: (panelIndex, isExpanded) {
          ref.read(expandedRootTaskIdProvider.notifier).state =
              isExpanded ? null : tree.task.id;
        },
        children: [
          ExpansionPanelRadio(
            value: tree.task.id,
            canTapOnHeader: true,
            headerBuilder: (context, isExpanded) {
              return ProjectNodeHeader(task: tree.task, section: section);
            },
            body: ProjectChildrenEditor(
              nodes: tree.children,
              parentTask: tree.task,
            ),
          ),
        ],
      ),
    );
  }
}

class ProjectNodeHeader extends ConsumerWidget {
  const ProjectNodeHeader({
    super.key,
    required this.task,
    required this.section,
  });

  final Task task;
  final TaskSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(right: 8),
      title: Text(task.title, style: theme.textTheme.titleMedium),
        subtitle: Text('ID: ${task.id}'),
      trailing: Wrap(
        spacing: 8,
        children: [
          IconButton(
            tooltip: l10n.actionAddSubtask,
            icon: const Icon(Icons.subdirectory_arrow_right),
            onPressed: () => _showAddSubtaskDialog(context, ref, task.id),
          ),
          IconButton(
            tooltip: l10n.taskListRenameDialogTitle,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showRenameDialog(context, ref, task),
          ),
          IconButton(
            tooltip: l10n.actionArchive,
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => _archiveTask(context, ref, task.id),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSubtaskDialog(
    BuildContext context,
      WidgetRef ref,
      String parentId,
    ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.actionAddSubtask),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: InputDecoration(hintText: l10n.taskTitleHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.of(dialogContext).pop(value);
              }
            },
            child: Text(l10n.commonAdd),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) {
      return;
    }

    final notifier = ref.read(taskEditActionsNotifierProvider.notifier);
    try {
      await notifier.addSubtask(parentId: parentId, title: result);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.taskListSubtaskCreatedToast)),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to create subtask: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.taskListSubtaskError)),
      );
    }
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: task.title);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.taskListRenameDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: InputDecoration(hintText: l10n.taskTitleHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.of(dialogContext).pop(value);
              }
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );

    if (result == null || result == task.title) {
      return;
    }

    final taskService = ref.read(taskServiceProvider);
    await taskService.updateDetails(
      taskId: task.id,
      payload: TaskUpdate(title: result),
    );
  }

  Future<void> _archiveTask(
    BuildContext context,
    WidgetRef ref,
    String taskId,
  ) async {
    final notifier = ref.read(taskEditActionsNotifierProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await notifier.archive(taskId);
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.taskListTaskArchivedToast)),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to archive task: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.taskListTaskArchivedError)),
      );
    }
  }
}

class ProjectChildrenEditor extends ConsumerStatefulWidget {
  const ProjectChildrenEditor({
    super.key,
    required this.nodes,
    required this.parentTask,
  });

  final List<TaskTreeNode> nodes;
  final Task parentTask;

  @override
  ConsumerState<ProjectChildrenEditor> createState() => _ProjectChildrenEditorState();
}

class _ProjectChildrenEditorState extends ConsumerState<ProjectChildrenEditor> {
  late List<TaskTreeNode> _nodes;

  @override
  void initState() {
    super.initState();
    _nodes = List<TaskTreeNode>.from(widget.nodes);
  }

  @override
  void didUpdateWidget(covariant ProjectChildrenEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!task_list_utils.treeEquals(oldWidget.nodes, widget.nodes)) {
      _nodes = List<TaskTreeNode>.from(widget.nodes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    if (_nodes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          l10n.projectSheetMilestonesEmpty,
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    final flattenedNodes = <FlattenedTaskNode>[];
    for (final node in _nodes) {
      flattenedNodes.addAll(flattenTree(node));
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: flattenedNodes.length,
      onReorder: (oldIndex, newIndex) => _handleReorder(oldIndex, newIndex),
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final node = flattenedNodes[index];
        return ReorderableDragStartListener(
          key: ValueKey('project-node-${node.task.id}-${node.task.sortIndex}'),
          index: index,
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: TaskHeaderRow(task: node.task, useBodyText: true),
              subtitle: Text('ID: ${node.task.id}'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) {
      return;
    }

    setState(() {
      final node = _nodes.removeAt(oldIndex);
      final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      _nodes.insert(targetIndex, node);
    });

    final targetNode = _nodes[newIndex > oldIndex ? newIndex - 1 : newIndex].task;
    final taskService = ref.read(taskServiceProvider);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await taskService.updateDetails(
        taskId: targetNode.id,
        payload: TaskUpdate(parentId: widget.parentTask.id),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to reorder project nodes: $error\n$stackTrace');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.taskListSortError)),
      );
    }
  }
}
