import '../../../core/constants/task_constants.dart';

/// 排序索引计算器
///
/// 提供统一的 sortIndex 计算逻辑，避免硬编码
/// 所有方法都是静态方法，使用统一的 defaultInterval 常量
class SortIndexCalculator {
  /// 默认的排序间隔（用于插入操作）
  static const double defaultInterval = 1000.0;

  /// 插入到最前面
  ///
  /// [firstTaskSortIndex] 第一个任务的 sortIndex（如果列表为空则为 null）
  /// 返回新的 sortIndex
  ///
  /// 示例：
  /// - 如果第一个任务的 sortIndex 是 1000.0，返回 -1000.0
  /// - 如果列表为空（firstTaskSortIndex 为 null），返回 DEFAULT_SORT_INDEX
  static double insertAtFirst(double? firstTaskSortIndex) {
    if (firstTaskSortIndex == null) {
      return TaskConstants.DEFAULT_SORT_INDEX;
    }
    return firstTaskSortIndex - defaultInterval;
  }

  /// 插入到最后面
  ///
  /// [lastTaskSortIndex] 最后一个任务的 sortIndex（如果列表为空则为 null）
  /// 返回新的 sortIndex
  ///
  /// 示例：
  /// - 如果最后一个任务的 sortIndex 是 2000.0，返回 3000.0
  /// - 如果列表为空（lastTaskSortIndex 为 null），返回 DEFAULT_SORT_INDEX
  static double insertAtLast(double? lastTaskSortIndex) {
    if (lastTaskSortIndex == null) {
      return TaskConstants.DEFAULT_SORT_INDEX;
    }
    return lastTaskSortIndex + defaultInterval;
  }

  /// 插入到两个任务之间
  ///
  /// [beforeTaskSortIndex] 前面任务的 sortIndex
  /// [afterTaskSortIndex] 后面任务的 sortIndex
  /// 返回新的 sortIndex
  ///
  /// 示例：
  /// - 如果 beforeTask.sortIndex 是 1000.0，afterTask.sortIndex 是 2000.0，返回 1500.0
  static double insertBetween(
    double beforeTaskSortIndex,
    double afterTaskSortIndex,
  ) {
    return (beforeTaskSortIndex + afterTaskSortIndex) / 2;
  }

  /// 插入到任务之后
  ///
  /// [taskSortIndex] 任务的 sortIndex
  /// 返回新的 sortIndex
  ///
  /// 示例：
  /// - 如果任务的 sortIndex 是 1000.0，返回 2000.0
  static double insertAfter(double taskSortIndex) {
    return taskSortIndex + defaultInterval;
  }

  /// 插入到任务之前
  ///
  /// [taskSortIndex] 任务的 sortIndex
  /// 返回新的 sortIndex
  ///
  /// 示例：
  /// - 如果任务的 sortIndex 是 1000.0，返回 0.0
  static double insertBefore(double taskSortIndex) {
    return taskSortIndex - defaultInterval;
  }
}
