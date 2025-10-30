import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:granoflow/generated/l10n/app_localizations.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../core/services/task_service.dart';
import '../../core/constants/task_constants.dart';
import '../../data/models/tag.dart';
import '../../data/models/task.dart';
import '../widgets/modern_tag.dart';
import '../widgets/modern_tag_group.dart';
import '../widgets/tag_data.dart';
import '../widgets/page_app_bar.dart';
import '../widgets/main_drawer.dart';
import '../widgets/gradient_page_scaffold.dart';
import '../widgets/dismissible_task_tile.dart';
import '../widgets/swipe_configs.dart';
import '../widgets/swipe_action_handler.dart';
import '../widgets/swipe_action_type.dart';
import '../widgets/flexible_text_input.dart';
import '../widgets/flexible_description_input.dart';
import '../widgets/task_row_content.dart';
import '../widgets/reorderable_proxy_decorator.dart';
import '../widgets/task_tile_content.dart';

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
      body: GestureDetector(
        onTap: () {
          // 点击空白区域时移除焦点
          FocusManager.instance.primaryFocus?.unfocus();
        },
        behavior: HitTestBehavior.translucent,
        child: Column(
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

class _TaskSectionTaskModeList extends ConsumerStatefulWidget {
  const _TaskSectionTaskModeList({required this.section, required this.roots});

  final TaskSection section;
  final List<Task> roots;

  @override
  ConsumerState<_TaskSectionTaskModeList> createState() =>
      _TaskSectionTaskModeListState();
}

class _TaskSectionTaskModeListState
    extends ConsumerState<_TaskSectionTaskModeList> {
  late List<Task> _roots;

  @override
  void initState() {
    super.initState();
    _roots = List<Task>.from(widget.roots);
    if (widget.section == TaskSection.later) {
      debugPrint('📱 [TaskListPage] initState - 以后区域任务顺序:');
      for (final task in _roots) {
        debugPrint('  - ${task.title}: dueAt=${task.dueAt}');
      }
    }
  }

  @override
  void didUpdateWidget(_TaskSectionTaskModeList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.roots != oldWidget.roots) {
      _roots = List<Task>.from(widget.roots);
      if (widget.section == TaskSection.later) {
        debugPrint('📱 [TaskListPage] didUpdateWidget - 以后区域任务顺序:');
        for (final task in _roots) {
          debugPrint('  - ${task.title}: dueAt=${task.dueAt}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_roots.isEmpty) {
      return const SizedBox.shrink();
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _roots.length,
      onReorder: (oldIndex, newIndex) => _handleReorder(oldIndex, newIndex),
      buildDefaultDragHandles: false,
      proxyDecorator: ReorderableProxyDecorator.build,
      itemBuilder: (context, index) {
        final task = _roots[index];
        return ReorderableDragStartListener(
          key: ValueKey('task-${task.id}'),
          index: index,
          child: _TaskTreeTile(
            section: widget.section,
            rootTask: task,
            editMode: false,
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
    final before =
        targetIndex > 0 ? _roots[targetIndex - 1].sortIndex : null;
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

  double _calculateSortIndex(double? before, double? after) {
    if (before == null && after == null) {
      return 1000.0;
    } else if (before == null) {
      return after! - 1000.0;
    } else if (after == null) {
      return before + 1000.0;
    } else {
      return (before + after) / 2.0;
    }
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

/// Tasks 页面的叶子节点任务显示组件
/// 使用 TaskRowContent 实现 inline 编辑，与 Inbox 风格统一
class _TaskLeafTile extends ConsumerWidget {
  const _TaskLeafTile({
    required this.task,
    required this.depth,
  });

  final Task task;
  final int depth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indentation = depth * 16.0;

    return Padding(
      padding: EdgeInsets.only(left: indentation),
      child: DismissibleTaskTile(
        task: task,
        config: SwipeConfigs.tasksConfig,
        direction: DismissDirection.horizontal,
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
        child: TaskTileContent(task: task),
      ),
    );
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
  // 保持与 TaskRepository 一致的排序：dueAt（日期部分）→ sortIndex → createdAt
  // 注意：tasks 已经由 TaskRepository 排序，这里不需要重新排序
  // 但为了防止 Set/Map 操作打乱顺序，我们保持原始顺序
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
        _QuickTasksCollapsibleSection(asyncTasks: quickTasksAsync),
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

/// Collapsible section for quick tasks, similar to ProjectCard
class _QuickTasksCollapsibleSection extends ConsumerWidget {
  const _QuickTasksCollapsibleSection({required this.asyncTasks});

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
                    _QuickTasksHeaderRow(
                      isExpanded: isExpanded,
                      taskCount: tasks.length,
                    ),
                    if (isExpanded && tasks.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _QuickTasksList(tasks: tasks),
                      ),
                    if (isExpanded && tasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _EmptyPlaceholder(
                          message: l10n.projectQuickTasksEmpty,
                        ),
                      ),
                  ],
                );
              },
              loading: () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QuickTasksHeaderRow(isExpanded: isExpanded, taskCount: 0),
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
                  _QuickTasksHeaderRow(isExpanded: isExpanded, taskCount: 0),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _ErrorBanner(message: '$error'),
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

/// Header row for quick tasks section
class _QuickTasksHeaderRow extends StatelessWidget {
  const _QuickTasksHeaderRow({
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

/// List of quick tasks (displayed when expanded)
class _QuickTasksList extends StatelessWidget {
  const _QuickTasksList({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tasks
          .map((task) => _QuickTaskItem(task: task))
          .toList(growable: false),
    );
  }
}

/// Individual quick task item, styled like _MilestoneCard with swipe actions
class _QuickTaskItem extends ConsumerWidget {
  const _QuickTaskItem({required this.task});

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
              _TaskHeaderRow(
                task: task,
                showConvertAction: true,
                leading: _buildExecutionLeading(context, task),
              ),
              if (task.description != null && task.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: DescriptionBlock(description: task.description!),
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
  DateTime? _projectDeadline;
  String? _executionTag;
  String? _deadlineError;
  bool _suppressProjectShortcut = false;

  /// 将Tag列表转换为TagData列表
  List<TagData> _tagsToTagData(List<Tag> tags) {
    return tags.map((tag) => TagData.fromTagWithLocalization(tag, context)).toList();
  }


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
    );
  }

  void _onProjectDescriptionChanged() {
    _handleShortcutInController(
      _descriptionController,
      includeExecution: true,
      onHashtagSelected: (slug) {
        setState(() {
          _assignProjectTag(slug);
        });
      },
    );
  }

  void _handleShortcutInController(
    TextEditingController controller, {
    required bool includeExecution,
    required ValueChanged<String> onHashtagSelected,
  }) {
    if (_suppressProjectShortcut) {
      return;
    }
    final text = controller.text;
    if (text.isEmpty) {
      return;
    }
    final lastChar = text.codeUnitAt(text.length - 1);
    if (lastChar != 35) {
      // #
      return;
    }
    _suppressProjectShortcut = true;
    final trimmed = text.substring(0, text.length - 1);
    controller.value = controller.value.copyWith(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
    _suppressProjectShortcut = false;
    Future.microtask(() async {
      final slug = await _pickHashtag(includeExecution: includeExecution);
      if (!mounted || slug == null) {
        return;
      }
      onHashtagSelected(slug);
    });
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
              (slug) {
                final kind = _getTagKindFromSlug(slug);
                final (_, icon, __) = _getTagStyle(slug, kind);
                return ListTile(
                  leading: icon != null
                      ? Icon(
                          icon,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                  title: Text(_tagLabel(l10n, slug)),
                  onTap: () => Navigator.of(sheetContext).pop(slug),
                );
              },
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
    if (lastChar != 35) {
      return;
    }
    draft.suppressShortcut = true;
    final trimmed = text.substring(0, text.length - 1);
    draft.titleController.value = draft.titleController.value.copyWith(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
    draft.suppressShortcut = false;
    Future.microtask(() async {
      final slug = await _pickHashtag(includeExecution: true);
      if (!mounted || slug == null) {
        return;
      }
      setState(() {
        draft.applyTag(slug);
      });
    });
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
              FlexibleTextInput(
                controller: _titleController,
                softLimit: 50,
                hardLimit: 255,
                hintText: l10n.projectSheetTitleHint,
                labelText: l10n.taskListInputLabel,
                onChanged: (_) => _onProjectTitleChanged(),
              ),
              const SizedBox(height: 8),
              FlexibleDescriptionInput(
                controller: _descriptionController,
                softLimit: 200,
                hardLimit: 60000,
                hintText: l10n.projectSheetDescriptionHint,
                labelText: l10n.flexibleDescriptionLabel,
                onChanged: (_) => _onProjectDescriptionChanged(),
              ),
              const SizedBox(height: 16),
              // 四象限标签和执行方式标签inline排列
              Consumer(
                builder: (context, ref, child) {
                  final urgencyTagsAsync = ref.watch(urgencyTagOptionsProvider);
                  final importanceTagsAsync = ref.watch(importanceTagOptionsProvider);
                  final executionTagsAsync = ref.watch(executionTagOptionsProvider);
                  
                  return urgencyTagsAsync.when(
                    data: (urgencyTags) => importanceTagsAsync.when(
                      data: (importanceTags) => executionTagsAsync.when(
                        data: (executionTags) {
                          // 合并所有标签
                          final allTags = [...urgencyTags, ...importanceTags, ...executionTags];
                          final tagData = _tagsToTagData(allTags);
                          final selectedTags = <String>{
                            if (_selectedUrgencyTag != null) _selectedUrgencyTag!,
                            if (_selectedImportanceTag != null) _selectedImportanceTag!,
                            if (_executionTag != null) _executionTag!,
                          };
                          
                          return ModernTagGroup(
                            tags: tagData,
                            selectedTags: selectedTags,
                            multiSelect: false,
                            variant: TagVariant.pill,
                            size: TagSize.medium,
                            onSelectionChanged: (selected) {
                              setState(() {
                                if (selected.isEmpty) {
                                  _selectedUrgencyTag = null;
                                  _selectedImportanceTag = null;
                                  _executionTag = null;
                                } else {
                                  final selectedSlug = selected.first;
                                  if (_urgencyTags.contains(selectedSlug)) {
                                    _selectedUrgencyTag = selectedSlug;
                                    _selectedImportanceTag = null;
                                    _executionTag = null;
                                  } else if (_importanceTags.contains(selectedSlug)) {
                                    _selectedImportanceTag = selectedSlug;
                                    _selectedUrgencyTag = null;
                                    _executionTag = null;
                                  } else if (_executionOptionSlugs.contains(selectedSlug)) {
                                    _executionTag = selectedSlug;
                                    _selectedUrgencyTag = null;
                                    _selectedImportanceTag = null;
                                  }
                                }
                              });
                            },
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const Text('加载标签失败'),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => Text('加载标签失败'),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => Text('加载标签失败'),
                  );
                },
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
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();
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

class _MilestoneDraftTile extends StatefulWidget {
  const _MilestoneDraftTile({
    required this.draft,
    required this.onRemove,
    required this.onPickDeadline,
    required this.onChanged,
  });

  final _MilestoneDraft draft;
  final VoidCallback onRemove;
  final Future<void> Function() onPickDeadline;
  final VoidCallback onChanged;

  @override
  State<_MilestoneDraftTile> createState() => _MilestoneDraftTileState();
}

class _MilestoneDraftTileState extends State<_MilestoneDraftTile> {

  /// 将Tag列表转换为TagData列表
  List<TagData> _tagsToTagData(BuildContext context, List<Tag> tags) {
    return tags.map((tag) => TagData.fromTagWithLocalization(tag, context)).toList();
  }

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
                  child: FlexibleTextInput(
                    controller: widget.draft.titleController,
                    softLimit: 50,
                    hardLimit: 255,
                    hintText: l10n.projectSheetMilestoneTitleHint,
                    labelText: l10n.taskListInputLabel,
                    onChanged: (_) => widget.onChanged(),
                  ),
                ),
                IconButton(
                  onPressed: widget.onRemove,
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
                    widget.draft.deadline != null
                        ? _formatDeadline(context, widget.draft.deadline) ?? ''
                        : l10n.projectSheetSelectDeadlineHint,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.onPickDeadline,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(l10n.projectSheetSelectDeadline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 四象限标签和执行方式标签inline排列
            Consumer(
              builder: (context, ref, child) {
                final urgencyTagsAsync = ref.watch(urgencyTagOptionsProvider);
                final importanceTagsAsync = ref.watch(importanceTagOptionsProvider);
                final executionTagsAsync = ref.watch(executionTagOptionsProvider);
                
                return urgencyTagsAsync.when(
                  data: (urgencyTags) => importanceTagsAsync.when(
                    data: (importanceTags) => executionTagsAsync.when(
                      data: (executionTags) {
                        // 合并所有标签
                        final allTags = [...urgencyTags, ...importanceTags, ...executionTags];
                        final tagData = _tagsToTagData(context, allTags);
                        final selectedTags = <String>{
                          if (widget.draft.urgencyTag != null) widget.draft.urgencyTag!,
                          if (widget.draft.importanceTag != null) widget.draft.importanceTag!,
                          if (widget.draft.executionTag != null) widget.draft.executionTag!,
                        };
                        
                        return ModernTagGroup(
                          tags: tagData,
                          selectedTags: selectedTags,
                          multiSelect: false,
                          variant: TagVariant.pill,
                          size: TagSize.medium,
                          onSelectionChanged: (selected) {
                            if (selected.isEmpty) {
                              widget.draft.urgencyTag = null;
                              widget.draft.importanceTag = null;
                              widget.draft.executionTag = null;
                            } else {
                              final selectedSlug = selected.first;
                              if (_urgencyTags.contains(selectedSlug)) {
                                widget.draft.urgencyTag = selectedSlug;
                                widget.draft.importanceTag = null;
                                widget.draft.executionTag = null;
                              } else if (_importanceTags.contains(selectedSlug)) {
                                widget.draft.importanceTag = selectedSlug;
                                widget.draft.urgencyTag = null;
                                widget.draft.executionTag = null;
                              } else if (_executionOptionSlugs.contains(selectedSlug)) {
                                widget.draft.executionTag = selectedSlug;
                                widget.draft.urgencyTag = null;
                                widget.draft.importanceTag = null;
                              }
                            }
                            widget.onChanged();
                          },
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Text('加载标签失败'),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => Text('加载标签失败'),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => Text('加载标签失败'),
                );
              },
            ),
            const SizedBox(height: 12),
            FlexibleDescriptionInput(
              controller: widget.draft.descriptionController,
              softLimit: 200,
              hardLimit: 60000,
              hintText: l10n.projectSheetDescriptionHint,
              labelText: l10n.flexibleDescriptionLabel,
              onChanged: (_) => widget.onChanged(),
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
                useBodyText: true, // 零散任务使用普通文字大小
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
    final theme = Theme.of(context);

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
            child: TaskRowContent(
              task: task,
              compact: true,
              useBodyText: true, // 子任务使用普通文字大小
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
  final kind = _getTagKindFromSlug(slug);
  final (color, icon, _) = _getTagStyle(slug, kind);
  if (icon == null) {
    return null;
  }
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
    this.useBodyText = false, // 是否使用普通文字大小（零散任务用）
  });

  final Task task;
  final bool showConvertAction;
  final Widget? leading;
  final bool useBodyText; // 是否使用普通文字大小

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
              child: InkWell(
                onTap: () => _handleTitleTap(context, ref),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    task.title,
                    style: useBodyText ? theme.textTheme.bodyLarge : theme.textTheme.titleMedium,
                  ),
                ),
              ),
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

  /// 处理标题点击事件，弹出编辑对话框
  Future<void> _handleTitleTap(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: task.title);
    
    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.taskEditTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: InputDecoration(
            hintText: l10n.taskTitleHint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(dialogContext).pop(value.trim());
            }
          },
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

    controller.dispose();

    if (newTitle != null && newTitle != task.title) {
      try {
        final taskService = ref.read(taskServiceProvider);
        await taskService.updateDetails(
          taskId: task.id,
          payload: TaskUpdate(title: newTitle),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.taskUpdateSuccess),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.taskUpdateError}: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
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
      .map((slug) => _buildModernTag(context, slug))
      .whereType<Widget>()
      .toList(growable: false);
}

Widget? _buildModernTag(BuildContext context, String slug) {
  final tagData = _slugToTagData(context, slug);
  if (tagData == null) return null;

  return ModernTag(
    label: tagData.label,
    color: tagData.color,
    icon: tagData.icon,
    prefix: tagData.prefix,
    selected: false,
    variant: TagVariant.pill,
    size: TagSize.small,
  );
}


String _tagLabel(AppLocalizations l10n, String slug) {
  switch (slug) {
    // 上下文标签
    case '@anywhere':
      return l10n.tag_anywhere;
    case '@home':
      return l10n.tag_home;
      case '@company':
        return l10n.tag_company;
      case '@school':
        return l10n.tag_school;
    case '@local':
      return l10n.tag_local;
    case '@travel':
      return l10n.tag_travel;
    // 紧急程度标签
    case '#urgent':
      return l10n.tag_urgent;
    case '#not_urgent':
      return l10n.tag_not_urgent;
    // 重要程度标签
    case '#important':
      return l10n.tag_important;
    case '#not_important':
      return l10n.tag_not_important;
    // 执行方式标签
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

// 标签名称（不带前缀）
const _contextTagNames = <String>{'anywhere', 'home', 'workplace', 'local', 'travel'};
const _urgencyTagNames = <String>{'urgent', 'not_urgent'};
const _importanceTagNames = <String>{'important', 'not_important'};
const _executionTagNames = <String>{'timed', 'fragmented', 'waiting'};

/// 从slug创建TagData（用于显示已选择的标签）
TagData? _slugToTagData(BuildContext context, String slug) {
  final l10n = AppLocalizations.of(context);
  
  // 如果slug没有前缀，根据内容添加适当的前缀
  String normalizedSlug = slug;
  if (!slug.startsWith('@') && !slug.startsWith('#')) {
    // 根据标签内容判断类型并添加前缀
    if (_contextTagNames.contains(slug)) {
      normalizedSlug = '@$slug';
    } else if (_urgencyTagNames.contains(slug)) {
      normalizedSlug = '#$slug';
    } else if (_importanceTagNames.contains(slug)) {
      normalizedSlug = '#$slug';
    } else if (_executionTagNames.contains(slug)) {
      normalizedSlug = '#$slug';
    }
  }
  
  final kind = _getTagKindFromSlug(normalizedSlug);
  final label = _tagLabel(l10n, normalizedSlug);
  final (color, icon, prefix) = _getTagStyle(normalizedSlug, kind);
  
  return TagData(
    slug: normalizedSlug,
    label: label,
    color: color,
    icon: icon,
    prefix: prefix,
    kind: kind,
  );
}

/// 根据slug确定TagKind
TagKind _getTagKindFromSlug(String slug) {
  if (slug.startsWith('@')) return TagKind.context;
  if (_urgencyTags.contains(slug)) return TagKind.urgency;
  if (_importanceTags.contains(slug)) return TagKind.importance;
  if (_executionTags.contains(slug)) return TagKind.execution;
  return TagKind.special;
}

/// 获取标签样式（颜色、图标、前缀）
(Color, IconData?, String?) _getTagStyle(String slug, TagKind kind) {
  // 直接复制TagData._getTagStyle的逻辑
  // Context tags - 上下文标签（场景）
  if (slug.startsWith('@')) {
    return (
      const Color(0xFF5AC9B0), // OceanBreezeColorSchemes.lakeCyan
      Icons.place_outlined,
      null,
    );
  }

  // Priority tags - 优先级标签
  if (slug.startsWith('#')) {
    switch (slug) {
      case '#urgent':
        return (
          const Color(0xFFFF6B9D), // OceanBreezeColorSchemes.softPink
          Icons.priority_high,
          null,
        );
      case '#not_urgent':
        return (
          const Color(0xFF9E9E9E), // OceanBreezeColorSchemes.lightBlueGray
          Icons.event_available,
          null,
        );
      case '#important':
        return (
          const Color(0xFFFFB74D), // OceanBreezeColorSchemes.warmYellow
          Icons.star,
          null,
        );
      case '#not_important':
        return (
          const Color(0xFFBDBDBD), // OceanBreezeColorSchemes.silverGray
          Icons.star_outline,
          null,
        );
      case '#waiting':
        return (
          const Color(0xFF9E9E9E), // OceanBreezeColorSchemes.disabledGray
          Icons.hourglass_empty,
          null,
        );
      case '#timed':
        return (const Color(0xFFFF6B9D), Icons.schedule, null); // OceanBreezeColorSchemes.softPink
      case '#fragmented':
        return (
          const Color(0xFF5AC9B0), // OceanBreezeColorSchemes.lakeCyan
          Icons.flash_on_outlined,
          null,
        );
      default:
        // 未知的优先级标签，使用默认样式
        return (
          const Color(0xFF64B5F6), // OceanBreezeColorSchemes.seaSaltBlue
          Icons.tag,
          null,
        );
    }
  }

  // Special tags - 特殊标签
  if (slug == 'wasted') {
    return (
      const Color(0xFF757575), // OceanBreezeColorSchemes.secondaryText
      Icons.delete_outline,
      null,
    );
  }

  // Default - 默认样式
  return (const Color(0xFF64B5F6), Icons.tag, null); // OceanBreezeColorSchemes.seaSaltBlue
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
    if (a[i].task.id != b[i].task.id ||
        a[i].task.sortIndex != b[i].task.sortIndex) {
      return false;
    }
  }
  return true;
}
