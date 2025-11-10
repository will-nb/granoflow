import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/task.dart';
import '../../tasks/utils/tree_flattening_utils.dart';
import '../../widgets/task_drag_intent_helper.dart';
import '../drag/task_drag_intent_target.dart';
import 'task_list_config.dart';
import 'task_list_expansion_detector.dart';
import 'task_list_edge_auto_scroll.dart';

/// 任务卡片构建工具类
///
/// 职责：构建任务卡片 Widget
/// - 构建任务卡片（带拖拽、展开按钮、层级缩进）
/// - 处理任务卡片的拖拽逻辑
/// - 处理展开/收缩按钮逻辑
class TaskListTaskTileBuilder {
  TaskListTaskTileBuilder._();

  /// 构建任务卡片
  static Widget buildTaskTile({
    required Task task,
    required int depth,
    required double depthPixels,
    required bool isDraggedTask,
    required bool hasChildren,
    required bool isExpanded,
    required int taskLevel,
    required bool isInExpandedArea,
    required List<FlattenedTaskNode> flattenedTasks,
    required List<Task> filteredTasks,
    required List<Task> rootTasks,
    required dynamic dragState,
    required dynamic dragNotifier,
    required TaskListConfig config,
    required WidgetRef ref,
    required Set<String> expandedTaskIds,
    required void Function(Set<String>) onExpandedChanged,
    required void Function(Task task) onDragStarted,
    required void Function(DragUpdateDetails details) onDragUpdate,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return Container(
          padding: EdgeInsets.only(left: depth * depthPixels),
          decoration: isInExpandedArea
              ? BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                )
              : null,
          child: TaskDragIntentTarget.surface(
            key: ValueKey('${config.pageName.toLowerCase()}-${task.id}'),
            meta: TaskDragIntentMeta(
              page: config.pageName,
              targetType: 'taskSurface',
              targetId: task.id,
              targetTaskId: task.id,
              section: config.section?.name,
            ),
            canAccept: (draggedTask, _) =>
                TaskDragIntentHelper.canAcceptAsChild(draggedTask, task),
            onPerform: (draggedTask, ref, context, l10n) async {
              return await TaskDragIntentHelper.handleDropOnTask(
                draggedTask,
                task,
                context,
                ref,
                l10n,
              );
            },
            onHover: (isHovering, _) async {
              if (isHovering) {
                _handleExpansionAreaDetection(
                  dragState: dragState,
                  dragNotifier: dragNotifier,
                  flattenedTasks: flattenedTasks,
                  filteredTasks: filteredTasks,
                  hoveredTaskId: task.id,
                  hoveredInsertionIndex: null,
                );
                  _updateTaskSurfaceHover(dragNotifier, task.id);
                // 边缘自动滚动
                final currentPosition = _getCurrentDragPosition(dragState);
                if (currentPosition != null) {
                  TaskListEdgeAutoScroll.handleEdgeAutoScroll(
                    context,
                    currentPosition,
                    config,
                    ref,
                  );
                }
              } else {
                _clearHover(dragNotifier);
              }
            },
            child: Builder(
              builder: (context) {
                // 构建展开/收缩按钮
                Widget? expandCollapseButton;
                if (hasChildren) {
                  expandCollapseButton = _buildExpandCollapseButton(
                    task: task,
                    isExpanded: isExpanded,
                    taskLevel: taskLevel,
                    rootTasks: rootTasks,
                    config: config,
                    ref: ref,
                      expandedTaskIds: expandedTaskIds,
                    onExpandedChanged: onExpandedChanged,
                  );
                }

                // 构建任务卡片
                return config.buildTaskTile(
                  task: task,
                  key: ValueKey('task-${task.id}'),
                  trailing: expandCollapseButton,
                  childWhenDraggingOpacity: isDraggedTask ? 0.0 : null,
                  taskLevel: taskLevel,
                  onDragStarted: () => onDragStarted(task),
                  onDragUpdate: onDragUpdate,
                  onDragEnd: () {
                    // 拖拽结束处理
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// 构建展开/收缩按钮
  static Widget _buildExpandCollapseButton({
    required Task task,
    required bool isExpanded,
    required int taskLevel,
    required List<Task> rootTasks,
    required TaskListConfig config,
    required WidgetRef ref,
    required Set<String> expandedTaskIds,
    required void Function(Set<String>) onExpandedChanged,
  }) {
    return IconButton(
      icon: Icon(
        isExpanded ? Icons.expand_less : Icons.expand_more,
        size: 20,
      ),
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(),
        onPressed: () {
          final currentExpanded = Set<String>.from(expandedTaskIds);
        // 层级管理规则：展开一个根任务时，其他根任务收缩（Tasks 页面）
        if (!isExpanded && taskLevel == 1 && config.section != null) {
          // Tasks 页面：收缩所有根任务
            final rootTaskIds = rootTasks.map((t) => t.id).toSet();
          currentExpanded.removeAll(rootTaskIds);
          currentExpanded.add(task.id);
        } else {
          // 其他情况：简单的展开/收缩切换
          if (isExpanded) {
            currentExpanded.remove(task.id);
          } else {
            currentExpanded.add(task.id);
          }
        }
        onExpandedChanged(currentExpanded);
      },
    );
  }

  /// 处理扩展区检测
  static void _handleExpansionAreaDetection({
    required dynamic dragState,
    required dynamic dragNotifier,
    required List<FlattenedTaskNode> flattenedTasks,
    required List<Task> filteredTasks,
    required String? hoveredTaskId,
    required int? hoveredInsertionIndex,
  }) {
    final draggedTask = dragState?.draggedTask;
    if (draggedTask == null) return;

    final movedOut = TaskListExpansionDetector.isMovedOutOfExpandedArea(
      draggedTask,
      hoveredTaskId,
      hoveredInsertionIndex,
      flattenedTasks,
      filteredTasks,
    );

    if (movedOut) {
      dragNotifier.setDraggedTaskHidden(true);
      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: movedOutOfExpansion, taskId: ${draggedTask.id}, action: hideFromUI}',
        );
      }
    } else {
      if (dragState.isDraggedTaskHiddenFromExpansion == true) {
        dragNotifier.setDraggedTaskHidden(false);
        if (kDebugMode) {
          debugPrint(
            '[DnD] {event: movedBackToExpansion, taskId: ${draggedTask.id}, action: showInUI}',
          );
        }
      }
    }
  }

  /// 更新任务表面悬停状态
    static void _updateTaskSurfaceHover(dynamic dragNotifier, String taskId) {
    dragNotifier.updateTaskSurfaceHover(taskId);
  }

  /// 清除悬停状态
  static void _clearHover(dynamic dragNotifier) {
    dragNotifier.clearHover();
  }

  /// 获取当前拖拽位置
  static Offset? _getCurrentDragPosition(dynamic dragState) {
    return dragState?.currentDragPosition;
  }
}

