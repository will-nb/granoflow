import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/inbox_drag_provider.dart';
import '../../../core/constants/task_constants.dart';
import '../../../core/constants/drag_constants.dart';
import '../../../data/models/task.dart';
import '../../tasks/utils/hierarchy_utils.dart';
import '../../tasks/utils/sort_index_calculator.dart';
import '../../tasks/utils/task_collection_utils.dart';
import '../../tasks/utils/tree_flattening_utils.dart';
import '../../../core/services/sort_index_service.dart';
import '../../../core/providers/app_providers.dart';
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
/// - 层级缩进显示（每个层级缩进 16px）
///
/// 使用 [TaskTreeNode] 和 [flattenTree] 构建层级结构，并通过
/// [TaskDragIntentTarget] 处理跨区域拖拽和目标任务识别。
///
/// 注意：
/// - 显示完整的任务层级结构（包括所有子任务）
/// - 排序功能只影响根任务（子任务不参与排序）
/// - 插入目标只在根任务之间显示
/// - 自动过滤掉已删除（trashed）状态的任务
/// - 自动过滤掉项目（project）和里程碑（milestone）类型的任务
class InboxTaskList extends ConsumerStatefulWidget {
  /// 创建 Inbox 任务列表组件
  ///
  /// [tasks] 是要显示的任务列表
  const InboxTaskList({super.key, required this.tasks});

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

  /// 构建任务层级树
  ///
  /// 从任务列表构建 TaskTreeNode 层级树结构。
  /// 只包含非项目/非里程碑的任务，并按照 sortIndex 排序子任务。
  ///
  /// [tasks] 要构建树的任务列表
  /// 返回根任务树的列表
  List<TaskTreeNode> _buildTaskTree(List<Task> tasks) {
    final byId = {for (final task in tasks) task.id: task};
    final roots = collectRoots(
      tasks,
    ).where((task) => !isProjectOrMilestone(task)).toList();
    return roots.map((root) => _buildSubtree(root, byId)).toList();
  }

  /// 递归构建子树
  ///
  /// 为给定任务构建包含所有子任务的子树结构。
  ///
  /// [task] 当前任务
  /// [byId] 任务 ID 到任务的映射
  /// 返回包含当前任务及其所有子任务的树节点
  TaskTreeNode _buildSubtree(Task task, Map<int, Task> byId) {
    final children =
        byId.values
            .where((t) => t.parentId == task.id && !isProjectOrMilestone(t))
            .toList();
    // 使用统一的排序函数：sortIndex升序 → createdAt降序
    SortIndexService.sortChildrenTasks(children);
    final childNodes = children
        .map((child) => _buildSubtree(child, byId))
        .toList();
    return TaskTreeNode(task: task, children: childNodes);
  }

  /// 扁平化任务树，根据展开状态决定是否包含子任务
  ///
  /// 只有当父任务展开时才包含其子任务。
  /// 默认所有任务都是收缩状态（不展开子任务）。
  ///
  /// [node] 要扁平化的树节点
  /// [depth] 当前深度（从0开始）
  /// [expandedTaskIds] 已展开的任务 ID 集合
  /// 返回扁平化的任务节点列表
  List<FlattenedTaskNode> _flattenTreeWithExpansion(
    TaskTreeNode node, {
    int depth = 0,
    required Set<int> expandedTaskIds,
  }) {
    final result = <FlattenedTaskNode>[];
    // 总是包含当前任务
    result.add(FlattenedTaskNode(node.task, depth));

    // 只有当当前任务展开时才包含子任务
    if (expandedTaskIds.contains(node.task.id)) {
      for (final child in node.children) {
        result.addAll(
          _flattenTreeWithExpansion(
            child,
            depth: depth + 1,
            expandedTaskIds: expandedTaskIds,
          ),
        );
      }
    }

    return result;
  }

  /// 填充任务 ID 到是否有子任务的映射
  ///
  /// 递归遍历树，标记每个任务是否有子任务（非项目/非里程碑的子任务）。
  void _populateHasChildrenMap(
    TaskTreeNode node,
    Map<int, bool> map,
    List<Task> allTasks,
  ) {
    // 检查是否有非项目/非里程碑的子任务
    final hasChildren = node.children.isNotEmpty;
    map[node.task.id] = hasChildren;

    // 递归处理子任务
    for (final child in node.children) {
      _populateHasChildrenMap(child, map, allTasks);
    }
  }


  /// 将扁平化列表索引转换为根任务插入索引
  ///
  /// [flattenedIndex] 扁平化列表索引
  /// [flattenedTasks] 扁平化任务列表
  /// [taskIdToIndex] 任务 ID 到根任务索引的映射
  /// [rootTasks] 根任务列表
  /// [filteredTasks] 所有任务列表（用于查找父任务）
  /// 返回根任务插入索引
  int _convertFlattenedIndexToRootInsertionIndex(
    int flattenedIndex,
    List<FlattenedTaskNode> flattenedTasks,
    Map<int, int> taskIdToIndex,
    List<Task> rootTasks,
    List<Task> filteredTasks,
  ) {
    // 特殊情况：顶部插入
    if (flattenedIndex == 0) {
      return 0;
    }

    // 特殊情况：底部插入
    if (flattenedIndex >= flattenedTasks.length) {
      return rootTasks.length;
    }

    // 一般情况：找到对应的任务，然后找到它的根父任务
    final task = flattenedTasks[flattenedIndex].task;
    final rootIndex = taskIdToIndex[task.id];

    if (rootIndex != null) {
      // 如果任务是根任务，返回它的索引
      return rootIndex;
    }

    // 如果是子任务，找到它的根父任务
    // 使用 filteredTasks 查找父任务（数据已在内存中）
    Task? currentTask = task;
    while (currentTask != null && currentTask.parentId != null) {
      final parentId = currentTask.parentId!;
      final parent = filteredTasks.firstWhere(
        (t) => t.id == parentId,
        orElse: () => throw StateError('Parent task not found'),
      );
      final parentRootIndex = taskIdToIndex[parent.id];
      if (parentRootIndex != null) {
        // 找到根父任务，返回它的索引 + 1（插入到它之后）
        return parentRootIndex + 1;
      }
      currentTask = parent;
    }

    // 如果找不到根父任务，返回根任务列表长度（底部插入）
    return rootTasks.length;
  }

  /// 统一处理插入目标的 drop 逻辑
  ///
  /// [draggedTask] 被拖拽的任务
  /// [beforeTask] 插入位置之前的任务（null 表示插入到开头）
  /// [afterTask] 插入位置之后的任务（null 表示插入到结尾）
  /// [targetType] 插入目标类型（first, between, last）
  Future<TaskDragIntentResult> _handleInsertionDrop(
    Task draggedTask,
    Task? beforeTask,
    Task? afterTask,
    String targetType,
    WidgetRef ref,
  ) async {
    // 检查是否是子任务升级为根任务的情况
    final isSubtaskPromotion = draggedTask.parentId != null;
    if (kDebugMode) {
      debugPrint(
        '[DnD] {event: _handleInsertionDrop:start, page: Inbox, src: ${draggedTask.id}, isSubtaskPromotion: $isSubtaskPromotion, originalParentId: ${draggedTask.parentId}, targetType: $targetType, beforeTask: ${beforeTask?.id}, afterTask: ${afterTask?.id}, beforeSortIndex: ${beforeTask?.sortIndex}, afterSortIndex: ${afterTask?.sortIndex}}',
      );
    }
    try {
      final taskHierarchyService = ref.read(taskHierarchyServiceProvider);

      // 确定上方任务的 parentId
      int? aboveTaskParentId;
      double newSortIndex;

      if (targetType == 'first') {
        // 顶部插入目标：成为根项目（parentId = null）
        aboveTaskParentId = null;
        newSortIndex = SortIndexCalculator.insertAtFirst(beforeTask?.sortIndex);
      } else if (targetType == 'last') {
        // 底部插入目标：最后一个任务作为 beforeTask（afterTask = null）
        // 成为最后一个任务的兄弟
        aboveTaskParentId = beforeTask?.parentId;
        newSortIndex = SortIndexCalculator.insertAtLast(beforeTask?.sortIndex);
      } else {
        // 中间插入目标：成为 beforeTask 的兄弟
        aboveTaskParentId = beforeTask?.parentId;
        if (beforeTask != null && afterTask != null) {
          // 两个任务都存在：插入到它们之间
          newSortIndex = SortIndexCalculator.insertBetween(
            beforeTask.sortIndex,
            afterTask.sortIndex,
          );
        } else if (beforeTask != null) {
          // 只有 beforeTask 存在：插入到 beforeTask 之后
          newSortIndex = SortIndexCalculator.insertAfter(beforeTask.sortIndex);
        } else {
          // 两个任务都不存在：使用默认值（这种情况理论上不应该发生）
          newSortIndex = TaskConstants.DEFAULT_SORT_INDEX;
        }
      }

      // 统一使用 moveToParent 处理
      if (kDebugMode) {
        if (isSubtaskPromotion && aboveTaskParentId == null) {
          debugPrint(
            '[DnD] {event: subtaskPromotion, page: Inbox, src: ${draggedTask.id}, originalParentId: ${draggedTask.parentId}, newParentId: null (root), sortIndex: $newSortIndex}',
          );
        }
        debugPrint(
          '[DnD] {event: call:moveToParent, page: Inbox, src: ${draggedTask.id}, parentId: $aboveTaskParentId, sortIndex: $newSortIndex}',
        );
      }

      await taskHierarchyService.moveToParent(
        taskId: draggedTask.id,
        parentId: aboveTaskParentId,
        sortIndex: newSortIndex,
        clearParent: aboveTaskParentId == null, // 只有成为根项目时才 clearParent
      );

      // 批量重排所有inbox任务的sortIndex
      final taskRepository = ref.read(taskRepositoryProvider);
      final sortIndexService = ref.read(sortIndexServiceProvider);
      final allInboxTasks = await taskRepository.watchInbox().first;
      await sortIndexService.reorderTasksForInbox(tasks: allInboxTasks);
      
      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: reorderTasksForInbox:completed, page: Inbox, taskCount: ${allInboxTasks.length}}',
        );
        debugPrint(
          '[DnD] {event: accept:success, page: Inbox, src: ${draggedTask.id}, parentId: $aboveTaskParentId, sortIndex: $newSortIndex}',
        );
      }

      return TaskDragIntentResult.success(
        parentId: aboveTaskParentId,
        sortIndex: newSortIndex,
        clearParent: aboveTaskParentId == null,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: accept:error, page: Inbox, src: ${draggedTask.id}, error: $e, stackTrace: $stackTrace}',
        );
      }
      return const TaskDragIntentResult.blocked(
        blockReasonKey: 'taskMoveBlockedUnknown',
        blockLogTag: 'serviceError',
      );
    }
  }

  /// 检查子任务是否移动出父任务的扩展区
  ///
  /// [task] 被拖拽的子任务
  /// [hoveredTaskId] 当前悬停的任务 ID（如果是任务表面）
  /// [hoveredInsertionIndex] 当前悬停的插入位置索引（如果是插入间隔）
  /// [flattenedTasks] 扁平化任务列表
  /// [filteredTasks] 所有任务列表（用于查找父任务）
  /// 返回 true 如果移动出扩展区，应该提升为 level 1
  bool _isMovedOutOfExpandedArea(
    Task task,
    int? hoveredTaskId,
    int? hoveredInsertionIndex,
    List<FlattenedTaskNode> flattenedTasks,
    List<Task> filteredTasks,
  ) {
    if (task.parentId == null) {
      return false; // 根任务不存在扩展区
    }

    // 使用 filteredTasks 查找父任务（数据已在内存中）
    final parentTask = filteredTasks.firstWhere(
      (t) => t.id == task.parentId,
      orElse: () => throw StateError('Parent task not found'),
    );

    // 找到父任务在扁平化列表中的位置索引
    int? parentFlattenedIndex;
    int? lastChildFlattenedIndex;

    for (var i = 0; i < flattenedTasks.length; i++) {
      final flattenedTask = flattenedTasks[i];
      if (flattenedTask.task.id == parentTask.id) {
        parentFlattenedIndex = i;
      }
      // 找到父任务的最后一个子任务
      if (flattenedTask.task.parentId == parentTask.id) {
        lastChildFlattenedIndex = i;
      }
    }

    if (parentFlattenedIndex == null) {
      return false;
    }

    // 如果父任务未展开（没有子任务在扁平化列表中），拖拽目标肯定不在扩展区内
    if (lastChildFlattenedIndex == null) {
      return true;
    }

    // 检查拖拽目标是否在父任务的扩展区内
    // 扩展区范围：parentFlattenedIndex + 1 到 lastChildFlattenedIndex + 1
    // 注意：到达这里时 parentFlattenedIndex 和 lastChildFlattenedIndex 都已确认非 null
    final parentIndex = parentFlattenedIndex;
    final lastChildIndex = lastChildFlattenedIndex;

    if (hoveredTaskId != null) {
      // 拖拽到任务表面：检查该任务是否在扩展区内
      for (var i = parentIndex + 1; i <= lastChildIndex; i++) {
        if (flattenedTasks[i].task.id == hoveredTaskId) {
          return false; // 在扩展区内
        }
      }
      return true; // 不在扩展区内
    }

    if (hoveredInsertionIndex != null) {
      // 拖拽到插入间隔：检查插入位置是否在扩展区内
      // 插入位置在 parentFlattenedIndex + 1 到 lastChildFlattenedIndex + 1 之间，说明在扩展区内
      if (hoveredInsertionIndex > parentIndex &&
          hoveredInsertionIndex <= lastChildIndex + 1) {
        return false; // 在扩展区内
      }
      return true; // 不在扩展区内
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    // 获取虚拟字段 levelMap 和 childrenMap
    final levelMapAsync = ref.watch(inboxTaskLevelMapProvider);
    final childrenMapAsync = ref.watch(inboxTaskChildrenMapProvider);

    // 使用 AsyncValue.when 处理异步加载
    return levelMapAsync.when(
      data: (levelMap) {
        return childrenMapAsync.when(
          data: (childrenMap) {
            // 过滤掉 trashed 状态的任务
            final filteredTasks = _tasks
                .where((task) => task.status != TaskStatus.trashed)
                .toList();

    // 构建任务层级树
    final taskTrees = _buildTaskTree(filteredTasks);

    // 获取展开状态（默认所有任务都是收缩的）
    final expandedTaskIds = ref.watch(inboxExpandedTaskIdProvider);

    // 扁平化为带深度的任务列表（根据展开状态）
    final flattenedTasks = <FlattenedTaskNode>[];
    for (final tree in taskTrees) {
      flattenedTasks.addAll(
        _flattenTreeWithExpansion(
          tree,
          depth: 0,
          expandedTaskIds: expandedTaskIds,
        ),
      );
    }

    // 子任务拖拽时也采用与根任务相同的策略：保留在 flattenedTasks 中，通过 opacity 控制可见性
    // 这样可以让位动画正常工作，其他任务能够填补空位
    final dragState = ref.watch(inboxDragProvider);

    if (flattenedTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    // 创建任务 ID 到是否有子任务的映射（用于显示展开/收缩按钮）
    final taskIdToHasChildren = <int, bool>{};
    for (final tree in taskTrees) {
      _populateHasChildrenMap(tree, taskIdToHasChildren, filteredTasks);
    }

    // 获取根任务列表（仅用于排序逻辑和插入目标）
    final rootTasks = collectRoots(
      filteredTasks,
    ).where((task) => !isProjectOrMilestone(task)).toList();

    // 创建任务映射：任务 ID -> 根任务索引（仅用于根任务）
    final taskIdToIndex = <int, int>{};
    for (var i = 0; i < rootTasks.length; i++) {
      taskIdToIndex[rootTasks[i].id] = i;
    }

    // 标准实现：使用 Column 包裹任务和插入目标
    // 插入目标作为独立的小区域放在任务之间，不覆盖任务表面
    final dragNotifier = ref.read(inboxDragProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 列表开头的插入目标（支持根任务和子任务）
        TaskDragIntentTarget.insertion(
          key: const ValueKey('inbox-insertion-first'),
          meta: TaskDragIntentMeta(
            page: 'Inbox',
            targetType: 'insertionFirst',
            targetId: 0,
            targetTaskId: flattenedTasks.isNotEmpty
                ? flattenedTasks[0].task.id
                : null,
          ),
          insertionType: InsertionType.first,
          showWhenIdle: false,
          expandedHeight: _calculateInsertionTargetHeight(
            0,
            dragState,
            flattenedTasks,
            taskIdToIndex,
            rootTasks,
            filteredTasks,
          ),
          canAccept: (draggedTask, _) {
            // 统一接受根任务和子任务，都使用"成为兄弟"的逻辑
            final movable = canMoveTask(draggedTask);
            if (flattenedTasks.isEmpty) return false;
            // 不能拖到自己原来的位置
            return movable && draggedTask.id != flattenedTasks[0].task.id;
          },
          onPerform: (draggedTask, ref, context, l10n) async {
            final beforeTask = flattenedTasks.isNotEmpty
                ? flattenedTasks[0].task
                : null;
            final result = await _handleInsertionDrop(
              draggedTask,
              beforeTask,
              null,
              'first',
              ref,
            );
            dragNotifier.endDrag();
            return result;
          },
          onHover: (isHovering, _) async {
            if (isHovering) {
              // 检测是否移出扩展区
              final draggedTask = dragState.draggedTask;
              if (draggedTask != null) {
                final movedOut = _isMovedOutOfExpandedArea(
                  draggedTask,
                  null,
                  0,
                  flattenedTasks,
                  filteredTasks,
                );
                if (movedOut) {
                  // 移出扩展区：只更新UI状态，不修改数据库
                  dragNotifier.setDraggedTaskHidden(true);
                  if (kDebugMode) {
                    debugPrint(
                      '[DnD] {event: movedOutOfExpansion, page: Inbox, taskId: ${draggedTask.id}, action: hideFromUI}',
                    );
                  }
                } else {
                  // 回到扩展区内：恢复显示
                  if (dragState.isDraggedTaskHiddenFromExpansion == true) {
                    dragNotifier.setDraggedTaskHidden(false);
                    if (kDebugMode) {
                      debugPrint(
                        '[DnD] {event: movedBackToExpansion, page: Inbox, taskId: ${draggedTask.id}, action: showInUI}',
                      );
                    }
                  }
                }
              }

              dragNotifier.updateInsertionHover(0);
            }
            // 不在 onLeave 时清除 hover，保持扩展的命中区域有效
            // 这样即使指针稍微移出，插入索引仍保持活跃，直到进入另一个目标或拖拽结束
          },
        ),
        // 遍历扁平化的任务列表（包含子任务）
        ...flattenedTasks
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final flattenedNode = entry.value;
              final task = flattenedNode.task;
              final depth = flattenedNode.depth;

              // 查找下一个任务（用于插入目标，支持根任务和子任务）
              Task? nextTask;
              int? nextTaskFlattenedIndex;
              if (index + 1 < flattenedTasks.length) {
                nextTask = flattenedTasks[index + 1].task;
                nextTaskFlattenedIndex = index + 1;
              }

              final rootIndex = taskIdToIndex[task.id];

              // 检查当前任务是否是被拖拽的任务
              final isDraggedTask =
                  dragState.isDragging && dragState.draggedTask?.id == task.id;

              return [
                // 任务卡片（带缩进和让位动画）
                // 注意：被拖拽任务的隐藏现在由 StandardDraggable 的 childWhenDraggingOpacity 控制
                AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    transform: () {
                      if (!dragState.isDragging ||
                          dragState.hoveredInsertionIndex == null) {
                        return null;
                      }

                      // 使用虚拟字段 levelMap 计算 level
                      final draggedTask = dragState.draggedTask;
                      if (draggedTask == null) {
                        return null;
                      }
                      
                      final draggedTaskLevel = levelMap[draggedTask.id] ?? 1;
                      final draggedTaskParentId = draggedTask.parentId;

                      // 计算当前任务的 level 和 parentId
                      final currentTaskLevel = levelMap[task.id] ?? 1;
                      final currentTaskParentId = task.parentId;

                      // 判断是根任务还是子任务
                      final isRootTask = rootIndex != null;
                      
                      if (isRootTask) {
                        // 根任务：使用根任务索引和转换后的插入索引
                        // rootIndex 在这里肯定不为 null（因为 isRootTask 检查过）
                        
                        // 转换扁平化列表索引为根任务插入索引
                        final rootInsertionIndex =
                            _convertFlattenedIndexToRootInsertionIndex(
                              dragState.hoveredInsertionIndex!,
                              flattenedTasks,
                              taskIdToIndex,
                              rootTasks,
                              filteredTasks,
                            );

                        return _calculateYieldingTransform(
                          index: rootIndex,
                          draggedTaskIndex:
                              taskIdToIndex[draggedTask.id] ?? -1,
                          hoveredInsertionIndex: rootInsertionIndex,
                          totalTasks: rootTasks.length,
                          draggedTaskLevel: draggedTaskLevel,
                          currentTaskLevel: currentTaskLevel,
                          draggedTaskParentId: draggedTaskParentId,
                          currentTaskParentId: currentTaskParentId,
                        );
                      } else {
                        // 子任务：使用扁平化列表索引
                        // 查找被拖拽子任务在 flattenedTasks 中的原始位置
                        int draggedTaskFlattenedIndex = -1;
                        for (var i = 0; i < flattenedTasks.length; i++) {
                          if (flattenedTasks[i].task.id == draggedTask.id) {
                            draggedTaskFlattenedIndex = i;
                            break;
                          }
                        }
                        
                        if (draggedTaskFlattenedIndex == -1) {
                          return null;
                        }

                        // 对于子任务，直接使用 flattenedIndex
                        return _calculateYieldingTransform(
                          index: index,
                          draggedTaskIndex: draggedTaskFlattenedIndex,
                          hoveredInsertionIndex: dragState.hoveredInsertionIndex!,
                          totalTasks: flattenedTasks.length,
                          draggedTaskLevel: draggedTaskLevel,
                          currentTaskLevel: currentTaskLevel,
                          draggedTaskParentId: draggedTaskParentId,
                          currentTaskParentId: currentTaskParentId,
                        );
                      }
                    }(),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: depth * 20.0,
                      ), // 层级缩进：每个层级20px
                      child: TaskDragIntentTarget.surface(
                        key: ValueKey('inbox-${task.id}'),
                        meta: TaskDragIntentMeta(
                          page: 'Inbox',
                          targetType: 'taskSurface',
                          targetId: task.id,
                          targetTaskId: task.id,
                        ),
                        canAccept: (draggedTask, _) =>
                            TaskDragIntentHelper.canAcceptAsChild(
                              draggedTask,
                              task,
                            ),
                        onPerform: (draggedTask, ref, context, l10n) async {
                          final result =
                              await TaskDragIntentHelper.handleDropOnTask(
                                draggedTask,
                                task,
                                context,
                                ref,
                                l10n,
                              );
                          return result;
                        },
                        onHover: (isHovering, _) async {
                          if (isHovering) {
                            // 检测是否移出扩展区
                            final draggedTask = dragState.draggedTask;
                            if (draggedTask != null) {
                              final movedOut = _isMovedOutOfExpandedArea(
                                draggedTask,
                                task.id,
                                null,
                                flattenedTasks,
                                filteredTasks,
                              );
                              if (movedOut) {
                                // 移出扩展区：只更新UI状态，不修改数据库
                                dragNotifier.setDraggedTaskHidden(true);
                                if (kDebugMode) {
                                  debugPrint(
                                    '[DnD] {event: movedOutOfExpansion, page: Inbox, taskId: ${draggedTask.id}, action: hideFromUI}',
                                  );
                                }
                              } else {
                                // 回到扩展区内：恢复显示
                                if (dragState.isDraggedTaskHiddenFromExpansion == true) {
                                  dragNotifier.setDraggedTaskHidden(false);
                                  if (kDebugMode) {
                                    debugPrint(
                                      '[DnD] {event: movedBackToExpansion, page: Inbox, taskId: ${draggedTask.id}, action: showInUI}',
                                    );
                                  }
                                }
                              }
                            }

                            dragNotifier.updateTaskSurfaceHover(task.id);
                          } else {
                            dragNotifier.clearHover();
                          }
                        },
                        child: Builder(
                          builder: (context) {
                            final hasChildren =
                                taskIdToHasChildren[task.id] ?? false;
                            final isExpanded = expandedTaskIds.contains(
                              task.id,
                            );

                            // 构建展开/收缩按钮（仅当有子任务时显示）
                            Widget? expandCollapseButton;
                            if (hasChildren) {
                              expandCollapseButton = IconButton(
                                icon: Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 20,
                                ),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  final expandedNotifier = ref.read(
                                    inboxExpandedTaskIdProvider.notifier,
                                  );
                                  final currentExpanded = Set<int>.from(
                                    expandedNotifier.state,
                                  );
                                  // 如果当前已展开，则从集合中移除；否则添加到集合中
                                  if (isExpanded) {
                                    currentExpanded.remove(task.id);
                                  } else {
                                    currentExpanded.add(task.id);
                                  }
                                  expandedNotifier.state = currentExpanded;
                                },
                              );
                            }

                            return InboxTaskTile(
                              task: task,
                              trailing: expandCollapseButton,
                              childWhenDraggingOpacity: isDraggedTask ? 0.0 : null,
                              onDragStarted: () {
                                // 使用虚拟字段 levelMap 和 childrenMap
                                final taskLevel = levelMap[task.id] ?? 1;

                                // 获取展开状态管理器
                                final expandedNotifier = ref.read(
                                  inboxExpandedTaskIdProvider.notifier,
                                );
                                final currentExpanded = Set<int>.from(
                                  expandedNotifier.state,
                                );

                                if (taskLevel == 1) {
                                  // 根任务：收缩所有子任务
                                  final childTaskIds = childrenMap[task.id] ?? <int>{};
                                  final updatedExpanded = Set<int>.from(
                                    currentExpanded,
                                  );
                                  updatedExpanded.removeAll(childTaskIds);
                                  expandedNotifier.state = updatedExpanded;
                                } else {
                                  // 子任务：检查是否展开
                                  final isExpanded = expandedTaskIds.contains(
                                    task.id,
                                  );
                                  if (!isExpanded) {
                                    // 禁止拖拽未展开的任务
                                    return;
                                  }
                                  // 收缩自己的子任务
                                  final childTaskIds = childrenMap[task.id] ?? <int>{};
                                  final updatedExpanded = Set<int>.from(
                                    currentExpanded,
                                  );
                                  updatedExpanded.removeAll(childTaskIds);
                                  expandedNotifier.state = updatedExpanded;
                                }

                                // 在 onDragStarted 时还没有全局位置，使用 Offset.zero 作为占位符
                                // 实际位置会在第一次 onDragUpdate 时更新
                                dragNotifier.startDrag(task, Offset.zero);
                              },
                              onDragUpdate: (details) {
                                // 更新拖拽位置（全局坐标）
                                dragNotifier.updateDragPosition(
                                  details.globalPosition,
                                );
                              },
                              onDragEnd: () async {
                                if (kDebugMode) {
                                  debugPrint(
                                    '[DnD] {event: onDragEnd:called, taskId: ${task.id}}',
                                  );
                                }
                                
                                // 在 endDrag() 之前立即读取状态，确保获取到最新的偏移量
                                final dragState = ref.read(inboxDragProvider);
                                
                                // 保存偏移量，因为 endDrag() 会清空状态
                                final horizontalOffset = dragState.horizontalOffset;
                                final verticalOffset = dragState.verticalOffset;
                                
                                if (kDebugMode) {
                                  debugPrint(
                                    '[DnD] {event: onDragEnd:stateRead, taskId: ${task.id}, horizontalOffset: $horizontalOffset, verticalOffset: $verticalOffset}',
                                  );
                                }

                                // 使用闭包中捕获的 task 对象，而不是状态中的 draggedTask
                                // 因为状态可能在 onDragEnd 之前被清空
                                final taskService = ref.read(taskServiceProvider);
                                final taskHierarchyService =
                                    ref.read(taskHierarchyServiceProvider);
                                
                                if (kDebugMode) {
                                  debugPrint(
                                    '[DnD] {event: onDragEnd:leftDragPromotion:attempt, taskId: ${task.id}, horizontalOffset: $horizontalOffset, verticalOffset: $verticalOffset}',
                                  );
                                }
                                
                                await taskService.handleLeftDragPromotion(
                                  task.id,
                                  taskHierarchyService,
                                  horizontalOffset: horizontalOffset,
                                  verticalOffset: verticalOffset,
                                );

                                dragNotifier.endDrag();
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                // 插入目标（支持在根任务之间和子任务之间显示）
                if (nextTask != null)
                  TaskDragIntentTarget.insertion(
                    key: ValueKey('inbox-insertion-after-${task.id}'),
                    meta: TaskDragIntentMeta(
                      page: 'Inbox',
                      targetType: 'insertionBetween',
                      targetId: nextTaskFlattenedIndex,
                      targetTaskId: nextTask.id,
                    ),
                    insertionType:
                        (nextTaskFlattenedIndex != null &&
                            nextTaskFlattenedIndex == flattenedTasks.length - 1)
                        ? InsertionType.last
                        : InsertionType.between,
                    showWhenIdle: false,
                    expandedHeight: nextTaskFlattenedIndex != null
                        ? _calculateInsertionTargetHeight(
                            // 底部插入时，使用 flattenedTasks.length 表示插入到最后一个之后
                            (nextTaskFlattenedIndex ==
                                    flattenedTasks.length - 1)
                                ? flattenedTasks.length
                                : nextTaskFlattenedIndex,
                            dragState,
                            flattenedTasks,
                            taskIdToIndex,
                            rootTasks,
                            filteredTasks,
                          )
                        : null,
                    canAccept: (draggedTask, _) {
                      // 统一接受根任务和子任务，都使用"成为兄弟"的逻辑
                      final movable = canMoveTask(draggedTask);
                      // 不能拖到自己原来的位置
                      if (draggedTask.id == task.id ||
                          (nextTask != null && draggedTask.id == nextTask.id)) {
                        return false;
                      }
                      return movable;
                    },
                    onPerform: (draggedTask, ref, context, l10n) async {
                      final targetType =
                          (nextTaskFlattenedIndex != null &&
                              nextTaskFlattenedIndex ==
                                  flattenedTasks.length - 1)
                          ? 'last'
                          : 'between';
                      final result = await _handleInsertionDrop(
                        draggedTask,
                        task,
                        nextTask,
                        targetType,
                        ref,
                      );
                      dragNotifier.endDrag();
                      return result;
                    },
                    onHover: (isHovering, _) async {
                      if (isHovering) {
                        // 底部插入时，使用 flattenedTasks.length 表示插入到最后一个之后
                        final insertionIndex =
                            (nextTaskFlattenedIndex != null &&
                                nextTaskFlattenedIndex ==
                                    flattenedTasks.length - 1)
                            ? flattenedTasks.length
                            : nextTaskFlattenedIndex;

                        // 检测是否移出扩展区
                        final draggedTask = dragState.draggedTask;
                        if (draggedTask != null) {
                          final movedOut = _isMovedOutOfExpandedArea(
                            draggedTask,
                            null,
                            insertionIndex,
                            flattenedTasks,
                            filteredTasks,
                          );
                          if (movedOut) {
                            // 移出扩展区：只更新UI状态，不修改数据库
                            dragNotifier.setDraggedTaskHidden(true);
                            if (kDebugMode) {
                              debugPrint(
                                '[DnD] {event: movedOutOfExpansion, page: Inbox, taskId: ${draggedTask.id}, action: hideFromUI}',
                              );
                            }
                          } else {
                            // 回到扩展区内：恢复显示
                            if (dragState.isDraggedTaskHiddenFromExpansion == true) {
                              dragNotifier.setDraggedTaskHidden(false);
                              if (kDebugMode) {
                                debugPrint(
                                  '[DnD] {event: movedBackToExpansion, page: Inbox, taskId: ${draggedTask.id}, action: showInUI}',
                                );
                              }
                            }
                          }
                        }

                        dragNotifier.updateInsertionHover(insertionIndex);
                      }
                      // 不在 onLeave 时清除 hover，保持扩展的命中区域有效
                      // 这样即使指针稍微移出，插入索引仍保持活跃，直到进入另一个目标或拖拽结束
                    },
                  ),
              ];
            })
            .expand((widgets) => widgets),
          ],
        );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) {
            debugPrint('Error loading children map: $error');
            return const SizedBox.shrink();
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        debugPrint('Error loading level map: $error');
        return const SizedBox.shrink();
      },
    );
  }

  /// 计算插入目标的动态高度
  ///
  /// 按照 Flutter ReorderableListView 的标准实现：
  /// - 当插入位置有让位动画时，返回 taskHeight，覆盖整个让出的空间
  /// - 否则返回 null，使用默认的 8px 高度
  ///
  /// [flattenedIndex] 插入位置的扁平化列表索引
  /// [dragState] 当前拖拽状态
  /// [flattenedTasks] 扁平化任务列表
  /// [taskIdToIndex] 任务 ID 到根任务索引的映射
  /// [rootTasks] 根任务列表
  /// [filteredTasks] 所有任务列表
  /// 返回动态高度（如果有让位动画）或 null（使用默认高度）
  double? _calculateInsertionTargetHeight(
    int flattenedIndex,
    InboxDragState dragState,
    List<FlattenedTaskNode> flattenedTasks,
    Map<int, int> taskIdToIndex,
    List<Task> rootTasks,
    List<Task> filteredTasks,
  ) {
    // 如果没有拖拽，使用默认高度
    if (!dragState.isDragging || dragState.hoveredInsertionIndex == null) {
      return null;
    }

    // 如果当前插入位置没有被悬停，使用默认高度
    if (dragState.hoveredInsertionIndex != flattenedIndex) {
      return null;
    }

    // 转换扁平化列表索引为根任务插入索引
    final rootInsertionIndex = _convertFlattenedIndexToRootInsertionIndex(
      flattenedIndex,
      flattenedTasks,
      taskIdToIndex,
      rootTasks,
      filteredTasks,
    );

    // 获取被拖拽任务的根任务索引
    final draggedTaskId = dragState.draggedTask?.id;
    if (draggedTaskId == null) {
      return null;
    }
    final draggedTaskIndex = taskIdToIndex[draggedTaskId] ?? -1;

    // 如果被拖拽任务不在根任务列表中，使用默认高度
    if (draggedTaskIndex == -1) {
      return null;
    }

    // 计算原始插入位置
    final originalInsertionIndex = draggedTaskIndex;

    // 如果插入位置等于原始位置或原始位置+1，没有让位动画，使用默认高度
    if (rootInsertionIndex == originalInsertionIndex ||
        rootInsertionIndex == originalInsertionIndex + 1) {
      return null;
    }

    // 有让位动画，返回 taskHeight 覆盖整个让出的空间
    return DragConstants.taskHeight;
  }

  /// 计算让位动画的 Transform
  ///
  /// 参考 Flutter ReorderableListView 的标准让位动画逻辑：
  /// - 只有当插入位置真正改变时才触发让位动画
  /// - 如果插入位置等于原始位置或原始位置+1，不触发让位动画
  /// - 让位动画只在同级任务之间发生（相同 level 和 parentId）
  ///
  /// 统一的让位规则（适用于所有插入位置：顶部、中间、底部）：
  /// - 核心思想：被拖拽的任务被"拾起"后，它的位置会留下一个空行。
  ///   当插入位置改变时，需要让其他任务移动来填补这个空行，并为插入位置腾出空间。
  /// - 当 insertionIndex < draggedTaskIndex：从插入位置到原始位置之间的任务向下移动
  /// - 当 insertionIndex > draggedTaskIndex：从原始位置到插入位置之间的任务向上移动
  ///
  /// [index] 当前任务的索引
  /// [draggedTaskIndex] 被拖拽的任务索引（-1 表示未找到）
  /// [hoveredInsertionIndex] 当前悬停的插入位置索引（插入到这个索引之前，已转换为根任务索引）
  /// [totalTasks] 总任务数
  /// [draggedTaskLevel] 被拖拽任务的层级（1-3，null 表示未知）
  /// [currentTaskLevel] 当前任务的层级（1-3，null 表示未知）
  /// [draggedTaskParentId] 被拖拽任务的父任务 ID（null 表示根任务）
  /// [currentTaskParentId] 当前任务的父任务 ID（null 表示根任务）
  Matrix4? _calculateYieldingTransform({
    required int index,
    required int draggedTaskIndex,
    required int hoveredInsertionIndex,
    required int totalTasks,
    int? draggedTaskLevel,
    int? currentTaskLevel,
    int? draggedTaskParentId,
    int? currentTaskParentId,
  }) {
    // 如果当前任务是正在拖拽的任务，不需要移动
    if (index == draggedTaskIndex || draggedTaskIndex == -1) {
      return null;
    }

    // 层级检查：只有在相同层级之间才发生让位动画
    if (draggedTaskLevel != null && currentTaskLevel != null) {
      if (draggedTaskLevel != currentTaskLevel) {
        return null; // 不同层级，不触发让位动画
      }
    }

    // 对于子任务（level > 1），还需要检查 parentId 是否相同
    if (draggedTaskLevel != null && draggedTaskLevel > 1) {
      if (draggedTaskParentId != currentTaskParentId) {
        return null; // 不同父任务，不触发让位动画
      }
    }

    // 使用统一的任务高度常量
    const taskHeight = DragConstants.taskHeight;

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

    // 统一的让位动画逻辑（适用于所有插入位置：顶部、中间、底部）
    // 根据插入位置和被拖拽任务的原始位置计算
    if (hoveredInsertionIndex < draggedTaskIndex) {
      // 插入位置在被拖拽任务之前：从插入位置到被拖拽任务原始位置之间的任务向下移动
      // 填补被拖拽任务留下的空行，并为插入位置腾出空间
      if (index >= hoveredInsertionIndex && index < draggedTaskIndex) {
        return Matrix4.translationValues(0, taskHeight, 0);
      }
    } else if (hoveredInsertionIndex > draggedTaskIndex) {
      // 插入位置在被拖拽任务之后：从被拖拽任务原始位置到插入位置之间的任务向上移动
      // 填补被拖拽任务留下的空行，并为插入位置腾出空间
      if (index > draggedTaskIndex && index < hoveredInsertionIndex) {
        return Matrix4.translationValues(0, -taskHeight, 0);
      }
    }

    // 其他情况不需要移动
    return null;
  }
}
