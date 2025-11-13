import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/task.dart';
import '../../widgets/expandable_task_row.dart';
import '../../widgets/dismissible_task_tile.dart';
import '../../widgets/swipe_action_handler.dart';
import '../../widgets/swipe_configs.dart';
import '../../tasks/utils/task_collection_utils.dart';
import '../../tasks/utils/tree_flattening_utils.dart';
import '../../common/task_list/task_list_tree_builder.dart';
import '../../common/task_list/task_list_edge_auto_scroll.dart';
import '../../common/task_list/task_list_insertion_target_builder.dart';
import '../../common/drag/standard_draggable.dart';
import '../../../core/providers/tasks_drag_provider.dart';
import 'milestone_task_list_config.dart';

/// 里程碑任务列表组件（简化版）
///
/// 使用 SimplifiedTaskRow 显示任务，所有任务平铺显示
/// 保留拖拽排序功能，但移除层级结构和展开/收缩功能
/// 支持跨里程碑拖拽
class MilestoneTaskListSimplified extends ConsumerStatefulWidget {
  const MilestoneTaskListSimplified({
    super.key,
    required this.milestoneId,
    required this.tasks,
  });

  final String milestoneId;
  final List<Task> tasks;

  @override
  ConsumerState<MilestoneTaskListSimplified> createState() =>
      _MilestoneTaskListSimplifiedState();
}

class _MilestoneTaskListSimplifiedState
    extends ConsumerState<MilestoneTaskListSimplified> {
  late List<Task> _tasks;
  late MilestoneTaskListConfig _config;

  @override
  void initState() {
    super.initState();
    _tasks = List<Task>.from(widget.tasks);
    _config = MilestoneTaskListConfig(widget.milestoneId);
  }

  @override
  void didUpdateWidget(covariant MilestoneTaskListSimplified oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks != oldWidget.tasks ||
        widget.milestoneId != oldWidget.milestoneId) {
      _tasks = List<Task>.from(widget.tasks);
      _config = MilestoneTaskListConfig(widget.milestoneId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    // 过滤掉 trashed 和 pseudoDeleted 状态的任务
    // 里程碑区域：包含 pending、doing、paused、inbox、completedActive、archived 状态的任务
    final filteredTasks = _tasks.where((task) {
      return task.status != TaskStatus.trashed &&
          task.status != TaskStatus.pseudoDeleted &&
          (task.status == TaskStatus.pending ||
              task.status == TaskStatus.doing ||
              task.status == TaskStatus.paused ||
              task.status == TaskStatus.inbox ||
              task.status == TaskStatus.completedActive ||
              task.status == TaskStatus.archived);
    }).toList();

    // 构建任务层级树（用于获取所有任务，包括子任务）
    final taskTrees = TaskListTreeBuilder.buildTaskTree(filteredTasks);

    // 扁平化所有任务（不根据展开状态，直接平铺所有任务）
    final flattenedTasks = <FlattenedTaskNode>[];
    for (final tree in taskTrees) {
      flattenedTasks.addAll(flattenTree(tree));
    }

    if (flattenedTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    // 按 sortIndex 升序排序（已完成任务的 sortIndex 小于未完成任务的 sortIndex）
    flattenedTasks.sort((a, b) => a.task.sortIndex.compareTo(b.task.sortIndex));

    // 获取根任务列表（用于判断插入目标位置）
    final rootTasks = collectRoots(filteredTasks);
    rootTasks.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    // 创建根任务 ID 集合，用于快速判断任务是否是根任务
    final rootTaskIds = rootTasks.map((task) => task.id).toSet();

    // 获取拖拽状态和 Notifier
    final dragState = ref.watch(tasksDragProvider);
    final dragNotifier = ref.read(tasksDragProvider.notifier);

    // 构建任务列表和插入目标
    final widgets = <Widget>[];

    // 1. 构建顶部插入目标
    widgets.add(
      TaskListInsertionTargetBuilder.buildTopInsertionTarget(
        flattenedTasks: flattenedTasks,
        filteredTasks: filteredTasks,
        config: _config,
        dragState: dragState,
        dragNotifier: dragNotifier,
        ref: ref,
      ),
    );

    // 2. 遍历扁平化任务列表，构建任务卡片和中间插入目标
    for (var index = 0; index < flattenedTasks.length; index++) {
      final flattenedNode = flattenedTasks[index];
      final task = flattenedNode.task;
      final taskLevel = flattenedNode.depth + 1; // depth 从 0 开始，level 从 1 开始
      final isRootTask = rootTaskIds.contains(task.id);

      // 检查是否是正在拖拽的任务
      final isDraggedTask = dragState.draggedTask?.id == task.id && dragState.isDragging;

      // 里程碑区域：左滑移动到今日，右滑归档/删除
      final config = taskLevel > 1
          ? SwipeConfigs.tasksNonTodaySubtaskConfig
          : SwipeConfigs.tasksNonTodayConfig;

      // 构建任务行
      final taskRow = DismissibleTaskTile(
        key: ValueKey('milestone-${task.id}-${task.updatedAt.millisecondsSinceEpoch}'),
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
        child: ExpandableTaskRow(
          key: ValueKey('simplified-${task.id}'),
          task: task,
          section: null, // 里程碑不是基于 section 的
          showCheckbox: true,
          verticalPadding: 4.0,
        ),
      );

      // 只对根任务启用拖拽（子任务不参与排序）
      if (isRootTask) {
        // 根任务：使用 StandardDraggable 包裹
        widgets.add(
          StandardDraggable<Task>(
            key: ValueKey('drag-handler-${task.id}'),
            data: task,
            enabled: true,
            childWhenDraggingOpacity: isDraggedTask ? 0.0 : null,
            onDragStarted: () {
              dragNotifier.startDrag(task, Offset.zero);
            },
            onDragUpdate: (details) {
              dragNotifier.updateDragPosition(details.globalPosition);
              // 边缘自动滚动
              TaskListEdgeAutoScroll.handleEdgeAutoScroll(
                context,
                details.globalPosition,
                _config,
                ref,
              );
            },
            onDragEnd: () {
              dragNotifier.endDrag();
            },
            child: taskRow,
          ),
        );
      } else {
        // 子任务：直接添加，不启用拖拽
        widgets.add(taskRow);
      }

      // 3. 构建中间插入目标（在任务之后）
      // 只在根任务之间添加插入目标（当前任务是根任务，下一个任务也是根任务时）
      if (index + 1 < flattenedTasks.length) {
        final nextTask = flattenedTasks[index + 1].task;
        final isNextRootTask = rootTaskIds.contains(nextTask.id);

        // 只在根任务之间添加插入目标
        if (isRootTask && isNextRootTask) {
          widgets.add(
            TaskListInsertionTargetBuilder.buildMiddleInsertionTarget(
              insertionIndex: index + 1,
              beforeTask: task,
              afterTask: nextTask,
              flattenedTasks: flattenedTasks,
              filteredTasks: filteredTasks,
              config: _config,
              dragState: dragState,
              dragNotifier: dragNotifier,
              ref: ref,
            ),
          );
        }
      }
    }

    // 4. 构建底部插入目标
    if (flattenedTasks.isNotEmpty) {
      widgets.add(
        TaskListInsertionTargetBuilder.buildBottomInsertionTarget(
          flattenedTasks: flattenedTasks,
          filteredTasks: filteredTasks,
          config: _config,
          dragState: dragState,
          dragNotifier: dragNotifier,
          ref: ref,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }
}

