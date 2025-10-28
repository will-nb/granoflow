import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:granoflow/generated/l10n/app_localizations.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/service_providers.dart';
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
  bool _editMode = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final editActions = ref.watch(taskEditActionsNotifierProvider);
    final bool showLinearProgress = _editMode && editActions.isLoading;
    
    // 动态获取有任务的分组
    final sectionMetas = <_SectionMeta>[
      _SectionMeta(section: TaskSection.overdue, title: l10n.plannerSectionOverdueTitle),
      _SectionMeta(section: TaskSection.today, title: l10n.plannerSectionTodayTitle),
      _SectionMeta(section: TaskSection.tomorrow, title: l10n.plannerSectionTomorrowTitle),
      _SectionMeta(section: TaskSection.thisWeek, title: l10n.plannerSectionThisWeekTitle),
      _SectionMeta(section: TaskSection.thisMonth, title: l10n.plannerSectionThisMonthTitle),
      _SectionMeta(section: TaskSection.later, title: l10n.plannerSectionLaterTitle),
    ];

    return GradientPageScaffold(
      appBar: const PageAppBar(
        title: 'Tasks',
      ),
      drawer: const MainDrawer(),
      body: Column(
        children: [
        // 模式切换控件
        if (showLinearProgress)
          const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ToggleButtons(
                isSelected: <bool>[!_editMode, _editMode],
                onPressed: (index) {
                  setState(() {
                    _editMode = index == 1;
                  });
                },
                constraints: const BoxConstraints(minHeight: 36, minWidth: 72),
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
        // 主要内容列表
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: sectionMetas
                .map((meta) => Consumer(
                  builder: (context, ref, child) {
                    // 检查该分组是否有任务
                    final tasksAsync = ref.watch(taskSectionsProvider(meta.section));
                    return tasksAsync.when(
                      data: (tasks) {
                        // 如果没有任务，不显示该分组
                        if (tasks.isEmpty) return const SizedBox.shrink();
                        return TaskSectionPanel(
                          key: ValueKey('${meta.section}-${_editMode.toString()}'),
                          section: meta.section,
                          title: meta.title,
                          editMode: _editMode,
                          onQuickAdd: () => _handleQuickAdd(context, meta.section),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ))
                .toList(growable: false),
          ),
        ),
      ],
    ),
    );
  }

  Future<void> _handleQuickAdd(BuildContext context, TaskSection section) async {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.taskListAddedToast)));
    } catch (error, stackTrace) {
      debugPrint('Failed to add task: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.taskListAddError)));
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
                  return _EmptySectionHint(message: l10n.taskListEmptySectionHint);
                }
                final roots = _collectRoots(tasks);
                if (roots.isEmpty) {
                  return _EmptySectionHint(message: l10n.taskListEmptySectionHint);
                }
                if (editMode) {
                  return _TaskSectionEditor(section: section, roots: roots);
                }
                return _TaskSectionBaseList(section: section, roots: roots);
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

class _TaskSectionBaseList extends ConsumerWidget {
  const _TaskSectionBaseList({required this.section, required this.roots});

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
    
    return Column(
      children: widgets,
    );
  }
}

class _TaskSectionEditor extends ConsumerStatefulWidget {
  const _TaskSectionEditor({required this.section, required this.roots});

  final TaskSection section;
  final List<Task> roots;

  @override
  ConsumerState<_TaskSectionEditor> createState() => _TaskSectionEditorState();
}

class _TaskSectionEditorState extends ConsumerState<_TaskSectionEditor> {
  late List<Task> _roots;

  @override
  void initState() {
    super.initState();
    _roots = List<Task>.from(widget.roots);
  }

  @override
  void didUpdateWidget(covariant _TaskSectionEditor oldWidget) {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      child: _TaskEditorHeader(task: task, section: widget.section),
                    ),
                  ],
                ),
                _TaskTreeTile(
                  section: widget.section,
                  rootTask: task,
                  editMode: true,
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
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
    final after = targetIndex < _roots.length - 1 ? _roots[targetIndex + 1].sortIndex : null;
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
          return _TaskTreeEditorView(tree: tree, section: section, padding: padding);
        }
        return _TaskTreeBaseView(tree: tree, section: section);
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _ErrorBanner(message: '$error'),
    );
  }
}

class _TaskTreeBaseView extends ConsumerWidget {
  const _TaskTreeBaseView({required this.tree, required this.section});

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
      key: ValueKey('base-${tree.task.id}'),
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
      childrenPadding: EdgeInsets.only(left: 16.0 + depth * 12, right: 8, bottom: 8),
      children: node.children
          .map((child) => _TaskTreeBranch(node: child, depth: depth + 1))
          .toList(growable: false),
    );
  }
}

class _TaskTreeEditorView extends ConsumerWidget {
  const _TaskTreeEditorView({required this.tree, required this.section, this.padding});

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
          ref.read(expandedRootTaskIdProvider.notifier).state = isExpanded ? null : tree.task.id;
        },
        children: [
          ExpansionPanelRadio(
            value: tree.task.id,
            canTapOnHeader: true,
            headerBuilder: (context, isExpanded) {
              return _TaskEditorHeader(task: tree.task, section: section);
            },
            body: _TaskChildrenEditor(nodes: tree.children, parentTask: tree.task),
          ),
        ],
      ),
    );
  }
}

class _TaskEditorHeader extends ConsumerWidget {
  const _TaskEditorHeader({required this.task, required this.section});

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

class _TaskChildrenEditor extends ConsumerStatefulWidget {
  const _TaskChildrenEditor({required this.nodes, required this.parentTask});

  final List<TaskTreeNode> nodes;
  final Task parentTask;

  @override
  ConsumerState<_TaskChildrenEditor> createState() => _TaskChildrenEditorState();
}

class _TaskChildrenEditorState extends ConsumerState<_TaskChildrenEditor> {
  late List<TaskTreeNode> _nodes;

  @override
  void initState() {
    super.initState();
    _nodes = List<TaskTreeNode>.from(widget.nodes);
  }

  @override
  void didUpdateWidget(covariant _TaskChildrenEditor oldWidget) {
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
          leading: ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_handle)),
          title: Text(node.task.title),
          subtitle: Text('ID: ${node.task.taskId}'),
          trailing: Wrap(
            spacing: 4,
            children: [
              IconButton(
                tooltip: l10n.actionAddSubtask,
                icon: const Icon(Icons.add),
                onPressed: () => _showAddSubtaskDialog(context, ref, node.task.id),
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
    final before = targetIndex > 0 ? _nodes[targetIndex - 1].task.sortIndex : null;
    final after = targetIndex < _nodes.length - 1 ? _nodes[targetIndex + 1].task.sortIndex : null;
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
  const _TaskLeafTile({required this.task, required this.depth, required this.onTap});

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
          direction: isDragging ? DismissDirection.none : DismissDirection.horizontal,
          onLeftAction: (task) => SwipeActionHandler.handleAction(context, ref, SwipeActionType.postpone, task),
          onRightAction: (task) => SwipeActionHandler.handleAction(context, ref, SwipeActionType.archive, task),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
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
                      onSubmitted: (value) => _updateTaskTitle(context, value),
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
                      ref.read(taskListExpandedTaskIdProvider.notifier).state =
                          isExpanded ? null : widget.task.id;
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
                          _updateDueDateForTask(context, ref, widget.task.id, date);
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

  Future<void> _updateDueDateForTask(BuildContext context, WidgetRef ref, int taskId, DateTime dueDate) async {
    try {
      await ref.read(taskServiceProvider).updateDetails(
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
  const _TaskTitle({required this.task, required this.depth, this.highlight = false});

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
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onErrorContainer),
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
    final dateLabel = MaterialLocalizations.of(context).formatMediumDate(_selectedDate!);
    final sectionLabel = _labelForSection(l10n, widget.section);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets, left: 20, right: 20, top: 20),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).taskListInputValidation)));
      return;
    }
    setState(() {
      _submitting = true;
    });
    Navigator.of(
      context,
    ).pop(_QuickAddResult(title: title, dueDate: _selectedDate ?? _defaultDueDate(widget.section)));
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

Future<void> _startFocus(BuildContext context, WidgetRef ref, int taskId) async {
  final notifier = ref.read(focusActionsNotifierProvider.notifier);
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    await notifier.start(taskId);
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.taskListFocusStartedToast)));
  } catch (error, stackTrace) {
    debugPrint('Failed to start focus session: $error\n$stackTrace');
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.taskListFocusError)));
  }
}

Future<void> _archiveTask(BuildContext context, WidgetRef ref, int taskId) async {
  final notifier = ref.read(taskEditActionsNotifierProvider.notifier);
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    await notifier.archive(taskId);
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.taskListTaskArchivedToast)));
  } catch (error, stackTrace) {
    debugPrint('Failed to archive task: $error\n$stackTrace');
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.taskListTaskArchivedError)));
  }
}

Future<void> _showAddSubtaskDialog(BuildContext context, WidgetRef ref, int parentId) async {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(AppLocalizations.of(dialogContext).taskListAddSubtaskDialogTitle),
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
      SnackBar(content: Text(AppLocalizations.of(context).taskListSubtaskCreatedToast)),
    );
  } catch (error, stackTrace) {
    debugPrint('Failed to create subtask: $error\n$stackTrace');
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).taskListSubtaskError)));
  }
}

Future<void> _showRenameDialog(BuildContext context, WidgetRef ref, Task task) async {
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
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.commonCancel)),
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
    if (a[i].task.id != b[i].task.id || a[i].task.sortIndex != b[i].task.sortIndex) {
      return false;
    }
  }
  return true;
}
