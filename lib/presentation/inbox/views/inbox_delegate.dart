import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../data/models/task.dart';
import '../../common/drag/draggable_list_delegate.dart';
import '../../common/drag/draggable_list_controller.dart';
import '../../tasks/utils/hierarchy_utils.dart';
import '../../tasks/utils/sort_index_utils.dart';
import '../widgets/inbox_task_tile.dart';

/// InboxTaskList 的拖拽行为委托实现
class InboxDelegate extends DraggableListDelegate<Task> {
  final WidgetRef ref;
  final List<Task> allTasks;
  final int? expandedTaskId;
  final Function(int?) onExpansionChanged;
  
  InboxDelegate({
    required this.ref,
    required this.allTasks,
    required this.expandedTaskId,
    required this.onExpansionChanged,
  });
  
  @override
  bool canReorder(Task item, int oldIndex, int newIndex) {
    // 总是允许在收件箱内重排序
    return true;
  }
  
  @override
  Future<void> onReorder(Task item, int oldIndex, int newIndex) async {
    final tasks = ref.read(inboxListControllerProvider).items;
    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    
    final beforeTask = targetIndex > 0 ? tasks[targetIndex - 1] : null;
    final afterTask = targetIndex < tasks.length - 1 ? tasks[targetIndex + 1] : null;
    
    final beforeSortIndex = beforeTask?.sortIndex;
    final afterSortIndex = afterTask?.sortIndex;
    final newSortIndex = calculateSortIndex(beforeSortIndex, afterSortIndex);
    
    final taskService = ref.read(taskServiceProvider);
    
    if (kDebugMode) {
      debugPrint(
        '[DnD] {event: reorder:start, location: inbox, taskId: ${item.id}, '
        'oldIndex: $oldIndex, newIndex: $newIndex, oldSortIndex: ${item.sortIndex}, '
        'newSortIndex: $newSortIndex}',
      );
    }
    
    await taskService.updateDetails(
      taskId: item.id,
      payload: TaskUpdate(sortIndex: newSortIndex),
    );
    
    if (kDebugMode) {
      debugPrint(
        '[DnD] {event: reorder:success, location: inbox, taskId: ${item.id}, '
        'newSortIndex: $newSortIndex}',
      );
    }
  }
  
  @override
  bool canAcceptExternal(Task draggedItem, int targetIndex) {
    // 收件箱可以接受来自其他区域的任务
    return true;
  }
  
  @override
  Future<void> onAcceptExternal(Task draggedItem, int targetIndex) async {
    final tasks = ref.read(inboxListControllerProvider).items;
    final taskService = ref.read(taskServiceProvider);
    
    // 计算新的排序索引
    double newSortIndex;
    if (targetIndex == 0) {
      newSortIndex = tasks.isNotEmpty ? tasks.first.sortIndex - 1000 : 0;
    } else if (targetIndex >= tasks.length) {
      newSortIndex = tasks.isNotEmpty ? tasks.last.sortIndex + 1000 : 0;
    } else {
      final beforeTask = tasks[targetIndex - 1];
      final afterTask = tasks[targetIndex];
      newSortIndex = calculateSortIndex(beforeTask.sortIndex, afterTask.sortIndex);
    }
    
    if (kDebugMode) {
      debugPrint(
        '[DnD] {event: accept:external, location: inbox, '
        'taskId: ${draggedItem.id}, targetIndex: $targetIndex, '
        'newSortIndex: $newSortIndex}',
      );
    }
    
    // 移动到收件箱意味着：状态改为 inbox，清除截止日期，清除父任务
    await taskService.updateDetails(
      taskId: draggedItem.id,
      payload: TaskUpdate(
        sortIndex: newSortIndex,
        status: TaskStatus.inbox,
        dueAt: null,
        parentId: null,
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
        '[DnD] {event: makeChild:start, location: inbox, draggedId: ${draggedItem.id}, '
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
        '[DnD] {event: makeChild:success, location: inbox, draggedId: ${draggedItem.id}, '
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
        '[DnD] {event: promoteToRoot:start, location: inbox, taskId: ${item.id}, '
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
        '[DnD] {event: promoteToRoot:success, location: inbox, taskId: ${item.id}}',
      );
    }
  }
  
  @override
  String getItemId(Task item) => item.id.toString();
  
  @override
  Widget buildItem(BuildContext context, Task item, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Column(
        children: [
          InboxTaskTile(
            task: item,
            leading: const Padding(
              padding: EdgeInsets.only(right: 12, top: 12, bottom: 12),
              child: Icon(Icons.drag_indicator_rounded, size: 20),
            ),
            contentPadding: const EdgeInsets.only(left: 0, right: 16, top: 12, bottom: 12),
          ),
          // TODO: Add expandable children support
        ],
      ),
    );
  }
  
  @override
  Widget? buildPromoteTarget(BuildContext context) {
    // 收件箱不需要提升目标区域，子任务会自动成为根任务
    return null;
  }
}

/// Controller provider for inbox list
final inboxListControllerProvider = ChangeNotifierProvider<DraggableListController<Task>>(
  (ref) => DraggableListController<Task>(),
);
