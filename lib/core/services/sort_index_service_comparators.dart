import '../../data/models/task.dart';

/// SortIndexService 排序比较函数
/// 
/// 包含各种场景下的任务排序比较逻辑
class SortIndexServiceComparators {
  /// Inbox页面的排序比较函数
  ///
  /// 排序规则：sortIndex升序 → createdAt降序（兜底）
  static int compareTasksForInbox(Task a, Task b) {
    // 1. 按 sortIndex 升序排序
    final sortIndexComparison = a.sortIndex.compareTo(b.sortIndex);
    if (sortIndexComparison != 0) return sortIndexComparison;

    // 2. sortIndex 相同，按 createdAt 降序排序（新任务在前）
    return b.createdAt.compareTo(a.createdAt);
  }

  /// Tasks页面的排序比较函数
  ///
  /// 排序规则：dueAt升序 → sortIndex升序 → createdAt降序（兜底）
  static int compareTasksForTasksPage(Task a, Task b) {
    // 1. 比较 dueAt 的日期部分（忽略时间）
    final aDate = a.dueAt;
    final bDate = b.dueAt;

    if (aDate == null && bDate == null) {
      // 两者都没有 dueAt，按 sortIndex 升序 → createdAt 降序
      final sortIndexComparison = a.sortIndex.compareTo(b.sortIndex);
      if (sortIndexComparison != 0) return sortIndexComparison;
      return b.createdAt.compareTo(a.createdAt);
    }

    if (aDate == null) return 1; // 没有 dueAt 的排在后面
    if (bDate == null) return -1;

    // 提取日期部分（年-月-日，忽略时分秒）
    final aDayOnly = DateTime(aDate.year, aDate.month, aDate.day);
    final bDayOnly = DateTime(bDate.year, bDate.month, bDate.day);

    final dateComparison = aDayOnly.compareTo(bDayOnly);
    if (dateComparison != 0) return dateComparison;

    // 2. 日期相同，按 sortIndex 升序
    final sortIndexComparison = a.sortIndex.compareTo(b.sortIndex);
    if (sortIndexComparison != 0) return sortIndexComparison;

    // 3. sortIndex 也相同，按 createdAt 降序（新任务在前）
    return b.createdAt.compareTo(a.createdAt);
  }

  /// 子任务排序比较函数
  ///
  /// 排序规则：sortIndex升序 → createdAt降序（兜底）
  /// 用于在各自父任务内对子任务进行排序
  static int compareTasksForChildren(Task a, Task b) {
    // 与 Inbox 排序规则相同：sortIndex升序 → createdAt降序
    return compareTasksForInbox(a, b);
  }
}
