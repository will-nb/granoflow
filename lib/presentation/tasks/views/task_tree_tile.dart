import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../widgets/error_banner.dart';
import '../utils/list_comparison_utils.dart' as task_list_utils;
import '../utils/sort_index_utils.dart';
import 'task_leaf_tile.dart';
import 'task_title.dart';

class TaskTreeTile extends ConsumerWidget {
  const TaskTreeTile({
    super.key,
    required this.section,
    required this.rootTask,
    required this.editMode,
    this.padding,
  });

  final TaskSection section;
  final Task rootTask;
  final bool editMode;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(taskTreeProvider(rootTask.id));
    return treeAsync.when(
      data: (tree) {
        if (editMode) {
          return ProjectTreeView(
            tree: tree,
            section: section,
            padding: padding,
          );
        }
        return TaskTreeView(tree: tree, section: section);
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => ErrorBanner(message: '$error'),
    );
  }
}

class TaskTreeView extends ConsumerWidget {
  const TaskTreeView({super.key, required this.tree, required this.section});

  final TaskTreeNode tree;
  final TaskSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tree.children.isEmpty) {
      return TaskLeafTile(task: tree.task, depth: 0);
    }
    return ExpansionTile(
      key: ValueKey('tasks-${tree.task.id}'),
      title: TaskTitle(task: tree.task, depth: 0, highlight: true),
      tilePadding: const EdgeInsets.only(left: 8, right: 16),
      childrenPadding: const EdgeInsets.only(left: 16, bottom: 8, right: 8),
      children: tree.children
          .map((child) => _TaskTreeBranch(node: child, depth: 1))
          .toList(growable: false),
    );
  }
}

class _TaskTreeBranch extends ConsumerWidget {
  const _TaskTreeBranch({required this.node, required this.depth});

  final TaskTreeNode node;
  final int depth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (node.children.isEmpty) {
      return TaskLeafTile(task: node.task, depth: depth);
    }
    return ExpansionTile(
      key: ValueKey('child-${node.task.id}'),
      title: TaskTitle(task: node.task, depth: depth, highlight: true),
      tilePadding: EdgeInsets.only(left: 8.0 + depth * 12, right: 16),
      childrenPadding: EdgeInsets.only(
        left: 16.0 + depth * 12,
        right: 8,
        bottom: 8,
      ),
      children: node.children
          .map((child) => _TaskTreeBranch(node: child, depth: depth + 1))
          .toList(growable: false),
    );
  }
}

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
  const ProjectNodeHeader({super.key, required this.task, required this.section});

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
      subtitle: Text('ID: ${task.taskId}'),
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
    final l10n = AppLocalizations.of(context);
    if (_nodes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(l10n.taskListNoSubtasks),
      );
    }
    return ReorderableListView.builder(
      key: ValueKey('children-${widget.parentTask.id}'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: _nodes.length,
      onReorder: (oldIndex, newIndex) => _handleReorder(oldIndex, newIndex),
      itemBuilder: (context, index) {
        final node = _nodes[index];
        return ListTile(
          key: ValueKey('child-${node.task.id}-${node.task.sortIndex}'),
          leading: ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle),
          ),
          title: Text(node.task.title),
          subtitle: Text('ID: ${node.task.taskId}'),
          trailing: Wrap(
            spacing: 4,
            children: [
              IconButton(
                tooltip: l10n.actionAddSubtask,
                icon: const Icon(Icons.add),
                onPressed: () =>
                    _showAddSubtaskDialog(context, ref, node.task.id),
              ),
              IconButton(
                tooltip: l10n.taskListRenameDialogTitle,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showRenameDialog(context, ref, node.task),
              ),
              IconButton(
                tooltip: l10n.actionArchive,
                icon: const Icon(Icons.archive_outlined),
                onPressed: () => _archiveTask(context, ref, node.task.id),
              ),
            ],
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

    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final before = targetIndex > 0
        ? _nodes[targetIndex - 1].task.sortIndex
        : null;
    final after = targetIndex < _nodes.length - 1
        ? _nodes[targetIndex + 1].task.sortIndex
        : null;
    final updatedNode = _nodes[targetIndex];
    final newSortIndex = calculateSortIndex(before, after);

    final taskService = ref.read(taskServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await taskService.updateDetails(
        taskId: updatedNode.task.id,
        payload: TaskUpdate(sortIndex: newSortIndex),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to update child sort: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.taskListSortError)));
    }
  }
}

Future<void> _showAddSubtaskDialog(
  BuildContext context,
  WidgetRef ref,
  int parentId,
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
  int taskId,
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

