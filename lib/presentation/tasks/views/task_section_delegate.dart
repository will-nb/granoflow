import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/utils/task_section_utils.dart';
import '../../../data/models/task.dart';
import '../../common/drag/draggable_list_delegate.dart';
import '../../common/drag/draggable_list_controller.dart';
import '../../widgets/drag_to_remove_handler.dart';
import '../utils/hierarchy_utils.dart';
import '../utils/sort_index_utils.dart';
import 'task_section_list.dart';

/// TaskSectionList 的拖拽行为委托实现
class TaskSectionDelegate extends DraggableListDelegate<Task> {
  final TaskSection section;
  final WidgetRef ref;
  final Set<int> Function(int index) getDisplayedParentIds;
  final List<Task> tasks;  // Task list for reliable data access
  
  TaskSectionDelegate({
    required this.section,
    required this.ref,
    required this.getDisplayedParentIds,
    required this.tasks,  // Add tasks parameter
  });
  
  @override
  bool canReorder(Task item, int oldIndex, int newIndex) {
    // 总是允许在同一区域内重排序
    return true;
  }
  
  @override
  Future<void> onReorder(Task item, int oldIndex, int newIndex) async {
    // Use the tasks parameter passed to constructor instead of controller.items
    // (same fix as InboxDelegate - controller.items may be empty or stale)
    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    
    if (kDebugMode) {
      debugPrint('[TaskDelegate] onReorder - START');
      debugPrint('  section: ${section.name}');
      debugPrint('  taskId: ${item.id}, title: ${item.title}');
      debugPrint('  oldIndex: $oldIndex, newIndex: $newIndex, targetIndex: $targetIndex');
      debugPrint('  totalTasks: ${tasks.length}');
      
      // 打印周围任务的信息
      if (targetIndex > 0) {
        final beforeTask = tasks[targetIndex - 1];
        debugPrint('  beforeTask: id=${beforeTask.id}, sortIndex=${beforeTask.sortIndex}, dueAt=${beforeTask.dueAt}');
      }
      if (targetIndex < tasks.length - 1) {
        final afterTask = tasks[targetIndex + 1];
        debugPrint('  afterTask: id=${afterTask.id}, sortIndex=${afterTask.sortIndex}, dueAt=${afterTask.dueAt}');
      }
    }
    
    final beforeTask = targetIndex > 0 ? tasks[targetIndex - 1] : null;
    final afterTask = targetIndex < tasks.length - 1 ? tasks[targetIndex + 1] : null;
    
    final beforeSortIndex = beforeTask?.sortIndex;
    final afterSortIndex = afterTask?.sortIndex;
    final newSortIndex = calculateSortIndex(beforeSortIndex, afterSortIndex);
    
    // 计算新的 dueAt：同一区域内，使用相邻任务的 dueAt
    DateTime? newDueAt;
    if (beforeTask != null && beforeTask.dueAt != null) {
      newDueAt = beforeTask.dueAt;
    } else if (afterTask != null && afterTask.dueAt != null) {
      newDueAt = afterTask.dueAt;
    } else {
      newDueAt = item.dueAt;
    }
    
    final taskService = ref.read(taskServiceProvider);
    
    if (kDebugMode) {
      debugPrint(
        '[DnD] {event: reorder:start, section: ${section.name}, taskId: ${item.id}, '
        'oldIndex: $oldIndex, newIndex: $newIndex, oldDueAt: ${item.dueAt}, '
        'newDueAt: $newDueAt, oldSortIndex: ${item.sortIndex}, newSortIndex: $newSortIndex}',
      );
    }
    
    try {
      await taskService.updateDetails(
        taskId: item.id,
        payload: TaskUpdate(sortIndex: newSortIndex, dueAt: newDueAt),
      );
      
      if (kDebugMode) {
        debugPrint('[TaskDelegate] onReorder - SUCCESS');
        debugPrint('  newSortIndex: $newSortIndex, newDueAt: $newDueAt');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TaskDelegate] onReorder - ERROR: $e');
      }
      rethrow;
    }
  }
  
  @override
  bool canAcceptExternal(Task draggedItem, int targetIndex) {
    // 检查是否可以接受来自其他区域的任务
    // 不能拖拽到逾期区域
    if (section == TaskSection.overdue) {
      return false;
    }
    return true;
  }
  
  @override
  Future<void> onAcceptExternal(Task draggedItem, int targetIndex) async {
    // Use the tasks parameter instead of controller.items (same fix as onReorder)
    final taskService = ref.read(taskServiceProvider);
    
    // 计算新的排序索引
    double newSortIndex;
    if (targetIndex == 0) {
      // 插入到最前面
      newSortIndex = tasks.isNotEmpty 
          ? tasks.first.sortIndex - 1000
          : 0;
    } else if (targetIndex >= tasks.length) {
      // 插入到最后面
      newSortIndex = tasks.isNotEmpty
          ? tasks.last.sortIndex + 1000
          : 0;
    } else {
      // 插入到中间
      final beforeTask = tasks[targetIndex - 1];
      final afterTask = tasks[targetIndex];
      newSortIndex = calculateSortIndex(beforeTask.sortIndex, afterTask.sortIndex);
    }
    
    // 计算新的截止日期（根据目标区域）
    final now = DateTime.now();
    DateTime? newDueAt;
    
    if (targetIndex > 0 && targetIndex < tasks.length) {
      // 如果在两个任务之间，使用前一个任务的日期
      newDueAt = tasks[targetIndex - 1].dueAt;
    } else {
      // 否则使用区域的默认日期
      newDueAt = TaskSectionUtils.getSectionEndTime(section, now: now);
    }
    
    if (kDebugMode) {
      debugPrint(
        '[DnD] {event: accept:external, section: ${section.name}, '
        'taskId: ${draggedItem.id}, targetIndex: $targetIndex, '
        'newDueAt: $newDueAt, newSortIndex: $newSortIndex}',
      );
    }
    
    await taskService.updateDetails(
      taskId: draggedItem.id,
      payload: TaskUpdate(
        sortIndex: newSortIndex,
        dueAt: newDueAt,
        status: TaskStatus.pending, // 确保状态正确
      ),
    );
  }
  
  @override
  bool canMakeChild(Task draggedItem, Task targetItem) {
    // 使用现有的层级检查逻辑
    if (draggedItem.id == targetItem.id) return false;
    if (draggedItem.parentId == targetItem.id) return false;
    if (!canAcceptChildren(targetItem)) return false;
    if (!canMoveTask(draggedItem)) return false;
    
    // TODO: 添加循环引用和深度检查
    
    return true;
  }
  
  @override
  Future<void> onMakeChild(Task draggedItem, Task targetItem) async {
    final taskHierarchyService = ref.read(taskHierarchyServiceProvider);
    
    if (kDebugMode) {
      debugPrint(
        '[DnD] {event: makeChild:start, draggedId: ${draggedItem.id}, '
        'targetId: ${targetItem.id}}',
      );
    }
    
    final newSortIndex = await taskHierarchyService
        .calculateSortIndexForNewChild(targetItem.id);
    
    await taskHierarchyService.moveToParent(
      taskId: draggedItem.id,
      parentId: targetItem.id,
      sortIndex: newSortIndex,
    );
    
    if (kDebugMode) {
      debugPrint(
        '[DnD] {event: makeChild:success, draggedId: ${draggedItem.id}, '
        'parentId: ${targetItem.id}}',
      );
    }
  }
  
  @override
  bool canPromoteToRoot(Task item) {
    return item.parentId != null;
  }
  
  @override
  Future<void> onPromoteToRoot(Task item) async {
    final taskHierarchyService = ref.read(taskHierarchyServiceProvider);
    
    if (kDebugMode) {
      debugPrint(
        '[DnD] {event: promoteToRoot:start, taskId: ${item.id}, '
        'oldParentId: ${item.parentId}}',
      );
    }
    
    await taskHierarchyService.moveToParent(
      taskId: item.id,
      parentId: null,
      sortIndex: item.sortIndex,
      clearParent: true,
    );
    
    if (kDebugMode) {
      debugPrint(
        '[DnD] {event: promoteToRoot:success, taskId: ${item.id}}',
      );
    }
  }
  
  @override
  String getItemId(Task item) => item.id.toString();
  
  @override
  Widget buildItem(BuildContext context, Task item, int index, Animation<double> animation) {
    if (kDebugMode) {
      debugPrint('[TaskSectionDelegate] buildItem - section=${section.name}, index=$index, taskId=${item.id}, title=${item.title}');
    }
    return SizeTransition(
      sizeFactor: animation,
      child: TaskWithParentChain(
        section: section,
        task: item,
        displayedParentIds: getDisplayedParentIds(index),
      ),
    );
  }
  
  @override
  Widget? buildPromoteTarget(BuildContext context) {
    // 使用现有的 DragToRemoveHandler 作为提升目标
    return const DragToRemoveHandler();
  }
}

/// Controller provider for task section lists
final taskSectionListControllerProvider = ChangeNotifierProvider.family<DraggableListController<Task>, TaskSection>(
  (ref, section) => DraggableListController<Task>(),
);
