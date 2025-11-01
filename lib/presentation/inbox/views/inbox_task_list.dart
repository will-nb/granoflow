import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/providers/inbox_drag_provider.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../tasks/utils/hierarchy_utils.dart';
import '../../tasks/utils/sort_index_utils.dart';
import '../../tasks/utils/task_collection_utils.dart';
import '../../tasks/utils/tree_flattening_utils.dart';
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

  /// 构建任务层级树
  ///
  /// 从任务列表构建 TaskTreeNode 层级树结构。
  /// 只包含非项目/非里程碑的任务，并按照 sortIndex 排序子任务。
  ///
  /// [tasks] 要构建树的任务列表
  /// 返回根任务树的列表
  List<TaskTreeNode> _buildTaskTree(List<Task> tasks) {
    final byId = {for (final task in tasks) task.id: task};
    final roots = collectRoots(tasks)
        .where((task) => !isProjectOrMilestone(task))
        .toList();
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
    final children = byId.values
        .where((t) => t.parentId == task.id && !isProjectOrMilestone(t))
        .toList()
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    final childNodes = children.map((child) => _buildSubtree(child, byId)).toList();
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
    
    // 计算 before 和 after：目标位置前后任务的 sortIndex
    // 注意：需要考虑被拖拽任务本身，如果 before/after 位置是被拖拽的任务，需要跳过
    
    double? before;
    double? after;
    
    if (insertionIndex <= oldIndex) {
      // 向前移动：targetIndex = insertionIndex
      // before：目标位置之前的任务
      if (targetIndex > 0) {
        final beforeIndex = targetIndex - 1;
        // 如果 before 位置是被拖拽的任务，需要再往前找
        if (beforeIndex == oldIndex) {
          before = beforeIndex > 0 ? rootTasks[beforeIndex - 1].sortIndex : null;
        } else {
          before = rootTasks[beforeIndex].sortIndex;
        }
      } else {
        before = null;
      }
      
      // after：目标位置之后的任务
      if (targetIndex < rootTasks.length - 1) {
        final afterIndex = targetIndex + 1;
        // 如果 after 位置是被拖拽的任务，需要再往后找
        if (afterIndex == oldIndex) {
          after = afterIndex < rootTasks.length - 1
              ? rootTasks[afterIndex + 1].sortIndex
              : null;
        } else {
          after = rootTasks[afterIndex].sortIndex;
        }
      } else {
        after = null;
      }
    } else {
      // 向后移动：targetIndex = insertionIndex - 1
      // before：目标位置之前的任务
      if (targetIndex > 0) {
        final beforeIndex = targetIndex - 1;
        // 如果 before 位置是被拖拽的任务，需要再往前找
        if (beforeIndex == oldIndex) {
          before = beforeIndex > 0 ? rootTasks[beforeIndex - 1].sortIndex : null;
        } else {
          before = rootTasks[beforeIndex].sortIndex;
        }
      } else {
        before = null;
      }
      
      // after：目标位置之后的任务（也就是 insertionIndex 位置的任务）
      if (insertionIndex < rootTasks.length) {
        // insertionIndex 位置的任务（跳过被拖拽的任务）
        if (insertionIndex == oldIndex) {
          // 不应该发生，因为向后移动时 insertionIndex > oldIndex
          after = insertionIndex < rootTasks.length - 1
              ? rootTasks[insertionIndex + 1].sortIndex
              : null;
        } else {
          after = rootTasks[insertionIndex].sortIndex;
        }
      } else {
        after = null; // 插入到末尾
      }
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

    if (flattenedTasks.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // 创建任务 ID 到是否有子任务的映射（用于显示展开/收缩按钮）
    final taskIdToHasChildren = <int, bool>{};
    for (final tree in taskTrees) {
      _populateHasChildrenMap(tree, taskIdToHasChildren, filteredTasks);
    }

    // 获取根任务列表（仅用于排序逻辑和插入目标）
    final rootTasks = collectRoots(filteredTasks)
        .where((task) => !isProjectOrMilestone(task))
        .toList();
    
    // 创建任务映射：任务 ID -> 根任务索引（仅用于根任务）
    final taskIdToIndex = <int, int>{};
    for (var i = 0; i < rootTasks.length; i++) {
      taskIdToIndex[rootTasks[i].id] = i;
    }

    // 标准实现：使用 Column 包裹任务和插入目标
    // 插入目标作为独立的小区域放在任务之间，不覆盖任务表面
    final dragNotifier = ref.read(inboxDragProvider.notifier);
    final dragState = ref.watch(inboxDragProvider);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 列表开头的插入目标（只针对根任务）
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
            return rootTasks.isNotEmpty && 
                   taskIdToIndex.containsKey(draggedTask.id) &&
                   draggedTask.id != rootTasks[0].id;
          },
          onPerform: (draggedTask, ref, context, l10n) async {
            final oldIndex = taskIdToIndex[draggedTask.id];
            if (oldIndex == null) {
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
        // 遍历扁平化的任务列表（包含子任务）
        ...flattenedTasks.asMap().entries.map((entry) {
          final index = entry.key;
          final flattenedNode = entry.value;
          final task = flattenedNode.task;
          final depth = flattenedNode.depth;
          
          // 查找下一个根任务的索引（用于插入目标）
          int? nextRootIndex;
          Task? nextRootTask;
          if (depth == 0) {
            // 当前是根任务，查找下一个根任务
            for (var i = index + 1; i < flattenedTasks.length; i++) {
              if (flattenedTasks[i].depth == 0) {
                nextRootTask = flattenedTasks[i].task;
                nextRootIndex = taskIdToIndex[nextRootTask.id];
                break;
              }
            }
          }
          
          final rootIndex = taskIdToIndex[task.id];
          final isRootTask = rootIndex != null;
          
          return [
            // 任务卡片（带缩进和让位动画）
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              transform: () {
                if (!dragState.isDragging || 
                    dragState.hoveredInsertionIndex == null ||
                    rootIndex == null) {
                  return null;
                }
                return _calculateYieldingTransform(
                  index: rootIndex,
                  draggedTaskIndex: taskIdToIndex[dragState.draggedTask?.id] ?? -1,
                  hoveredInsertionIndex: dragState.hoveredInsertionIndex!,
                  totalTasks: rootTasks.length,
                );
              }(),
              child: Padding(
                padding: EdgeInsets.only(left: depth * 20.0), // 层级缩进：每个层级20px
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
                  child: Builder(
                    builder: (context) {
                      final hasChildren = taskIdToHasChildren[task.id] ?? false;
                      final isExpanded = expandedTaskIds.contains(task.id);
                      
                      // 构建展开/收缩按钮（仅当有子任务时显示）
                      Widget? expandCollapseButton;
                      if (hasChildren) {
                        expandCollapseButton = IconButton(
                          icon: Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 20,
                          ),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            final expandedNotifier = ref.read(inboxExpandedTaskIdProvider.notifier);
                            final currentExpanded = Set<int>.from(expandedNotifier.state);
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
                        onDragStarted: () {
                          dragNotifier.startDrag(task);
                        },
                        onDragEnd: () {
                          dragNotifier.endDrag();
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            // 插入目标（只在根任务之间显示，不包括子任务）
            if (isRootTask && nextRootIndex != null && nextRootTask != null)
              TaskDragIntentTarget.insertion(
                key: ValueKey('inbox-insertion-after-${task.id}'),
                meta: TaskDragIntentMeta(
                  page: 'Inbox',
                  targetType: 'insertionBetween',
                  targetId: nextRootIndex,
                  targetTaskId: nextRootTask.id,
                ),
                insertionType: nextRootIndex == rootTasks.length - 1
                    ? InsertionType.last
                    : InsertionType.between,
                showWhenIdle: false,
                canAccept: (draggedTask, _) {
                  final draggedRootIndex = taskIdToIndex[draggedTask.id];
                  if (draggedRootIndex == null || 
                      draggedTask.id == task.id || 
                      (nextRootTask != null && draggedTask.id == nextRootTask.id)) {
                    return false;
                  }
                  return true;
                },
                onPerform: (draggedTask, ref, context, l10n) async {
                  final oldIndex = taskIdToIndex[draggedTask.id];
                  if (oldIndex == null) {
                    return const TaskDragIntentResult.blocked(
                      blockReasonKey: 'taskMoveBlockedUnknown',
                      blockLogTag: 'taskNotFound',
                    );
                  }
                  await _handleReorder(oldIndex, nextRootIndex!);
                  dragNotifier.endDrag();
                  return const TaskDragIntentResult.success();
                },
                onHover: (isHovering, _) {
                  if (isHovering) {
                    dragNotifier.updateInsertionHover(nextRootIndex!);
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
