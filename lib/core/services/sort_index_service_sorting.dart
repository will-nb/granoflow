import '../../data/models/task.dart';
import 'sort_index_service_comparators.dart';

/// SortIndexService 排序方法
/// 
/// 包含各种场景下的任务列表排序方法
class SortIndexServiceSorting {
  /// 对任务列表进行排序（Inbox页面）
  ///
  /// [tasks] 要排序的任务列表（会被原地修改）
  static void sortTasksForInbox(List<Task> tasks) {
    tasks.sort(SortIndexServiceComparators.compareTasksForInbox);
  }

  /// 对任务列表进行排序（Tasks页面）
  ///
  /// [tasks] 要排序的任务列表（会被原地修改）
  static void sortTasksForTasksPage(List<Task> tasks) {
    tasks.sort(SortIndexServiceComparators.compareTasksForTasksPage);
  }

  /// 对子任务列表进行排序
  ///
  /// [tasks] 要排序的子任务列表（会被原地修改）
  static void sortChildrenTasks(List<Task> tasks) {
    tasks.sort(SortIndexServiceComparators.compareTasksForChildren);
  }
}

