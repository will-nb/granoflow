import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/task.dart';
import '../../tasks/utils/tree_flattening_utils.dart';
import 'task_list_config.dart';
import 'task_list_insertion_target_builder.dart';
import 'task_list_task_tile_builder.dart';

/// 任务列表拖拽 UI 构建协调器
///
/// 职责：协调插入目标和任务卡片的构建
/// - 协调 TaskListInsertionTargetBuilder 和 TaskListTaskTileBuilder
/// - 管理构建流程和状态
/// - 通过 TaskListConfig 处理 Inbox 和 Tasks 的差异
class TaskListDragBuilder {
  TaskListDragBuilder._();

  /// 构建任务列表的拖拽 UI（包括插入目标和任务卡片）
  ///
  /// [flattenedTasks] 扁平化任务列表
  /// [rootTasks] 根任务列表
  /// [taskIdToIndex] 任务 ID 到根任务索引的映射
  /// [taskIdToHasChildren] 任务 ID 到是否有子任务的映射
  /// [levelMap] 任务 ID 到层级的映射
  /// [childrenMap] 任务 ID 到子任务 ID 集合的映射
  /// [expandedTaskIds] 已展开的任务 ID 集合
  /// [filteredTasks] 所有任务列表（用于查找父任务）
  /// [config] 任务列表配置
  /// [dragState] 拖拽状态（InboxDragState 或 TasksDragState）
  /// [dragNotifier] 拖拽 Notifier（InboxDragNotifier 或 TasksDragNotifier）
  /// [ref] WidgetRef
  /// [onExpandedChanged] 展开状态变化回调
  /// [onDragStarted] 拖拽开始回调（用于层级管理）
  /// [onDragEnd] 拖拽结束回调
  /// [onDragUpdate] 拖拽更新回调（用于边缘自动滚动）
  /// [depth] 层级缩进（每个层级缩进多少像素，默认 20px）
  static List<Widget> buildTaskListDragUI({
    required List<FlattenedTaskNode> flattenedTasks,
    required List<Task> rootTasks,
    required Map<String, int> taskIdToIndex,
    required Map<String, bool> taskIdToHasChildren,
    required Map<String, int> levelMap,
    required Map<String, Set<String>> childrenMap,
    required Set<String> expandedTaskIds,
    required List<Task> filteredTasks,
    required TaskListConfig config,
    required dynamic dragState,
    required dynamic dragNotifier,
    required WidgetRef ref,
    required void Function(Set<String>) onExpandedChanged,
    required void Function(Task task) onDragStarted,
    required VoidCallback onDragEnd,
    required void Function(DragUpdateDetails details) onDragUpdate,
    double depth = 20.0,
  }) {
    final widgets = <Widget>[];

    // 1. 构建顶部插入目标
    widgets.add(
      TaskListInsertionTargetBuilder.buildTopInsertionTarget(
        flattenedTasks: flattenedTasks,
        filteredTasks: filteredTasks,
        config: config,
        dragState: dragState,
        dragNotifier: dragNotifier,
        ref: ref,
      ),
    );

    // 2. 遍历扁平化任务列表，构建任务卡片和中间插入目标
    for (var index = 0; index < flattenedTasks.length; index++) {
      final flattenedNode = flattenedTasks[index];
      final task = flattenedNode.task;
      final taskDepth = flattenedNode.depth;

      // 查找下一个任务（用于插入目标）
      Task? nextTask;
      int? nextTaskFlattenedIndex;
      if (index + 1 < flattenedTasks.length) {
        nextTask = flattenedTasks[index + 1].task;
        nextTaskFlattenedIndex = index + 1;
      }

      final isDraggedTask = _isDraggingTask(dragState, task);

      // 2.1 构建任务卡片
      widgets.add(
        TaskListTaskTileBuilder.buildTaskTile(
          task: task,
          depth: taskDepth,
          depthPixels: depth,
          isDraggedTask: isDraggedTask,
          hasChildren: taskIdToHasChildren[task.id] ?? false,
          isExpanded: expandedTaskIds.contains(task.id),
          taskLevel: levelMap[task.id] ?? 1,
          isInExpandedArea: task.parentId != null &&
              expandedTaskIds.contains(task.parentId),
          flattenedTasks: flattenedTasks,
          filteredTasks: filteredTasks,
          rootTasks: rootTasks,
          dragState: dragState,
          dragNotifier: dragNotifier,
          config: config,
          ref: ref,
          expandedTaskIds: expandedTaskIds,
          onExpandedChanged: onExpandedChanged,
          onDragStarted: onDragStarted,
          onDragUpdate: onDragUpdate,
        ),
      );

      // 2.2 构建中间插入目标（在任务之后）
      if (nextTask != null) {
        widgets.add(
          TaskListInsertionTargetBuilder.buildMiddleInsertionTarget(
            insertionIndex: nextTaskFlattenedIndex!,
            beforeTask: task,
            afterTask: nextTask,
            flattenedTasks: flattenedTasks,
            filteredTasks: filteredTasks,
            config: config,
            dragState: dragState,
            dragNotifier: dragNotifier,
            ref: ref,
          ),
        );
      }
    }

    // 3. 构建底部插入目标
    if (flattenedTasks.isNotEmpty) {
      widgets.add(
        TaskListInsertionTargetBuilder.buildBottomInsertionTarget(
          flattenedTasks: flattenedTasks,
          filteredTasks: filteredTasks,
          config: config,
          dragState: dragState,
          dragNotifier: dragNotifier,
          ref: ref,
        ),
      );
    }

    return widgets;
  }

  /// 检查任务是否正在被拖拽
  static bool _isDraggingTask(dynamic dragState, Task task) {
    if (dragState == null) return false;
    // 统一访问 draggedTask 属性
    final draggedTask = dragState.draggedTask;
    if (draggedTask == null) return false;
    
    // 检查是否有 isDragging 属性（TasksDragState）
    final isDragging = dragState.isDragging;
    if (isDragging != null) {
      return isDragging == true && draggedTask.id == task.id;
    }
    // InboxDragState 没有 isDragging，直接检查 draggedTask
    return draggedTask.id == task.id;
  }
}

