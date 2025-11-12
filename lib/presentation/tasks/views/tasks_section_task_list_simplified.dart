import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/tasks_drag_provider.dart';
import '../../../data/models/task.dart';
import '../../widgets/simplified_task_row.dart';
import '../../widgets/reorderable_proxy_decorator.dart';
import '../../widgets/dismissible_task_tile.dart';
import '../../widgets/swipe_action_handler.dart';
import '../../widgets/swipe_configs.dart';
import '../utils/task_collection_utils.dart';
import '../utils/tree_flattening_utils.dart';
import '../../common/task_list/task_list_tree_builder.dart';
import '../../common/task_list/tasks_section_task_list_config.dart';
import '../../common/drag/standard_draggable.dart';

/// Tasks Section 页面的任务列表组件（简化版）
///
/// 使用 SimplifiedTaskRow 显示任务，所有任务平铺显示
/// 保留拖拽排序功能，但移除层级结构和展开/收缩功能
class TasksSectionTaskListSimplified extends ConsumerStatefulWidget {
  const TasksSectionTaskListSimplified({
    super.key,
    required this.section,
    required this.tasks,
  });

  final TaskSection section;
  final List<Task> tasks;

  @override
  ConsumerState<TasksSectionTaskListSimplified> createState() =>
      _TasksSectionTaskListSimplifiedState();
}

class _TasksSectionTaskListSimplifiedState
    extends ConsumerState<TasksSectionTaskListSimplified> {
  late List<Task> _tasks;
  late TasksSectionTaskListConfig _config;

  @override
  void initState() {
    super.initState();
    _tasks = List<Task>.from(widget.tasks);
    _config = TasksSectionTaskListConfig(widget.section);
  }

  @override
  void didUpdateWidget(covariant TasksSectionTaskListSimplified oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks != oldWidget.tasks || widget.section != oldWidget.section) {
      _tasks = List<Task>.from(widget.tasks);
      _config = TasksSectionTaskListConfig(widget.section);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    // 过滤掉 trashed 状态的任务
    final filteredTasks = _tasks
        .where((task) => task.status != TaskStatus.trashed)
        .toList();

    // 构建任务层级树（用于获取所有任务，包括子任务）
    final taskTrees = TaskListTreeBuilder.buildTaskTree(filteredTasks);

    // 扁平化所有任务（不根据展开状态，直接平铺所有任务）
    final allTasks = <Task>[];
    for (final tree in taskTrees) {
      final flattened = flattenTree(tree);
      allTasks.addAll(flattened.map((node) => node.task));
    }

    if (allTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    // 获取根任务列表（用于拖拽排序）
    final rootTasks = collectRoots(filteredTasks);

    // 获取拖拽状态
    final dragNotifier = ref.read(tasksDragProvider.notifier);

    // 使用 ReorderableListView 实现拖拽排序（只对根任务排序）
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rootTasks.length,
      onReorder: (oldIndex, newIndex) {
        // 处理拖拽排序
        _handleReorder(oldIndex, newIndex, rootTasks);
      },
      buildDefaultDragHandles: false,
      proxyDecorator: ReorderableProxyDecorator.build,
      itemBuilder: (context, index) {
        final rootTask = rootTasks[index];
        // 获取该根任务的所有子任务
        final rootTaskTree = taskTrees.firstWhere(
          (tree) => tree.task.id == rootTask.id,
          orElse: () => TaskTreeNode(task: rootTask, children: []),
        );
        final flattened = flattenTree(rootTaskTree);

        // 显示根任务及其所有子任务
        return Column(
          key: ValueKey('root-${rootTask.id}'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: flattened.map((node) {
            final task = node.task;
            final taskLevel = node.depth + 1; // depth 从 0 开始，level 从 1 开始
            
            // 根据区域和任务层级选择配置
            // 今日区域：左滑完成，右滑归档/删除
            // 其他区域：左滑移动到今日，右滑归档/删除
            final config = widget.section == TaskSection.today
                ? (taskLevel > 1 ? SwipeConfigs.tasksSubtaskConfig : SwipeConfigs.tasksConfig)
                : (taskLevel > 1 ? SwipeConfigs.tasksNonTodaySubtaskConfig : SwipeConfigs.tasksNonTodayConfig);

            return DismissibleTaskTile(
                key: ValueKey('tasks-section-${task.id}-${task.updatedAt.millisecondsSinceEpoch}'),
                task: task,
                config: config,
                onLeftAction: (task) {
                  SwipeActionHandler.handleAction(
                    context,
                    ref,
                    config.leftAction,
                    task,
                    taskLevel: taskLevel,
                  );
                },
                onRightAction: (task) {
                  SwipeActionHandler.handleAction(
                    context,
                    ref,
                    config.rightAction,
                    task,
                  );
                },
                child: StandardDraggable<Task>(
                  data: task,
                  handle: const Padding(
                    padding: EdgeInsets.only(right: 12, top: 4),
                    child: Icon(Icons.drag_indicator, size: 20),
                  ),
                  enabled: task.id == rootTask.id, // 只有根任务可以拖拽排序
                  onDragStarted: () {
                    dragNotifier.startDrag(task, Offset.zero);
                  },
                  onDragUpdate: (details) {
                    dragNotifier.updateDragPosition(details.globalPosition);
                  },
                  onDragEnd: () {
                    dragNotifier.endDrag();
                  },
                  child: SimplifiedTaskRow(
                    key: ValueKey('simplified-${task.id}'),
                    task: task,
                  ),
                ),
              );
          }).toList(),
        );
      },
    );
  }

  Future<void> _handleReorder(
    int oldIndex,
    int newIndex,
    List<Task> rootTasks,
  ) async {
    if (oldIndex == newIndex) return;

    // 调整索引（ReorderableListView 的 newIndex 在向下移动时需要调整）
    final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;

    final draggedTask = rootTasks[oldIndex];
    final beforeTask = adjustedNewIndex > 0 ? rootTasks[adjustedNewIndex - 1] : null;
    final afterTask = adjustedNewIndex < rootTasks.length - 1
        ? rootTasks[adjustedNewIndex + 1]
        : null;

    // 使用配置的 handleDueDate 方法确定目标日期
    final targetDate = _config.handleDueDate(
      section: widget.section,
      beforeTask: beforeTask,
      afterTask: afterTask,
      draggedTask: draggedTask,
    );

    // 使用配置的 reorderTasks 方法
    await _config.reorderTasks(
      ref: ref,
      allTasks: rootTasks,
      targetDate: targetDate,
    );
  }
}

