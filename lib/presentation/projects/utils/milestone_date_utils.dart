import '../../../data/models/task.dart';
import '../../../core/services/task_crud_service_helpers.dart';

/// 里程碑日期工具类
///
/// 提供里程碑相关的日期计算功能
class MilestoneDateUtils {
  MilestoneDateUtils._();

  /// 计算里程碑的默认截止日期
  ///
  /// 规则：
  /// - 如果里程碑没有任务，返回明天（23:59:59）
  /// - 如果里程碑有任务，找到最后一个任务（按 dueAt 降序排序，如果没有 dueAt 则按 sortIndex 降序）
  /// - 返回最后一个任务的 dueAt 的第二天（23:59:59）
  /// - 如果最后一个任务没有 dueAt，返回明天
  ///
  /// [tasks] 里程碑的任务列表
  /// 返回标准化后的默认截止日期（23:59:59）
  static DateTime calculateMilestoneDefaultDueDate(List<Task> tasks) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    // 如果任务列表为空，返回明天
    if (tasks.isEmpty) {
      return TaskCrudServiceHelpers.normalizeDueDate(tomorrow);
    }

    // 过滤出有 dueAt 的任务和没有 dueAt 的任务
    final tasksWithDueAt = tasks.where((task) => task.dueAt != null).toList();
    final tasksWithoutDueAt = tasks.where((task) => task.dueAt == null).toList();

    // 如果有有 dueAt 的任务，按 dueAt 降序排序，取第一个
    if (tasksWithDueAt.isNotEmpty) {
      tasksWithDueAt.sort((a, b) {
        // 按 dueAt 降序排序
        return b.dueAt!.compareTo(a.dueAt!);
      });
      final lastTask = tasksWithDueAt.first;
      // 返回最后一个任务的 dueAt 的第二天
      final lastTaskDueAt = lastTask.dueAt!;
      final nextDay = DateTime(
        lastTaskDueAt.year,
        lastTaskDueAt.month,
        lastTaskDueAt.day + 1,
      );
      return TaskCrudServiceHelpers.normalizeDueDate(nextDay);
    }

    // 如果没有有 dueAt 的任务，按 sortIndex 降序排序，取第一个
    if (tasksWithoutDueAt.isNotEmpty) {
      tasksWithoutDueAt.sort((a, b) {
        // 按 sortIndex 降序排序
        return b.sortIndex.compareTo(a.sortIndex);
      });
      // 最后一个任务没有 dueAt，返回明天
      return TaskCrudServiceHelpers.normalizeDueDate(tomorrow);
    }

    // 理论上不应该到达这里，但为了安全起见返回明天
    return TaskCrudServiceHelpers.normalizeDueDate(tomorrow);
  }
}

