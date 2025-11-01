import '../../../data/models/task.dart';
import '../../../core/services/sort_index_service.dart';

/// Collects root tasks from a list of tasks.
/// 
/// Root tasks are those without a parent or whose parent is not in the list.
/// 
/// 排序规则：
/// - 如果输入任务列表包含 dueAt（Tasks 页面），根任务已经由 TaskRepository 按
///   dueAt升序 → sortIndex升序 → createdAt降序 排序，保持原顺序。
/// - 如果输入任务列表不包含 dueAt（Inbox 页面），根任务按 sortIndex升序 → 
///   createdAt降序 排序。
/// 
/// [tasks] 输入的任务列表
/// 返回根任务列表
List<Task> collectRoots(List<Task> tasks) {
  final byId = {for (final task in tasks) task.id: task};
  final roots = <Task>[];
  for (final task in tasks) {
    final parentId = task.parentId;
    if (parentId == null || !byId.containsKey(parentId)) {
      roots.add(task);
    }
  }
  
  // 判断是否需要排序：如果所有任务都没有 dueAt，说明是 Inbox 页面，需要排序
  // 如果部分任务有 dueAt，说明是 Tasks 页面，任务已经由 TaskRepository 排序，保持原顺序
  final hasAnyDueAt = roots.any((task) => task.dueAt != null);
  if (!hasAnyDueAt && roots.isNotEmpty) {
    // Inbox 页面：使用 Inbox 排序规则（sortIndex升序 → createdAt降序）
    SortIndexService.sortTasksForInbox(roots);
  }
  // Tasks 页面：保持原顺序（已经由 TaskRepository 排序）
  
  return roots;
}

