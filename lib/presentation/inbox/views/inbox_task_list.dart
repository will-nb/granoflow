import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/providers/inbox_drag_provider.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../tasks/utils/hierarchy_utils.dart';
import '../../tasks/utils/sort_index_utils.dart';
import '../../tasks/utils/task_collection_utils.dart';
import '../../widgets/task_drag_intent_helper.dart';
import '../../common/drag/task_drag_intent_target.dart';
import '../../common/drag/standard_drag_target.dart';
import '../widgets/inbox_task_tile.dart';

/// Inbox 页面的任务列表组件
///
/// 提供可拖拽排序的任务列表，支持以下功能：
/// - 列表内任务重排序（拖拽改变顺序）
/// - 跨区域拖拽（将任务拖到其他任务上使其成为子任务）
/// - 拖拽时的视觉反馈（倾斜、缩放、阴影效果）
///
/// 使用 [ReorderableListView] 实现列表内排序功能，并通过
/// [TaskDragIntentTarget] 处理跨区域拖拽和目标任务识别。
///
/// 注意：
/// - 只显示根任务（没有父任务的任务）
/// - 自动过滤掉已删除（trashed）状态的任务
/// - 自动过滤掉项目（project）和里程碑（milestone）类型的任务
class InboxTaskList extends ConsumerStatefulWidget {
  /// 创建 Inbox 任务列表组件
  ///
  /// [tasks] 是要显示的任务列表
  const InboxTaskList({
    super.key,
    required this.tasks,
  });

  /// 要显示的任务列表
  final List<Task> tasks;

  @override
  ConsumerState<InboxTaskList> createState() => _InboxTaskListState();
}

class _InboxTaskListState extends ConsumerState<InboxTaskList> {
  /// 内部维护的任务列表副本
  ///
  /// 用于在组件更新时保持列表状态的稳定性
  late List<Task> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = List<Task>.from(widget.tasks);
  }

  @override
  void didUpdateWidget(covariant InboxTaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks != oldWidget.tasks) {
      _tasks = List<Task>.from(widget.tasks);
    }
  }

  /// 处理列表内任务重排序
  ///
  /// 当用户在列表内拖拽任务改变顺序时，计算新的 [sortIndex] 并更新任务。
  ///
  /// 排序逻辑：
  /// 1. 过滤掉已删除状态的任务
  /// 2. 过滤出根任务（非项目、非里程碑）
  /// 3. 根据插入位置计算新的 [sortIndex]
  /// 4. 调用 [TaskService.updateDetails] 更新任务
  ///
  /// 如果更新失败，会显示错误提示。
  ///
  /// [oldIndex] 任务原来的索引位置
  /// [insertionIndex] 插入位置索引（插入到这个索引之前，0 表示插入到开头）
  Future<void> _handleReorder(int oldIndex, int insertionIndex) async {
    if (oldIndex == insertionIndex || (oldIndex + 1 == insertionIndex)) {
      // 如果位置没有改变，不需要更新
      debugPrint('[InboxTaskList] 排序位置未改变: oldIndex=$oldIndex, insertionIndex=$insertionIndex');
      return;
    }

    // 过滤掉 trashed 状态的任务
    final filteredTasks = _tasks.where((task) => task.status != TaskStatus.trashed).toList();
    final rootTasks = collectRoots(filteredTasks)
        .where((task) => !isProjectOrMilestone(task))
        .toList();

    if (oldIndex < 0 || oldIndex >= rootTasks.length) {
      debugPrint('[InboxTaskList] 无效的 oldIndex: $oldIndex (总任务数: ${rootTasks.length})');
      return;
    }

    if (insertionIndex < 0 || insertionIndex > rootTasks.length) {
      debugPrint('[InboxTaskList] 无效的 insertionIndex: $insertionIndex (总任务数: ${rootTasks.length})');
      return;
    }

    // 计算新的 sortIndex
    // insertionIndex 表示插入到这个索引之前
    // 如果 insertionIndex <= oldIndex，说明向前移动，新的位置是 insertionIndex
    // 如果 insertionIndex > oldIndex，说明向后移动，新的位置是 insertionIndex - 1
    final targetIndex = insertionIndex <= oldIndex ? insertionIndex : insertionIndex - 1;
    
    // 确保 targetIndex 在有效范围内
    if (targetIndex < 0 || targetIndex >= rootTasks.length) {
      debugPrint('[InboxTaskList] 无效的 targetIndex: $targetIndex (总任务数: ${rootTasks.length})');
      return;
    }
    
    // 计算 before：目标位置之前的任务的 sortIndex
    final before = targetIndex > 0 ? rootTasks[targetIndex - 1].sortIndex : null;
    
    // 计算 after：目标位置之后的任务的 sortIndex
    // 注意：需要考虑被拖拽任务本身，如果 after 位置是被拖拽的任务，需要跳过
    double? after;
    if (insertionIndex <= oldIndex) {
      // 向前移动：after 应该是 insertionIndex 位置的任务（跳过被拖拽的任务）
      // 如果 insertionIndex < rootTasks.length 且 insertionIndex != oldIndex
      if (insertionIndex < rootTasks.length) {
        if (insertionIndex != oldIndex) {
          after = rootTasks[insertionIndex].sortIndex;
        } else {
          // 如果 insertionIndex == oldIndex，after 应该是 oldIndex + 1 的任务
          after = insertionIndex + 1 < rootTasks.length
              ? rootTasks[insertionIndex + 1].sortIndex
              : null;
        }
      } else {
        after = null; // 插入到末尾
      }
    } else {
      // 向后移动：after 应该是 insertionIndex 位置的任务
      after = insertionIndex < rootTasks.length
          ? rootTasks[insertionIndex].sortIndex
          : null;
    }
    
    final newSortIndex = calculateSortIndex(before, after);
    final task = rootTasks[oldIndex];

    debugPrint('[InboxTaskList] 开始排序: taskId=${task.id}, oldIndex=$oldIndex, insertionIndex=$insertionIndex, targetIndex=$targetIndex, newSortIndex=$newSortIndex');

    final taskService = ref.read(taskServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    try {
      await taskService.updateDetails(
        taskId: task.id,
        payload: TaskUpdate(sortIndex: newSortIndex),
      );
      debugPrint('[InboxTaskList] 排序成功: taskId=${task.id}, newSortIndex=$newSortIndex');
    } catch (error, stackTrace) {
      debugPrint('[InboxTaskList] 排序失败: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.taskListSortError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    // 过滤掉 trashed 状态的任务
    final filteredTasks = _tasks.where((task) => task.status != TaskStatus.trashed).toList();

    // 过滤出根任务
    final rootTasks = collectRoots(filteredTasks)
        .where((task) => !isProjectOrMilestone(task))
        .toList();

    if (rootTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    // 标准实现：使用 Column 包裹任务和插入目标
    // 插入目标作为独立的小区域放在任务之间，不覆盖任务表面
    final dragNotifier = ref.read(inboxDragProvider.notifier);
    final dragState = ref.watch(inboxDragProvider);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 列表开头的插入目标
        TaskDragIntentTarget.insertion(
          key: const ValueKey('inbox-insertion-first'),
          meta: TaskDragIntentMeta(
            page: 'Inbox',
            targetType: 'insertionFirst',
            targetId: 0,
            targetTaskId: rootTasks.isNotEmpty ? rootTasks[0].id : null,
          ),
          insertionType: InsertionType.first,
          showWhenIdle: false,
          canAccept: (draggedTask, _) {
            return rootTasks.isNotEmpty && draggedTask.id != rootTasks[0].id;
          },
          onPerform: (draggedTask, ref, context, l10n) async {
            final oldIndex = rootTasks.indexWhere((t) => t.id == draggedTask.id);
            if (oldIndex == -1) {
              return const TaskDragIntentResult.blocked(
                blockReasonKey: 'taskMoveBlockedUnknown',
                blockLogTag: 'taskNotFound',
              );
            }
            await _handleReorder(oldIndex, 0);
            dragNotifier.endDrag();
            return const TaskDragIntentResult.success();
          },
          onHover: (isHovering, _) {
            if (isHovering) {
              dragNotifier.updateInsertionHover(0);
            } else {
              dragNotifier.clearHover();
            }
          },
        ),
        // 遍历任务，每个任务后面跟一个插入目标
        ...rootTasks.asMap().entries.map((entry) {
          final index = entry.key;
          final task = entry.value;
          final afterTask = index < rootTasks.length - 1 ? rootTasks[index + 1] : null;
          
          return [
            // 任务卡片（带让位动画）
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              transform: dragState.isDragging && dragState.hoveredInsertionIndex != null
                  ? _calculateYieldingTransform(
                      index: index,
                      draggedTaskIndex: rootTasks.indexWhere((t) => t.id == dragState.draggedTask?.id),
                      hoveredInsertionIndex: dragState.hoveredInsertionIndex!,
                      totalTasks: rootTasks.length,
                    )
                  : null,
              child: TaskDragIntentTarget.surface(
                key: ValueKey('inbox-${task.id}'),
                meta: TaskDragIntentMeta(
                  page: 'Inbox',
                  targetType: 'taskSurface',
                  targetId: task.id,
                  targetTaskId: task.id,
                ),
                canAccept: (draggedTask, _) =>
                    TaskDragIntentHelper.canAcceptAsChild(draggedTask, task),
                onPerform: (draggedTask, ref, context, l10n) async {
                  final result = await TaskDragIntentHelper.handleDropOnTask(
                    draggedTask,
                    task,
                    context,
                    ref,
                    l10n,
                  );
                  return result;
                },
                onHover: (isHovering, _) {
                  if (isHovering) {
                    dragNotifier.updateTaskSurfaceHover(task.id);
                  } else {
                    dragNotifier.clearHover();
                  }
                },
                child: InboxTaskTile(
                  task: task,
                  onDragStarted: () {
                    dragNotifier.startDrag(task);
                  },
                  onDragEnd: () {
                    dragNotifier.endDrag();
                  },
                ),
              ),
            ),
            // 任务后的插入目标（最后一个任务后是 last 类型）
            TaskDragIntentTarget.insertion(
              key: ValueKey('inbox-insertion-after-$index'),
              meta: TaskDragIntentMeta(
                page: 'Inbox',
                targetType: 'insertionBetween',
                targetId: index + 1,
                targetTaskId: afterTask?.id ?? task.id,
              ),
              insertionType: index == rootTasks.length - 1
                  ? InsertionType.last
                  : InsertionType.between,
              showWhenIdle: false,
              canAccept: (draggedTask, _) {
                if (draggedTask.id == task.id || draggedTask.id == afterTask?.id) {
                  return false;
                }
                return true;
              },
              onPerform: (draggedTask, ref, context, l10n) async {
                final oldIndex = rootTasks.indexWhere((t) => t.id == draggedTask.id);
                if (oldIndex == -1) {
                  return const TaskDragIntentResult.blocked(
                    blockReasonKey: 'taskMoveBlockedUnknown',
                    blockLogTag: 'taskNotFound',
                  );
                }
                await _handleReorder(oldIndex, index + 1);
                dragNotifier.endDrag();
                return const TaskDragIntentResult.success();
              },
              onHover: (isHovering, _) {
                if (isHovering) {
                  dragNotifier.updateInsertionHover(index + 1);
                } else {
                  dragNotifier.clearHover();
                }
              },
            ),
          ];
        }).expand((widgets) => widgets),
      ],
    );
  }

  /// 计算让位动画的 Transform
  /// 
  /// 参考 Flutter ReorderableListView 的让位动画逻辑：
  /// - 只有当插入位置真正改变时才触发让位动画
  /// - 如果插入位置等于原始位置或原始位置+1，不触发让位动画
  /// 
  /// 让位规则（参考标准实现）：
  /// - insertionIndex 表示插入到这个索引之前
  /// - 如果 insertionIndex < index：当前任务向下移动（为插入让出空间）
  /// - 如果 insertionIndex == index + 1：不移动（这是任务的原始位置）
  /// - 如果 insertionIndex > index + 1：当前任务向上移动（为插入让出空间）
  /// - 特殊情况：插入位置在最后一个任务之后时，最后一个任务向上移动
  /// 
  /// [index] 当前任务的索引
  /// [draggedTaskIndex] 被拖拽的任务索引（-1 表示未找到）
  /// [hoveredInsertionIndex] 当前悬停的插入位置索引（插入到这个索引之前）
  /// [totalTasks] 总任务数
  Matrix4? _calculateYieldingTransform({
    required int index,
    required int draggedTaskIndex,
    required int hoveredInsertionIndex,
    required int totalTasks,
  }) {
    // 如果当前任务是正在拖拽的任务，不需要移动
    if (index == draggedTaskIndex || draggedTaskIndex == -1) {
      return null;
    }

    // 计算任务高度（假设每个任务大约 60 像素高，包括 padding）
    const taskHeight = 60.0;

    // 参考 Flutter 标准实现：计算被拖拽任务的原始插入位置
    // 如果 draggedTaskIndex 存在，原始插入位置应该是 draggedTaskIndex（未移动时）
    final originalInsertionIndex = draggedTaskIndex;

    // 关键：只有当插入位置真正改变时才触发让位动画
    // 如果插入位置等于原始位置，不触发让位（这是拖拽开始时的状态）
    if (hoveredInsertionIndex == originalInsertionIndex) {
      return null;
    }
    // 如果插入位置等于原始位置+1，也不触发让位（这是任务的原始位置+1）
    if (hoveredInsertionIndex == originalInsertionIndex + 1) {
      return null;
    }

    // 让位动画逻辑（参考 Flutter 标准实现）：
    // 1. 如果插入位置在当前任务之前（insertionIndex < index），当前任务向下移动
    if (hoveredInsertionIndex < index) {
      return Matrix4.translationValues(0, taskHeight, 0);
    }
    
    // 2. 如果插入位置在当前任务之后（insertionIndex > index）
    if (hoveredInsertionIndex > index) {
      // 2.1 特殊情况：如果插入位置在列表末尾（最后一个任务之后）
      if (hoveredInsertionIndex == totalTasks && index == totalTasks - 1) {
        // 最后一个任务向上移动
        return Matrix4.translationValues(0, -taskHeight, 0);
      }
      // 2.2 如果插入位置正好是当前任务的原始位置（index + 1），不移动
      if (hoveredInsertionIndex == index + 1) {
        return null;
      }
      // 2.3 其他情况：插入位置在当前任务之后，当前任务向上移动（为插入让出空间）
      return Matrix4.translationValues(0, -taskHeight, 0);
    }
    
    // 3. 如果插入位置在当前任务开始处（insertionIndex == index）
    if (hoveredInsertionIndex == index) {
      // 只有当被拖拽的任务来自后面时才让位（向上移动）
      if (draggedTaskIndex > index) {
        return Matrix4.translationValues(0, -taskHeight, 0);
      }
      // 如果被拖拽的任务来自前面，已经通过上面的 hoveredInsertionIndex < index 处理了
      return null;
    }

    // 其他情况不需要移动
    return null;
  }
}
