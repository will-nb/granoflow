import '../../../data/models/task.dart';
import '../../../core/services/sort_index_service.dart';

/// 层级功能已移除，直接返回所有任务（不再区分根任务和子任务）
/// 
/// 排序规则：
/// - 如果输入任务列表包含 dueAt（Tasks 页面），任务已经由 TaskRepository 按
///   dueAt升序 → sortIndex升序 → createdAt降序 排序，保持原顺序。
/// - 如果输入任务列表不包含 dueAt（Inbox 页面），任务按 sortIndex升序 → 
///   createdAt降序 排序。
/// 
/// [tasks] 输入的任务列表
/// 返回所有任务列表
List<Task> collectRoots(List<Task> tasks) {
  // 层级功能已移除，直接返回所有任务
  final result = List<Task>.from(tasks);
  
  // 判断是否需要排序：如果所有任务都没有 dueAt，说明是 Inbox 页面，需要排序
  // 如果部分任务有 dueAt，说明是 Tasks 页面，任务已经由 TaskRepository 排序，保持原顺序
  final hasAnyDueAt = result.any((task) => task.dueAt != null);
  if (!hasAnyDueAt && result.isNotEmpty) {
    // Inbox 页面：使用 Inbox 排序规则（sortIndex升序 → createdAt降序）
    SortIndexService.sortTasksForInbox(result);
  }
  // Tasks 页面：保持原顺序（已经由 TaskRepository 排序）
  
  return result;
}

