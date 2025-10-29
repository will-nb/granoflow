import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:granoflow/generated/l10n/app_localizations.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../core/services/task_service.dart';
import '../../core/constants/task_constants.dart';
import '../../data/models/task.dart';
import '../widgets/page_app_bar.dart';
import '../widgets/main_drawer.dart';
import '../widgets/gradient_page_scaffold.dart';
import '../widgets/task_expanded_panel.dart';
import '../widgets/dismissible_task_tile.dart';
import '../widgets/swipe_configs.dart';
import '../widgets/swipe_action_handler.dart';
import '../widgets/swipe_action_type.dart';
import 'tasks_drag_handler.dart';
import 'tasks_drag_target.dart';
import 'tasks_drag_target_type.dart';
import '../../core/providers/tasks_drag_provider.dart';

class TaskListPage extends ConsumerStatefulWidget {
  const TaskListPage({super.key});

  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends ConsumerState<TaskListPage> {
  bool _showProjects = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final editActions = ref.watch(taskEditActionsNotifierProvider);
    final bool showLinearProgress = !_showProjects && editActions.isLoading;

    // 动态获取有任务的分组
    final sectionMetas = <_SectionMeta>[
      _SectionMeta(
        section: TaskSection.overdue,
        title: l10n.plannerSectionOverdueTitle,
      ),
      _SectionMeta(
        section: TaskSection.today,
        title: l10n.plannerSectionTodayTitle,
      ),
      _SectionMeta(
        section: TaskSection.tomorrow,
        title: l10n.plannerSectionTomorrowTitle,
      ),
      _SectionMeta(
        section: TaskSection.thisWeek,
        title: l10n.plannerSectionThisWeekTitle,
      ),
      _SectionMeta(
        section: TaskSection.thisMonth,
        title: l10n.plannerSectionThisMonthTitle,
      ),
      _SectionMeta(
        section: TaskSection.later,
        title: l10n.plannerSectionLaterTitle,
      ),
    ];

    return GradientPageScaffold(
      appBar: const PageAppBar(title: 'Tasks'),
      drawer: const MainDrawer(),
      body: Column(
        children: [
          // 模式切换控件
          if (showLinearProgress) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ToggleButtons(
                  isSelected: <bool>[!_showProjects, _showProjects],
                  onPressed: (index) {
                    setState(() {
                      _showProjects = index == 1;
                    });
                  },
                  constraints: const BoxConstraints(
                    minHeight: 36,
                    minWidth: 72,
                  ),
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(l10n.taskListModeTask),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(l10n.taskListModeProject),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _showProjects
                ? const _ProjectsDashboard()
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    children: sectionMetas
                        .map(
                          (meta) => Consumer(
                            builder: (context, ref, child) {
                              final tasksAsync = ref.watch(
                                taskSectionsProvider(meta.section),
                              );
                              return tasksAsync.when(
                                data: (tasks) {
                                  if (tasks.isEmpty)
                                    return const SizedBox.shrink();
                                  return TaskSectionPanel(
                                    key: ValueKey(
                                      '${meta.section}-${_showProjects.toString()}',
                                    ),
                                    section: meta.section,
                                    title: meta.title,
                                    editMode: _showProjects,
                                    onQuickAdd: () =>
                                        _handleQuickAdd(context, meta.section),
                                  );
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleQuickAdd(
    BuildContext context,
    TaskSection section,
  ) async {
    final l10n = AppLocalizations.of(context);
    final result = await showModalBottomSheet<_QuickAddResult>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _QuickAddSheet(section: section),
    );
    if (result == null) {
      return;
    }

    final taskService = ref.read(taskServiceProvider);
    try {
      final newTask = await taskService.captureInboxTask(title: result.title);
      await taskService.planTask(
        taskId: newTask.id,
        dueDateLocal: result.dueDate,
        section: section,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.taskListAddedToast)));
    } catch (error, stackTrace) {
      debugPrint('Failed to add task: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.taskListAddError)));
    }
  }
}

class TaskSectionPanel extends ConsumerWidget {
  const TaskSectionPanel({
    super.key,
    required this.section,
    required this.title,
    required this.editMode,
    required this.onQuickAdd,
  });

  final TaskSection section;
  final String title;
  final bool editMode;
  final VoidCallback onQuickAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskSectionsProvider(section));
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  onPressed: onQuickAdd,
                  icon: const Icon(Icons.add_task_outlined),
                  tooltip: l10n.taskListQuickAddTooltip,
                ),
              ],
            ),
            const SizedBox(height: 12),
            tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return _EmptySectionHint(
                    message: l10n.taskListEmptySectionHint,
                  );
                }
                final roots = _collectRoots(tasks);
                if (roots.isEmpty) {
                  return _EmptySectionHint(
                    message: l10n.taskListEmptySectionHint,
                  );
                }
                if (editMode) {
                  return _TaskSectionProjectModePanel(
                    section: section,
                    roots: roots,
                  );
                }
                return _TaskSectionTaskModeList(section: section, roots: roots);
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => _ErrorBanner(message: '$error'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskSectionTaskModeList extends ConsumerWidget {
  const _TaskSectionTaskModeList({required this.section, required this.roots});

  final TaskSection section;
  final List<Task> roots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widgets = <Widget>[];

    // 添加区域首位拖拽目标
    widgets.add(
      TasksPageDragTarget(
        targetType: TasksDragTargetType.sectionFirst,
        section: section,
      ),
    );

    // 添加任务和任务间的拖拽目标
    for (int i = 0; i < roots.length; i++) {
      final task = roots[i];

      // 添加任务
      widgets.add(
        _TaskTreeTile(
          key: ValueKey('tree-${task.id}'),
          section: section,
          rootTask: task,
          editMode: false,
        ),
      );

      // 如果不是最后一个任务，添加任务间拖拽目标
      if (i < roots.length - 1) {
        widgets.add(
          TasksPageDragTarget(
            targetType: TasksDragTargetType.between,
            beforeTask: task,
            afterTask: roots[i + 1],
          ),
        );
      }
    }

    // 添加区域末位拖拽目标
    widgets.add(
      TasksPageDragTarget(
        targetType: TasksDragTargetType.sectionLast,
        section: section,
      ),
    );

    return Column(children: widgets);
  }
}

class _TaskSectionProjectModePanel extends ConsumerStatefulWidget {
  const _TaskSectionProjectModePanel({
    required this.section,
    required this.roots,
  });

  final TaskSection section;
  final List<Task> roots;

  @override
  ConsumerState<_TaskSectionProjectModePanel> createState() =>
      _TaskSectionProjectModePanelState();
}

class _TaskSectionProjectModePanelState
    extends ConsumerState<_TaskSectionProjectModePanel> {
  late List<Task> _roots;

  @override
  void initState() {
    super.initState();
    _roots = List<Task>.from(widget.roots);
  }

  @override
  void didUpdateWidget(covariant _TaskSectionProjectModePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listEquals(oldWidget.roots, widget.roots)) {
      _roots = List<Task>.from(widget.roots);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _roots.length,
      onReorder: (oldIndex, newIndex) => _handleReorder(oldIndex, newIndex),
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final task = _roots[index];
        return Card(
          key: ValueKey('${task.id}-${task.sortIndex}'),
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.drag_indicator_rounded),
                      ),
                    ),
                    Expanded(
                      child: _ProjectNodeHeader(
                        task: task,
                        section: widget.section,
                      ),
                    ),
                  ],
                ),
                _TaskTreeTile(
                  section: widget.section,
                  rootTask: task,
                  editMode: true,
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 12,
                  ),
                ),
              ],
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
      final task = _roots.removeAt(oldIndex);
      final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      _roots.insert(targetIndex, task);
    });

    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final before = targetIndex > 0 ? _roots[targetIndex - 1].sortIndex : null;
    final after = targetIndex < _roots.length - 1
        ? _roots[targetIndex + 1].sortIndex
        : null;
    final newSortIndex = _calculateSortIndex(before, after);
    final task = _roots[targetIndex];
    final taskService = ref.read(taskServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await taskService.updateDetails(
        taskId: task.id,
        payload: TaskUpdate(sortIndex: newSortIndex),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to update sort order: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.taskListSortError)));
    }
  }
}

class _TaskTreeTile extends ConsumerWidget {
  const _TaskTreeTile({
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
          return _ProjectTreeView(
            tree: tree,
            section: section,
            padding: padding,
          );
        }
        return _TaskTreeView(tree: tree, section: section);
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _ErrorBanner(message: '$error'),
    );
  }
}

class _TaskTreeView extends ConsumerWidget {
  const _TaskTreeView({required this.tree, required this.section});

  final TaskTreeNode tree;
  final TaskSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasChildren = tree.children.isNotEmpty;
    if (!hasChildren) {
      return _TaskLeafTile(
        task: tree.task,
        depth: 0,
        onTap: () => _startFocus(context, ref, tree.task.id),
      );
    }
    return ExpansionTile(
      key: ValueKey('tasks-${tree.task.id}'),
      title: _TaskTitle(task: tree.task, depth: 0, highlight: true),
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
      return _TaskLeafTile(
        task: node.task,
        depth: depth,
        onTap: () => _startFocus(context, ref, node.task.id),
      );
    }
    return ExpansionTile(
      key: ValueKey('child-${node.task.id}'),
      title: _TaskTitle(task: node.task, depth: depth, highlight: true),
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

class _ProjectTreeView extends ConsumerWidget {
  const _ProjectTreeView({
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
          ref.read(expandedRootTaskIdProvider.notifier).state = isExpanded
              ? null
              : tree.task.id;
        },
        children: [
          ExpansionPanelRadio(
            value: tree.task.id,
            canTapOnHeader: true,
            headerBuilder: (context, isExpanded) {
              return _ProjectNodeHeader(task: tree.task, section: section);
            },
            body: _ProjectChildrenEditor(
              nodes: tree.children,
              parentTask: tree.task,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectNodeHeader extends ConsumerWidget {
  const _ProjectNodeHeader({required this.task, required this.section});

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

class _ProjectChildrenEditor extends ConsumerStatefulWidget {
  const _ProjectChildrenEditor({required this.nodes, required this.parentTask});

  final List<TaskTreeNode> nodes;
  final Task parentTask;

  @override
  ConsumerState<_ProjectChildrenEditor> createState() =>
      _ProjectChildrenEditorState();
}

class _ProjectChildrenEditorState
    extends ConsumerState<_ProjectChildrenEditor> {
  late List<TaskTreeNode> _nodes;

  @override
  void initState() {
    super.initState();
    _nodes = List<TaskTreeNode>.from(widget.nodes);
  }

  @override
  void didUpdateWidget(covariant _ProjectChildrenEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_treeEquals(oldWidget.nodes, widget.nodes)) {
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
    final newSortIndex = _calculateSortIndex(before, after);

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

class _TaskLeafTile extends ConsumerStatefulWidget {
  const _TaskLeafTile({
    required this.task,
    required this.depth,
    required this.onTap,
  });

  final Task task;
  final int depth;
  final VoidCallback onTap;

  @override
  ConsumerState<_TaskLeafTile> createState() => _TaskLeafTileState();
}

class _TaskLeafTileState extends ConsumerState<_TaskLeafTile> {
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _updateTaskTitle(BuildContext context, String newTitle) async {
    if (newTitle.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task title cannot be empty')),
      );
      _titleController.text = widget.task.title;
      return;
    }

    if (newTitle.trim() == widget.task.title) {
      return;
    }

    try {
      final taskService = ref.read(taskServiceProvider);
      await taskService.updateDetails(
        taskId: widget.task.id,
        payload: TaskUpdate(title: newTitle.trim()),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update task: $error')),
        );
        _titleController.text = widget.task.title;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expandedId = ref.watch(taskListExpandedTaskIdProvider);
    final isExpanded = expandedId == widget.task.id;
    final isDragging = ref.watch(tasksDragProvider.select((s) => s.isDragging));
    final indentation = widget.depth * 16.0;
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return TasksPageDragHandler(
      task: widget.task,
      enabled: !isExpanded, // 只在闭合时可拖拽
      child: Padding(
        padding: EdgeInsets.only(left: indentation),
        child: DismissibleTaskTile(
          task: widget.task,
          config: SwipeConfigs.tasksConfig,
          direction: isDragging
              ? DismissDirection.none
              : DismissDirection.horizontal,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                // 禁用拖拽时的 hover 效果，因为不支持嵌套子项目
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                enableFeedback: false,
                leading: Icon(
                  Icons.drag_indicator,
                  color: Colors.grey[400],
                  size: 20,
                ),
                title: isExpanded
                    ? TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: colorScheme.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                        onSubmitted: (value) =>
                            _updateTaskTitle(context, value),
                      )
                    : Text(widget.task.title),
                subtitle: Text('ID: ${widget.task.taskId}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_circle_outline),
                      tooltip: l10n.actionStartTimer,
                      onPressed: widget.onTap,
                    ),
                    IconButton(
                      icon: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                      ),
                      onPressed: () {
                        ref
                            .read(taskListExpandedTaskIdProvider.notifier)
                            .state = isExpanded
                            ? null
                            : widget.task.id;
                      },
                    ),
                  ],
                ),
                onTap: () {
                  ref.read(taskListExpandedTaskIdProvider.notifier).state =
                      isExpanded ? null : widget.task.id;
                },
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      TaskExpandedPanel(
                        task: widget.task,
                        localeName: 'en', // TODO: 获取正确的locale
                        showQuickPlan: false,
                        showDateSection: true,
                        showSwipeHint: true,
                        leftActionKey: 'taskArchiveAction',
                        rightActionKey: 'taskPostponeAction',
                        onDateChanged: (date) {
                          if (date != null) {
                            _updateDueDateForTask(
                              context,
                              ref,
                              widget.task.id,
                              date,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateDueDateForTask(
    BuildContext context,
    WidgetRef ref,
    int taskId,
    DateTime dueDate,
  ) async {
    try {
      await ref
          .read(taskServiceProvider)
          .updateDetails(
            taskId: taskId,
            payload: TaskUpdate(dueAt: dueDate),
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Due date updated successfully')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update due date: $error')),
        );
      }
    }
  }
}

class _TaskTitle extends StatelessWidget {
  const _TaskTitle({
    required this.task,
    required this.depth,
    this.highlight = false,
  });

  final Task task;
  final int depth;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = highlight
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)
        : theme.textTheme.bodyLarge;
    return Padding(
      padding: EdgeInsets.only(left: depth * 12),
      child: Text(task.title, style: style),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}

class _EmptySectionHint extends StatelessWidget {
  const _EmptySectionHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _QuickAddSheet extends StatefulWidget {
  const _QuickAddSheet({required this.section});

  final TaskSection section;

  @override
  State<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<_QuickAddSheet> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedDate;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = _defaultDueDate(widget.section);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final viewInsets = mediaQuery.viewInsets.bottom;
    final l10n = AppLocalizations.of(context);
    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatMediumDate(_selectedDate!);
    final sectionLabel = _labelForSection(l10n, widget.section);
    return Padding(
      padding: EdgeInsets.only(
        bottom: viewInsets,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.taskListQuickAddTitle(sectionLabel),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.taskListInputLabel,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(dateLabel),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.commonAdd),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDate ?? now;
    final result = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (result != null) {
      setState(() {
        _selectedDate = result;
      });
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).taskListInputValidation),
        ),
      );
      return;
    }
    setState(() {
      _submitting = true;
    });
    Navigator.of(context).pop(
      _QuickAddResult(
        title: title,
        dueDate: _selectedDate ?? _defaultDueDate(widget.section),
      ),
    );
  }
}

class _QuickAddResult {
  const _QuickAddResult({required this.title, required this.dueDate});

  final String title;
  final DateTime dueDate;
}

class _SectionMeta {
  const _SectionMeta({required this.section, required this.title});

  final TaskSection section;
  final String title;
}

List<Task> _collectRoots(List<Task> tasks) {
  final byId = {for (final task in tasks) task.id: task};
  final roots = <Task>[];
  for (final task in tasks) {
    final parentId = task.parentId;
    if (parentId == null || !byId.containsKey(parentId)) {
      roots.add(task);
    }
  }
  roots.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
  return roots;
}

String _labelForSection(AppLocalizations l10n, TaskSection section) {
  switch (section) {
    case TaskSection.overdue:
      return l10n.plannerSectionOverdueTitle;
    case TaskSection.today:
      return l10n.plannerSectionTodayTitle;
    case TaskSection.tomorrow:
      return l10n.plannerSectionTomorrowTitle;
    case TaskSection.thisWeek:
      return l10n.plannerSectionThisWeekTitle;
    case TaskSection.thisMonth:
      return l10n.plannerSectionThisMonthTitle;
    case TaskSection.later:
      return l10n.plannerSectionLaterTitle;
    case TaskSection.completed:
      return l10n.navCompletedTitle;
    case TaskSection.archived:
      return l10n.navArchivedTitle;
    case TaskSection.trash:
      return l10n.navTrashTitle;
  }
}

DateTime _defaultDueDate(TaskSection section) {
  final now = DateTime.now();
  final base = DateTime(now.year, now.month, now.day);
  switch (section) {
    case TaskSection.overdue:
      return base.subtract(const Duration(days: 1));
    case TaskSection.today:
      return base;
    case TaskSection.tomorrow:
      return base.add(const Duration(days: 1));
    case TaskSection.thisWeek:
      return base.add(const Duration(days: 2));
    case TaskSection.thisMonth:
      return base.add(const Duration(days: 7));
    case TaskSection.later:
      return base.add(const Duration(days: 30));
    case TaskSection.completed:
    case TaskSection.archived:
    case TaskSection.trash:
      return base;
  }
}

double _calculateSortIndex(double? before, double? after) {
  if (before != null && after != null) {
    if ((after - before).abs() > 0.0001) {
      return (before + after) / 2;
    }
    return after + 1;
  }
  if (before == null && after != null) {
    return after - 1000;
  }
  if (after == null && before != null) {
    return before + 1000;
  }
  return TaskConstants.DEFAULT_SORT_INDEX;
}

Future<void> _startFocus(
  BuildContext context,
  WidgetRef ref,
  int taskId,
) async {
  final notifier = ref.read(focusActionsNotifierProvider.notifier);
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    await notifier.start(taskId);
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.taskListFocusStartedToast)),
    );
  } catch (error, stackTrace) {
    debugPrint('Failed to start focus session: $error\n$stackTrace');
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.taskListFocusError)));
  }
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

Future<void> _showAddSubtaskDialog(
  BuildContext context,
  WidgetRef ref,
  int parentId,
) async {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        AppLocalizations.of(dialogContext).taskListAddSubtaskDialogTitle,
      ),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppLocalizations.of(dialogContext).taskListInputValidation;
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: AppLocalizations.of(dialogContext).taskListInputLabel,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(AppLocalizations.of(dialogContext).commonCancel),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() != true) {
              return;
            }
            Navigator.of(dialogContext).pop(controller.text.trim());
          },
          child: Text(AppLocalizations.of(dialogContext).commonAdd),
        ),
      ],
    ),
  );
  if (result == null) {
    return;
  }
  final notifier = ref.read(taskEditActionsNotifierProvider.notifier);
  try {
    await notifier.addSubtask(parentId: parentId, title: result);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).taskListSubtaskCreatedToast),
      ),
    );
  } catch (error, stackTrace) {
    debugPrint('Failed to create subtask: $error\n$stackTrace');
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).taskListSubtaskError),
      ),
    );
  }
}

Future<void> _showRenameDialog(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final controller = TextEditingController(text: task.title);
  final formKey = GlobalKey<FormState>();
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.taskListRenameDialogTitle),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppLocalizations.of(context).taskListInputValidation;
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() != true) {
              return;
            }
            Navigator.of(context).pop(controller.text.trim());
          },
          child: Text(l10n.commonSave),
        ),
      ],
    ),
  );
  if (result == null || result == task.title) {
    return;
  }
  final notifier = ref.read(taskEditActionsNotifierProvider.notifier);
  try {
    await notifier.editTitle(taskId: task.id, title: result);
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.taskListRenameSuccess)));
  } catch (error, stackTrace) {
    debugPrint('Failed to rename task: $error\n$stackTrace');
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.taskListRenameError)));
  }
}

class _ProjectsDashboard extends ConsumerWidget {
  const _ProjectsDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickTasksAsync = ref.watch(quickTasksProvider);
    final projectsAsync = ref.watch(projectsProvider);
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _openCreationSheet(context),
            icon: const Icon(Icons.add_circle_outline),
            label: Text(l10n.projectCreateButton),
          ),
        ),
        const SizedBox(height: 16),
        _SectionHeader(
          title: l10n.projectQuickTasksTitle,
          subtitle: l10n.projectQuickTasksSubtitle,
        ),
        const SizedBox(height: 12),
        _QuickTasksSection(asyncTasks: quickTasksAsync),
        const SizedBox(height: 24),
        _SectionHeader(
          title: l10n.projectListTitle,
          subtitle: l10n.projectListSubtitle,
        ),
        const SizedBox(height: 12),
        projectsAsync.when(
          data: (projects) {
            if (projects.isEmpty) {
              return _EmptyPlaceholder(message: l10n.projectListEmpty);
            }
            return Column(
              children: projects
                  .map((project) => ProjectCard(project: project))
                  .toList(growable: false),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => _ErrorBanner(message: '$error'),
        ),
      ],
    );
  }

  Future<void> _openCreationSheet(BuildContext context) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => const _ProjectCreationSheet(),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).projectCreateSuccess),
        ),
      );
    }
  }
}

class _QuickTasksSection extends ConsumerWidget {
  const _QuickTasksSection({required this.asyncTasks});

  final AsyncValue<List<Task>> asyncTasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return asyncTasks.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return _EmptyPlaceholder(message: l10n.projectQuickTasksEmpty);
        }
        return Column(
          children: tasks
              .map((task) => QuickTaskCard(task: task))
              .toList(growable: false),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _ErrorBanner(message: '$error'),
    );
  }
}

class _ProjectCreationSheet extends ConsumerStatefulWidget {
  const _ProjectCreationSheet();

  @override
  ConsumerState<_ProjectCreationSheet> createState() =>
      _ProjectCreationSheetState();
}

class _ProjectCreationSheetState extends ConsumerState<_ProjectCreationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_MilestoneDraft> _milestones = <_MilestoneDraft>[];
  bool _submitting = false;
  String? _selectedUrgencyTag;
  String? _selectedImportanceTag;
  String? _contextTag;
  DateTime? _projectDeadline;
  String? _executionTag;
  bool _showDescription = false;
  String? _deadlineError;
  bool _suppressProjectShortcut = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onProjectTitleChanged);
    _descriptionController.addListener(_onProjectDescriptionChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onProjectTitleChanged);
    _descriptionController.removeListener(_onProjectDescriptionChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    for (final milestone in _milestones) {
      milestone.dispose();
    }
    super.dispose();
  }

  void _onProjectTitleChanged() {
    _handleShortcutInController(
      _titleController,
      includeExecution: true,
      onHashtagSelected: (slug) {
        setState(() {
          _assignProjectTag(slug);
        });
      },
      onContextSelected: (slug) {
        setState(() {
          _contextTag = slug;
        });
      },
    );
  }

  void _onProjectDescriptionChanged() {
    if (!_showDescription) {
      return;
    }
    _handleShortcutInController(
      _descriptionController,
      includeExecution: true,
      onHashtagSelected: (slug) {
        setState(() {
          _assignProjectTag(slug);
        });
      },
      onContextSelected: (slug) {
        setState(() {
          _contextTag = slug;
        });
      },
    );
  }

  void _handleShortcutInController(
    TextEditingController controller, {
    required bool includeExecution,
    required ValueChanged<String> onHashtagSelected,
    required ValueChanged<String> onContextSelected,
  }) {
    if (_suppressProjectShortcut) {
      return;
    }
    final text = controller.text;
    if (text.isEmpty) {
      return;
    }
    final lastChar = text.codeUnitAt(text.length - 1);
    if (lastChar != 35 && lastChar != 64) {
      // # or @
      return;
    }
    _suppressProjectShortcut = true;
    final trimmed = text.substring(0, text.length - 1);
    controller.value = controller.value.copyWith(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
    _suppressProjectShortcut = false;
    if (lastChar == 35) {
      Future.microtask(() async {
        final slug = await _pickHashtag(includeExecution: includeExecution);
        if (!mounted || slug == null) {
          return;
        }
        onHashtagSelected(slug);
      });
    } else {
      Future.microtask(() async {
        final slug = await _pickContextTag();
        if (!mounted || slug == null) {
          return;
        }
        onContextSelected(slug);
      });
    }
  }

  Future<String?> _pickHashtag({required bool includeExecution}) async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final options = <String>[
      ..._quadrantOptionSlugs,
      if (includeExecution) ..._executionOptionSlugs,
    ];
    return showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                l10n.projectShortcutPickerTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            ...options.map(
              (slug) => ListTile(
                leading: _tagIcon(slug) != null
                    ? Icon(
                        _tagIcon(slug),
                        color: theme.colorScheme.primary,
                      )
                    : null,
                title: Text(_tagLabel(l10n, slug)),
                onTap: () => Navigator.of(sheetContext).pop(slug),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickContextTag() async {
    final options = await ref.read(contextTagOptionsProvider.future);
    if (!mounted || options.isEmpty) {
      return null;
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                l10n.projectContextPickerTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            ...options.map(
              (tag) => ListTile(
                leading: const Icon(Icons.alternate_email),
                title: Text(_tagLabel(l10n, tag.slug)),
                onTap: () => Navigator.of(sheetContext).pop(tag.slug),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _assignProjectTag(String slug) {
    if (_executionOptionSlugs.contains(slug)) {
      _executionTag = slug;
      return;
    }
    if (_urgencyTags.contains(slug)) {
      _selectedUrgencyTag = slug;
      return;
    }
    if (_importanceTags.contains(slug)) {
      _selectedImportanceTag = slug;
    }
  }

  void _attachMilestoneListeners(_MilestoneDraft draft) {
    if (draft.titleListener != null) {
      return;
    }
    draft.titleListener = () => _handleMilestoneTitleChanged(draft);
    draft.titleController.addListener(draft.titleListener!);
  }

  void _handleMilestoneTitleChanged(_MilestoneDraft draft) {
    if (draft.suppressShortcut) {
      return;
    }
    final text = draft.titleController.text;
    if (text.isEmpty) {
      return;
    }
    final lastChar = text.codeUnitAt(text.length - 1);
    if (lastChar != 35 && lastChar != 64) {
      return;
    }
    draft.suppressShortcut = true;
    final trimmed = text.substring(0, text.length - 1);
    draft.titleController.value = draft.titleController.value.copyWith(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
    draft.suppressShortcut = false;
    if (lastChar == 35) {
      Future.microtask(() async {
        final slug = await _pickHashtag(includeExecution: true);
        if (!mounted || slug == null) {
          return;
        }
        setState(() {
          draft.applyTag(slug);
        });
      });
    } else {
      Future.microtask(() async {
        final slug = await _pickContextTag();
        if (!mounted || slug == null) {
          return;
        }
        setState(() {
          draft.contextTag = slug;
        });
      });
    }
  }

  void _ensureProjectDeadlineCoversMilestones({bool showMessage = true}) {
    if (_projectDeadline == null) {
      return;
    }
    DateTime? latest;
    for (final milestone in _milestones) {
      final deadline = milestone.deadline;
      if (deadline == null) {
        continue;
      }
      if (latest == null || deadline.isAfter(latest)) {
        latest = deadline;
      }
    }
    if (latest != null && latest.isAfter(_projectDeadline!)) {
      setState(() {
        _projectDeadline = latest;
        _deadlineError = null;
      });
      if (showMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).projectDeadlineAutoAdjusted,
            ),
          ),
        );
      }
    }
  }

  List<String> _collectProjectTags() {
    final tags = <String>[];
    if (_selectedUrgencyTag != null) {
      tags.add(_selectedUrgencyTag!);
    }
    if (_selectedImportanceTag != null) {
      tags.add(_selectedImportanceTag!);
    }
    if (_executionTag != null) {
      tags.add(_executionTag!);
    }
    if (_contextTag != null) {
      tags.add(_contextTag!);
    }
    return tags;
  }

  List<ProjectMilestoneBlueprint> _collectMilestones() {
    final items = <ProjectMilestoneBlueprint>[];
    for (final draft in _milestones) {
      final title = draft.titleController.text.trim();
      if (title.isEmpty) {
        continue;
      }
      items.add(
        ProjectMilestoneBlueprint(
          title: title,
          dueDate: draft.deadline,
          tags: draft.buildTags(),
          description: draft.descriptionController.text.trim().isEmpty
              ? null
              : draft.descriptionController.text.trim(),
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: bottomInset + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.projectSheetTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                maxLength: 255,
                decoration: InputDecoration(
                  labelText: l10n.taskListInputLabel,
                  hintText: l10n.projectSheetTitleHint,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.taskListInputValidation;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() => _showDescription = !_showDescription);
                },
                icon: Icon(
                  _showDescription ? Icons.expand_less : Icons.notes_outlined,
                ),
                label: Text(
                  _showDescription
                      ? l10n.projectSheetHideDescription
                      : l10n.projectSheetAddDescription,
                ),
              ),
              if (_showDescription)
                TextField(
                  controller: _descriptionController,
                  maxLength: 60000,
                  minLines: 3,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: l10n.projectSheetDescriptionHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                l10n.projectSheetQuadrantLabel,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quadrantOptionSlugs
                    .map(
                      (slug) => ChoiceChip(
                        label: Text(_tagLabel(l10n, slug)),
                        selected: _urgencyTags.contains(slug)
                            ? _selectedUrgencyTag == slug
                            : _selectedImportanceTag == slug,
                        onSelected: (selected) {
                          setState(() {
                            if (_urgencyTags.contains(slug)) {
                              _selectedUrgencyTag = selected ? slug : null;
                            } else {
                              _selectedImportanceTag = selected ? slug : null;
                            }
                          });
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.projectSheetExecutionLabel,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _executionOptionSlugs
                    .map(
                      (slug) => ChoiceChip(
                        label: Text(_tagLabel(l10n, slug)),
                        selected: _executionTag == slug,
                        onSelected: (selected) {
                          setState(() {
                            _executionTag = selected ? slug : null;
                          });
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.projectSheetContextLabel,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (_contextTag != null)
                Wrap(
                  spacing: 8,
                  children: [
                    InputChip(
                      label: Text(_tagLabel(l10n, _contextTag!)),
                      avatar: const Icon(Icons.alternate_email, size: 16),
                      onDeleted: () {
                        setState(() => _contextTag = null);
                      },
                    ),
                  ],
                ),
              TextButton.icon(
                onPressed: () async {
                  final slug = await _pickContextTag();
                  if (!mounted || slug == null) {
                    return;
                  }
                  setState(() {
                    _contextTag = slug;
                  });
                },
                icon: const Icon(Icons.alternate_email),
                label: Text(
                  _contextTag == null
                      ? l10n.projectSheetSelectContext
                      : l10n.projectSheetChangeContext,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _projectDeadline != null
                          ? _formatDeadline(context, _projectDeadline) ?? ''
                          : l10n.projectSheetSelectDeadlineHint,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickProjectDeadline,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(l10n.projectSheetSelectDeadline),
                  ),
                ],
              ),
              if (_deadlineError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _deadlineError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                l10n.projectSheetMilestonesTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (_milestones.isEmpty)
                _EmptyPlaceholder(message: l10n.projectSheetMilestonesEmpty),
              if (_milestones.isNotEmpty)
                Column(
                  children: [
                    for (int index = 0; index < _milestones.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MilestoneDraftTile(
                          draft: _milestones[index],
                          onRemove: () => _removeMilestone(index),
                          onPickDeadline: () => _pickMilestoneDeadline(index),
                          onChanged: () => setState(() {}),
                          onPickContext: () async {
                            final slug = await _pickContextTag();
                            if (!mounted || slug == null) {
                              return;
                            }
                            setState(() {
                              _milestones[index].contextTag = slug;
                            });
                          },
                          onClearContext: () {
                            setState(() {
                              _milestones[index].contextTag = null;
                            });
                          },
                        ),
                      ),
                  ],
                ),
              OutlinedButton.icon(
                onPressed: _addMilestone,
                icon: const Icon(Icons.add),
                label: Text(l10n.projectSheetAddMilestone),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.commonCancel),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.commonSave),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addMilestone() {
    setState(() {
      final draft = _MilestoneDraft();
      _attachMilestoneListeners(draft);
      _milestones.add(draft);
    });
  }

  void _removeMilestone(int index) {
    setState(() {
      final removed = _milestones.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _pickProjectDeadline() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      initialDate: _projectDeadline ?? now,
    );
    if (selected != null) {
      setState(() {
        _projectDeadline = selected;
        _deadlineError = null;
      });
      _ensureProjectDeadlineCoversMilestones();
    }
  }

  Future<void> _pickMilestoneDeadline(int index) async {
    final now = DateTime.now();
    final draft = _milestones[index];
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      initialDate: draft.deadline ?? now,
    );
    if (selected != null) {
      setState(() {
        draft.deadline = selected;
      });
      _ensureProjectDeadlineCoversMilestones();
    }
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    if (_projectDeadline == null) {
      setState(() {
        _deadlineError = l10n.projectSheetDeadlineRequired;
      });
      return;
    }
    _ensureProjectDeadlineCoversMilestones(showMessage: false);
    setState(() => _deadlineError = null);
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }
    final description =
        _showDescription ? _descriptionController.text.trim() : null;
    final sanitizedDescription =
        description != null && description.isNotEmpty ? description : null;

    final blueprint = ProjectBlueprint(
      title: title,
      dueDate: _projectDeadline!,
      description: sanitizedDescription,
      tags: _collectProjectTags(),
      milestones: _collectMilestones(),
    );

    setState(() => _submitting = true);
    try {
      await ref.read(taskServiceProvider).createProject(blueprint);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      debugPrint('Failed to create project: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.projectCreateError)),
      );
      setState(() => _submitting = false);
    }
  }
}

class _MilestoneDraft {
  _MilestoneDraft()
    : titleController = TextEditingController(),
      descriptionController = TextEditingController();

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  DateTime? deadline;
  String? urgencyTag;
  String? importanceTag;
  String? executionTag;
  String? contextTag;
  VoidCallback? titleListener;
  bool suppressShortcut = false;

  void applyTag(String slug) {
    if (_executionTags.contains(slug)) {
      executionTag = slug;
    } else if (_urgencyTags.contains(slug)) {
      urgencyTag = slug;
    } else if (_importanceTags.contains(slug)) {
      importanceTag = slug;
    }
  }

  List<String> buildTags() {
    final tags = <String>[];
    if (urgencyTag != null) {
      tags.add(urgencyTag!);
    }
    if (importanceTag != null) {
      tags.add(importanceTag!);
    }
    if (executionTag != null) {
      tags.add(executionTag!);
    }
    if (contextTag != null) {
      tags.add(contextTag!);
    }
    return tags;
  }

  void dispose() {
    if (titleListener != null) {
      titleController.removeListener(titleListener!);
    }
    titleController.dispose();
    descriptionController.dispose();
  }
}

class _MilestoneDraftTile extends StatelessWidget {
  const _MilestoneDraftTile({
    required this.draft,
    required this.onRemove,
    required this.onPickDeadline,
    required this.onChanged,
    required this.onPickContext,
    required this.onClearContext,
  });

  final _MilestoneDraft draft;
  final VoidCallback onRemove;
  final Future<void> Function() onPickDeadline;
  final VoidCallback onChanged;
  final Future<void> Function() onPickContext;
  final VoidCallback onClearContext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: draft.titleController,
                    maxLength: 255,
                    decoration: InputDecoration(
                      labelText: l10n.taskListInputLabel,
                      hintText: l10n.projectSheetMilestoneTitleHint,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.commonDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    draft.deadline != null
                        ? _formatDeadline(context, draft.deadline) ?? ''
                        : l10n.projectSheetSelectDeadlineHint,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: onPickDeadline,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(l10n.projectSheetSelectDeadline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quadrantOptionSlugs.map((slug) {
                final isUrgency = _urgencyTags.contains(slug);
                final selected = isUrgency
                    ? draft.urgencyTag == slug
                    : draft.importanceTag == slug;
                return ChoiceChip(
                  label: Text(_tagLabel(l10n, slug)),
                  selected: selected,
                  onSelected: (value) {
                    if (isUrgency) {
                      if (value) {
                        draft.urgencyTag = slug;
                      } else if (draft.urgencyTag == slug) {
                        draft.urgencyTag = null;
                      }
                    } else {
                      if (value) {
                        draft.importanceTag = slug;
                      } else if (draft.importanceTag == slug) {
                        draft.importanceTag = null;
                      }
                    }
                    onChanged();
                  },
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _executionOptionSlugs.map((slug) {
                final selected = draft.executionTag == slug;
                return ChoiceChip(
                  label: Text(_tagLabel(l10n, slug)),
                  selected: selected,
                  onSelected: (value) {
                    draft.executionTag = value ? slug : null;
                    onChanged();
                  },
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 12),
            if (draft.contextTag != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InputChip(
                  label: Text(_tagLabel(l10n, draft.contextTag!)),
                  avatar: const Icon(Icons.alternate_email, size: 16),
                  onDeleted: onClearContext,
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onPickContext,
                icon: const Icon(Icons.alternate_email),
                label: Text(
                  draft.contextTag == null
                      ? l10n.projectSheetSelectContext
                      : l10n.projectSheetChangeContext,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: draft.descriptionController,
              maxLength: 60000,
              minLines: 2,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: l10n.projectSheetDescriptionHint,
                hintText: l10n.projectSheetDescriptionHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => onChanged(),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickTaskCard extends ConsumerWidget {
  const QuickTaskCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(taskTreeProvider(task.id));
    final theme = Theme.of(context);
    final executionLeading = _buildExecutionLeading(context, task);

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
              _TaskHeaderRow(
                task: task,
                showConvertAction: true,
                leading: executionLeading,
              ),
              treeAsync.when(
                data: (tree) {
                  final nodes = _flattenTree(tree, includeRoot: false);
                  if (nodes.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _TaskHierarchyList(nodes: nodes),
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
                  child: _ErrorBanner(message: '$error'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProjectCard extends ConsumerWidget {
  const ProjectCard({required this.project});

  final Task project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestonesAsync = ref.watch(projectMilestonesProvider(project.id));
    final expandedId = ref.watch(projectsExpandedTaskIdProvider);
    final isExpanded = expandedId == project.id;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: ValueKey('project-${project.id}'),
        direction: DismissDirection.horizontal,
        background: _projectSwipeBackground(
          color: theme.colorScheme.primary,
          icon: Icons.archive_outlined,
          label: l10n.taskArchiveAction,
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: _projectSwipeBackground(
          color: theme.colorScheme.tertiary,
          icon: Icons.snooze,
          label: l10n.projectSnoozeAction,
          alignment: Alignment.centerRight,
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            final confirmed = await _confirmProjectArchive(context, project);
            if (!confirmed) {
              return false;
            }
            await _archiveTask(context, ref, project.id);
            return true;
          }

          final confirmed = await _confirmProjectSnooze(context, project);
          if (!confirmed) {
            return false;
          }
          await _snoozeProject(context, ref, project);
          return false;
        },
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              final notifier = ref.read(projectsExpandedTaskIdProvider.notifier);
              notifier.state = isExpanded ? null : project.id;
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: milestonesAsync.when(
                data: (milestones) {
                  final total = milestones.length;
                  final completed = milestones
                      .where((m) => m.status == TaskStatus.completedActive)
                      .length;
                  final progress = total == 0 ? 0.0 : completed / total;
                  final overdue =
                      project.dueAt != null &&
                      project.dueAt!.isBefore(DateTime.now());
                  final hasDescription =
                      project.description != null && project.description!.isNotEmpty;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProjectHeaderRow(project: project, isExpanded: isExpanded),
                      if (hasDescription)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: DescriptionBlock(description: project.description!),
                        ),
                      const SizedBox(height: 12),
                      _ProjectProgressBar(
                        progress: progress,
                        completed: completed,
                        total: total,
                        overdue: overdue,
                      ),
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _ProjectDetails(
                            project: project,
                            milestones: milestones,
                          ),
                        ),
                    ],
                  );
                },
                loading: () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProjectHeaderRow(project: project, isExpanded: isExpanded),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      color: theme.colorScheme.primary,
                      minHeight: 2,
                    ),
                  ],
                ),
                error: (error, stackTrace) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProjectHeaderRow(project: project, isExpanded: isExpanded),
                    const SizedBox(height: 12),
                    _ErrorBanner(message: '$error'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectDetails extends ConsumerWidget {
  const _ProjectDetails({required this.project, required this.milestones});

  final Task project;
  final List<Task> milestones;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (milestones.isEmpty) {
      return _EmptyPlaceholder(message: l10n.projectNoMilestonesHint);
    }
    return Column(
      children: milestones
          .map((milestone) => _MilestoneCard(milestone: milestone))
          .toList(growable: false),
    );
  }
}

class _MilestoneCard extends ConsumerWidget {
  const _MilestoneCard({required this.milestone});

  final Task milestone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(taskTreeProvider(milestone.id));
    final theme = Theme.of(context);

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
            _TaskHeaderRow(task: milestone),
            if (milestone.description != null && milestone.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: DescriptionBlock(description: milestone.description!),
              ),
            treeAsync.when(
              data: (tree) {
                final nodes = _flattenTree(tree, includeRoot: false);
                if (nodes.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _TaskHierarchyList(nodes: nodes),
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
                child: _ErrorBanner(message: '$error'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskHierarchyList extends StatelessWidget {
  const _TaskHierarchyList({required this.nodes});

  final List<_FlattenedTaskNode> nodes;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: nodes
          .map((node) => _TaskHierarchyTile(node: node))
          .toList(growable: false),
    );
  }
}

class _TaskHierarchyTile extends StatelessWidget {
  const _TaskHierarchyTile({required this.node});

  final _FlattenedTaskNode node;

  @override
  Widget build(BuildContext context) {
    final task = node.task;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tagChips = _buildTagChips(context, task);
    final deadlineLabel = _formatDeadline(context, task.dueAt);
    final isCompleted = task.status == TaskStatus.completedActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DepthBars(depth: node.depth),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (deadlineLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${l10n.projectDeadlineLabel} $deadlineLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                if (tagChips.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(spacing: 8, runSpacing: 6, children: tagChips),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget? _buildExecutionLeading(BuildContext context, Task task) {
  final slug = task.tags.firstWhere(
    (tag) => _executionTags.contains(tag),
    orElse: () => '',
  );
  if (slug.isEmpty) {
    return null;
  }
  final theme = Theme.of(context);
  final icon = _tagIcon(slug);
  if (icon == null) {
    return null;
  }
  final color = _tagColor(theme, slug);
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: 0.18),
    ),
    padding: const EdgeInsets.all(8),
    child: Icon(icon, color: color, size: 20),
  );
}

class DescriptionBlock extends StatefulWidget {
  const DescriptionBlock({required this.description, this.trim = 255});

  final String description;
  final int trim;

  @override
  State<DescriptionBlock> createState() => _DescriptionBlockState();
}

class _DescriptionBlockState extends State<DescriptionBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final needsTrim = widget.description.length > widget.trim;
    final text = !_expanded && needsTrim
        ? widget.description.substring(0, widget.trim).trimRight() + '…'
        : widget.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: theme.textTheme.bodyMedium,
        ),
        if (needsTrim)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded
                  ? l10n.projectDescriptionShowLess
                  : l10n.projectDescriptionShowMore,
            ),
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(label),
      labelStyle: theme.textTheme.bodySmall?.copyWith(color: color),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.24)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

Widget _projectSwipeBackground({
  required Color color,
  required IconData icon,
  required String label,
  required Alignment alignment,
}) {
  return Container(
    alignment: alignment,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(24),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Future<bool> _confirmProjectArchive(BuildContext context, Task project) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.projectArchiveConfirmTitle),
      content: Text(l10n.projectArchiveConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.taskArchiveAction),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> _confirmProjectSnooze(BuildContext context, Task project) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.projectSnoozeConfirmTitle),
      content: Text(l10n.projectSnoozeConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.projectSnoozeConfirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> _snoozeProject(
  BuildContext context,
  WidgetRef ref,
  Task project,
) async {
  final taskService = ref.read(taskServiceProvider);
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    await taskService.snoozeProject(project.id);
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.projectSnoozeSuccess)),
    );
  } catch (error, stackTrace) {
    debugPrint('Failed to snooze project: $error\n$stackTrace');
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.projectSnoozeError)),
    );
  }
}

class _ProjectHeaderRow extends StatelessWidget {
  const _ProjectHeaderRow({required this.project, required this.isExpanded});

  final Task project;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final deadlineLabel = _formatDeadline(context, project.dueAt);
    final tagChips = _buildTagChips(context, project);
    final overdue = project.dueAt != null && project.dueAt!.isBefore(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(project.title, style: theme.textTheme.titleLarge),
            ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
        if (deadlineLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${l10n.projectDeadlineLabel} $deadlineLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
        if (tagChips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(spacing: 8, runSpacing: 6, children: tagChips),
          ),
        if (overdue)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _StatusChip(
              label: l10n.projectStatusOverdue,
              color: theme.colorScheme.error,
            ),
          ),
      ],
    );
  }
}

class _ProjectProgressBar extends StatelessWidget {
  const _ProjectProgressBar({
    required this.progress,
    required this.completed,
    required this.total,
    required this.overdue,
  });

  final double progress;
  final int completed;
  final int total;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final percentage = (progress * 100).clamp(0, 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: total == 0 ? 0 : progress,
          minHeight: 6,
          backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          valueColor: AlwaysStoppedAnimation<Color>(
            overdue ? theme.colorScheme.error : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          total == 0
              ? l10n.projectProgressEmpty
              : l10n.projectProgressLabel(percentage, completed, total),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TaskHeaderRow extends ConsumerWidget {
  const _TaskHeaderRow({
    required this.task,
    this.showConvertAction = false,
    this.leading,
  });

  final Task task;
  final bool showConvertAction;
  final Widget? leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final tagChips = _buildTagChips(context, task);
    final deadlineLabel = _formatDeadline(context, task.dueAt);
    final overdue = task.dueAt != null && task.dueAt!.isBefore(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null)
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 4),
                child: leading!,
              ),
            Expanded(
              child: Text(task.title, style: theme.textTheme.titleMedium),
            ),
            if (showConvertAction)
              IconButton(
                onPressed: () => _confirmConvert(context, ref),
                tooltip: l10n.projectConvertTooltip,
                icon: Icon(Icons.autorenew, color: theme.colorScheme.primary),
              ),
          ],
        ),
        if (deadlineLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${l10n.projectDeadlineLabel} $deadlineLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
        if (tagChips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(spacing: 8, runSpacing: 6, children: tagChips),
          ),
        if (overdue)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _StatusChip(
              label: l10n.projectStatusOverdue,
              color: theme.colorScheme.error,
            ),
          ),
      ],
    );
  }

  Future<void> _confirmConvert(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.projectConvertDialogTitle),
        content: Text(l10n.projectConvertDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.projectConvertConfirm),
          ),
        ],
      ),
    );
    if (result != true) {
      return;
    }
    try {
      await ref.read(taskServiceProvider).convertToProject(task.id);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.projectConvertSuccess)),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to convert task: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.projectConvertError)),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          message,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _DepthBars extends StatelessWidget {
  const _DepthBars({required this.depth});

  final int depth;

  @override
  Widget build(BuildContext context) {
    if (depth <= 0) {
      return const SizedBox(width: 4, height: 40);
    }
    final bars = List<Widget>.generate(depth, (index) {
      return Container(
        width: 4,
        height: 40,
        margin: EdgeInsets.only(right: index == depth - 1 ? 0 : 4),
        decoration: BoxDecoration(
          color: _depthBarColors[index % _depthBarColors.length],
          borderRadius: BorderRadius.circular(2),
        ),
      );
    });
    return SizedBox(
      width: depth * 8,
      child: Row(mainAxisSize: MainAxisSize.min, children: bars),
    );
  }
}

class _FlattenedTaskNode {
  const _FlattenedTaskNode(this.task, this.depth);

  final Task task;
  final int depth;
}

List<_FlattenedTaskNode> _flattenTree(
  TaskTreeNode node, {
  int depth = 0,
  bool includeRoot = true,
}) {
  final result = <_FlattenedTaskNode>[];
  if (includeRoot) {
    result.add(_FlattenedTaskNode(node.task, depth));
  }
  for (final child in node.children) {
    result.addAll(_flattenTree(child, depth: depth + 1, includeRoot: true));
  }
  return result;
}

String? _formatDeadline(BuildContext context, DateTime? date) {
  if (date == null) return null;
  final locale = AppLocalizations.of(context).localeName;
  final formatter = DateFormat.yMMMd(locale);
  return formatter.format(date);
}

List<Widget> _buildTagChips(BuildContext context, Task task) {
  if (task.tags.isEmpty) {
    return const [];
  }
  return task.tags
      .map((slug) => _buildTagChip(context, slug))
      .whereType<Widget>()
      .toList(growable: false);
}

Widget? _buildTagChip(BuildContext context, String slug) {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  final label = _tagLabel(l10n, slug);
  final color = _tagColor(theme, slug);
  final icon = _tagIcon(slug);

  return Chip(
    label: Text(label),
    avatar: icon != null ? Icon(icon, size: 16, color: color) : null,
    backgroundColor: color.withValues(alpha: 0.12),
    labelStyle: theme.textTheme.bodySmall?.copyWith(color: color),
    side: BorderSide(color: color.withValues(alpha: 0.4)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

String _tagLabel(AppLocalizations l10n, String slug) {
  switch (slug) {
    case '#urgent':
      return l10n.tag_urgent;
    case '#not_urgent':
      return l10n.tag_not_urgent;
    case '#important':
      return l10n.tag_important;
    case '#not_important':
      return l10n.tag_not_important;
    case '#timed':
      return l10n.tag_timed;
    case '#fragmented':
      return l10n.tag_fragmented;
    case '#waiting':
      return l10n.tag_waiting;
    default:
      return slug;
  }
}

Color _tagColor(ThemeData theme, String slug) {
  if (_executionTags.contains(slug)) {
    return theme.colorScheme.primary;
  }
  if (_urgencyTags.contains(slug)) {
    return theme.colorScheme.tertiary;
  }
  if (_importanceTags.contains(slug)) {
    return theme.colorScheme.secondary;
  }
  if (slug.startsWith('@')) {
    return theme.colorScheme.onSurfaceVariant;
  }
  return theme.colorScheme.outline;
}

IconData? _tagIcon(String slug) {
  switch (slug) {
    case '#timed':
      return Icons.timelapse;
    case '#fragmented':
      return Icons.flash_on_outlined;
    case '#waiting':
      return Icons.handshake_outlined;
    case '#urgent':
      return Icons.priority_high;
    case '#important':
      return Icons.star_outline;
    case '#not_important':
      return Icons.star_border;
    case '#not_urgent':
      return Icons.schedule;
    default:
      return null;
  }
}

const List<String> _quadrantOptionSlugs = <String>[
  '#urgent',
  '#important',
  '#not_urgent',
  '#not_important',
];

const List<String> _executionOptionSlugs = <String>[
  '#timed',
  '#fragmented',
  '#waiting',
];

const _depthBarColors = <Color>[
  Color(0xFF7F8CFF),
  Color(0xFF5AC9B0),
  Color(0xFFFFB86C),
  Color(0xFFE59BFF),
];

const _executionTags = <String>{'#timed', '#fragmented', '#waiting'};
const _urgencyTags = <String>{'#urgent', '#not_urgent'};
const _importanceTags = <String>{'#important', '#not_important'};

bool _listEquals(List<Task> a, List<Task> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i].id != b[i].id || a[i].sortIndex != b[i].sortIndex) {
      return false;
    }
  }
  return true;
}

bool _treeEquals(List<TaskTreeNode> a, List<TaskTreeNode> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i].task.id != b[i].task.id ||
        a[i].task.sortIndex != b[i].task.sortIndex) {
      return false;
    }
  }
  return true;
}
