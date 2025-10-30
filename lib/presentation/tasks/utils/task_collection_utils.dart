import '../../../data/models/task.dart';

/// Collects root tasks from a list of tasks.
/// 
/// Root tasks are those without a parent or whose parent is not in the list.
/// The order of tasks is preserved from the input list (assuming it's already sorted).
List<Task> collectRoots(List<Task> tasks) {
  final byId = {for (final task in tasks) task.id: task};
  final roots = <Task>[];
  for (final task in tasks) {
    final parentId = task.parentId;
    if (parentId == null || !byId.containsKey(parentId)) {
      roots.add(task);
    }
  }
  // 保持与 TaskRepository 一致的排序：dueAt（日期部分）→ sortIndex → createdAt
  // 注意：tasks 已经由 TaskRepository 排序，这里不需要重新排序
  // 但为了防止 Set/Map 操作打乱顺序，我们保持原始顺序
  return roots;
}

