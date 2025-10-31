import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../tasks/utils/hierarchy_utils.dart';
import '../../tasks/utils/sort_index_utils.dart';
import '../../tasks/utils/task_collection_utils.dart';
// import '../../../core/providers/inbox_drag_provider.dart';
import '../widgets/inbox_task_tile.dart';
import '../../../core/providers/inbox_drag_provider.dart';
import '../inbox_drag_target.dart';

class InboxTaskList extends ConsumerStatefulWidget {
  const InboxTaskList({
    super.key,
    required this.tasks,
  });

  final List<Task> tasks;

  @override
  ConsumerState<InboxTaskList> createState() => _InboxTaskListState();
}

class _InboxTaskListState extends ConsumerState<InboxTaskList> {
  late List<Task> _tasks;
  int? _expandedTaskId; // 手风琴模式：记录当前展开的任务ID
  // 自管占位逻辑已移除，改回 Reorderable + 标准插入线

  @override
  void initState() {
    super.initState();
    _tasks = List<Task>.from(widget.tasks);
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) {
      return;
    }

    // 过滤掉 trashed 状态的任务
    final filteredTasks = _tasks.where((task) => task.status != TaskStatus.trashed).toList();
    final rootTasks = collectRoots(filteredTasks)
        .where((task) => !isProjectOrMilestone(task))
        .toList();

    setState(() {
      final task = rootTasks.removeAt(oldIndex);
      final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      rootTasks.insert(targetIndex, task);
      // 将排序变化反映回 _tasks（filteredTasks 已与 _tasks 同源）
      _tasks = filteredTasks;
    });

    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final before = targetIndex > 0 ? rootTasks[targetIndex - 1].sortIndex : null;
    final after = targetIndex < rootTasks.length - 1
        ? rootTasks[targetIndex + 1].sortIndex
        : null;
    final newSortIndex = calculateSortIndex(before, after);
    final task = rootTasks[targetIndex];
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

  @override
  void didUpdateWidget(covariant InboxTaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks != oldWidget.tasks) {
      _tasks = List<Task>.from(widget.tasks);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    // 过滤掉 trashed 状态的任务（双重保障，Repository 层已经过滤）
    final filteredTasks = _tasks.where((task) => task.status != TaskStatus.trashed).toList();

    // 过滤出根任务（parentId == null 或者 parent 不在 inbox 中）
    final rootTasks = collectRoots(filteredTasks)
        // 排除项目和里程碑类型的根任务（只显示普通任务）
        .where((task) => !isProjectOrMilestone(task))
        .toList();

    if (rootTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // 列表开头插入线：仅用于子任务→根级
        InboxDragTarget(
          targetType: InboxDragTargetType.first,
          beforeTask: rootTasks.isNotEmpty ? rootTasks.first : null,
          onPromoteToRoot: (dragged, newIndex) => _optimisticallyPromoteToRoot(dragged, newIndex),
        ),
        ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
          itemCount: rootTasks.length,
          onReorder: _handleReorder,
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
            final rootTask = rootTasks[index];
            return Column(
              key: ValueKey('inbox-root-item-${rootTask.id}'),
              children: [
                if (index > 0)
                  InboxDragTarget(
                    targetType: InboxDragTargetType.between,
                    beforeTask: rootTasks[index - 1],
                    afterTask: rootTask,
                    onPromoteToRoot: (dragged, newIndex) => _optimisticallyPromoteToRoot(dragged, newIndex),
                  ),
                _InboxExpandableTaskItem(
                  task: rootTask,
                  allTasks: filteredTasks,
                  isExpanded: _expandedTaskId == rootTask.id,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _expandedTaskId = expanded ? rootTask.id : null;
                    });
                  },
                  leading: ReorderableDragStartListener(
          index: index,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 12, top: 12, bottom: 12),
                      child: Icon(Icons.drag_indicator_rounded, size: 20),
                    ),
                  ),
                  contentPadding: const EdgeInsets.only(left: 0, right: 16, top: 12, bottom: 12),
                ),
              ],
    );
          },
        ),
        // 列表结尾插入线：仅用于子任务→根级
        InboxDragTarget(
          targetType: InboxDragTargetType.last,
          afterTask: rootTasks.isNotEmpty ? rootTasks.last : null,
          onPromoteToRoot: (dragged, newIndex) => _optimisticallyPromoteToRoot(dragged, newIndex),
        ),
      ],
    );
  }

  // 自管占位逻辑移除

  void _optimisticallyPromoteToRoot(Task dragged, double newSortIndex) {
    final idx = _tasks.indexWhere((t) => t.id == dragged.id);
    if (idx == -1) return;
    setState(() {
      _tasks = List<Task>.from(_tasks)
        ..[idx] = _tasks[idx].copyWith(parentId: null, sortIndex: newSortIndex);
    });
  }

}

/// Inbox 可展开的任务项组件
/// 
/// 支持展开/折叠显示子任务，同时支持拖拽重新排序
class _InboxExpandableTaskItem extends ConsumerWidget {
  const _InboxExpandableTaskItem({
    required this.task,
    required this.allTasks,
    required this.isExpanded,
    required this.onExpansionChanged,
    this.leading,
    this.contentPadding,
    });

  final Task task;
  final List<Task> allTasks;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final Widget? leading;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 检查是否有子任务（排除项目和里程碑，排除 trashed 状态）
    final hasChildren = allTasks.any((t) =>
        t.parentId == task.id &&
        !isProjectOrMilestone(t) &&
        t.status != TaskStatus.trashed);

    // 如果没有子任务，直接显示任务 tile
    if (!hasChildren) {
      return InboxTaskTile(task: task, leading: leading, contentPadding: contentPadding);
    }

    // 有子任务，使用 ExpansionTile 展开/折叠（移除下划线装饰）
    return ExpansionTile(
      key: ValueKey('inbox-expandable-${task.id}'),
      initiallyExpanded: isExpanded,
      onExpansionChanged: onExpansionChanged,
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      // 移除下划线装饰
      shape: const Border(),
      collapsedShape: const Border(),
      // 任务头部：任务 tile
      title: InboxTaskTile(task: task, leading: leading, contentPadding: contentPadding),
      // 子任务列表
      children: [
        _InboxTaskChildren(
          parentTaskId: task.id,
          allTasks: allTasks,
          depth: 0,
        ),
      ],
    );
  }
}

/// Inbox 任务的子任务列表组件
/// 
/// 递归展示子任务，支持多层嵌套（最多3级）
class _InboxTaskChildren extends ConsumerWidget {
  const _InboxTaskChildren({
    required this.parentTaskId,
    required this.allTasks,
    this.depth = 0,
  });

  final int parentTaskId;
  final List<Task> allTasks;
  final int depth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 找出所有直接子任务，排除项目和里程碑，按 sortIndex 排序
    final children = allTasks
        .where((task) =>
            task.parentId == parentTaskId &&
            !isProjectOrMilestone(task) &&
            task.status != TaskStatus.trashed)
        .toList()
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    // 递归展示子任务（最多3级）
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        children: children.map((childTask) {
          return _InboxSubtaskItem(
            task: childTask,
            allTasks: allTasks,
            depth: depth + 1,
          );
        }).toList(),
      ),
    );
  }
}

/// Inbox 子任务项组件
/// 
/// 支持递归展示多层子任务，每层增加缩进（最多3级）
class _InboxSubtaskItem extends ConsumerStatefulWidget {
  const _InboxSubtaskItem({
    required this.task,
    required this.allTasks,
    this.depth = 0,
  });

  final Task task;
  final List<Task> allTasks;
  final int depth;

  @override
  ConsumerState<_InboxSubtaskItem> createState() => _InboxSubtaskItemState();
}

class _InboxSubtaskItemState extends ConsumerState<_InboxSubtaskItem> {
  bool _isExpanded = false;
  static const double _indentPerLevel = 32.0; // 统一每级仅一个手柄位宽度

  @override
  Widget build(BuildContext context) {
    // 检查是否有子任务（排除项目和里程碑，排除 trashed 状态）
    final hasChildren = widget.allTasks.any((t) =>
        t.parentId == widget.task.id &&
        !isProjectOrMilestone(t) &&
        t.status != TaskStatus.trashed);

    // 如果达到最大层级（3级），不再展开子任务
    final maxDepthReached = widget.depth >= 3;

    // 如果没有子任务或达到最大层级，直接显示任务 tile（带缩进）
    if (!hasChildren || maxDepthReached) {
      return Padding(
        padding: EdgeInsets.only(left: widget.depth * _indentPerLevel, bottom: 4),
        child: InboxTaskTile(task: widget.task),
      );
    }

    // 有子任务，使用 ExpansionTile 展开/折叠（移除下划线装饰）
    return ExpansionTile(
      key: ValueKey('inbox-subtask-${widget.task.id}'),
      initiallyExpanded: _isExpanded,
      onExpansionChanged: (expanded) {
        setState(() {
          _isExpanded = expanded;
        });
      },
      tilePadding: EdgeInsets.only(left: widget.depth * _indentPerLevel, right: 16),
      childrenPadding: EdgeInsets.only(
        left: 0,
        right: 16,
        bottom: 8,
      ),
      // 移除下划线装饰
      shape: const Border(),
      collapsedShape: const Border(),
      title: InboxTaskTile(task: widget.task),
      children: [
        _InboxTaskChildren(
          parentTaskId: widget.task.id,
          allTasks: widget.allTasks,
          depth: widget.depth,
        ),
      ],
    );
  }
}

