import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';

/// TaskCrudService 辅助方法
/// 
/// 包含任务层级和日期处理的辅助方法
class TaskCrudServiceHelpers {
  TaskCrudServiceHelpers({
    required TaskRepository taskRepository,
  }) : _tasks = taskRepository;

  final TaskRepository _tasks;

  /// 层级功能已移除，不再有后代任务
  Future<List<Task>> getAllDescendantTasks(String taskId) async {
    // 层级功能已移除，返回空列表
    return <Task>[];
  }

  /// 标准化截止日期为当天的 23:59:59
  static DateTime normalizeDueDate(DateTime localDate) {
    final converted = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      23,
      59,
      59,
      999,
    );
    return converted;
  }

  /// 比较两个时间点是否相同
  static bool isSameInstant(DateTime? a, DateTime? b) {
    if (a == null && b == null) {
      return true;
    }
    if (a == null || b == null) {
      return false;
    }
    return a.millisecondsSinceEpoch == b.millisecondsSinceEpoch;
  }

  /// 比较两个标签列表是否相等
  static bool areTagsEqual(List<String> tags1, List<String> tags2) {
    if (tags1.length != tags2.length) {
      return false;
    }
    final sorted1 = List<String>.from(tags1)..sort();
    final sorted2 = List<String>.from(tags2)..sort();
    return sorted1.toString() == sorted2.toString();
  }
}

