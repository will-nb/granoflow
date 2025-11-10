import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../../presentation/tasks/utils/hierarchy_utils.dart';

/// TaskCrudService 辅助方法
/// 
/// 包含任务层级和日期处理的辅助方法
class TaskCrudServiceHelpers {
  TaskCrudServiceHelpers({
    required TaskRepository taskRepository,
  }) : _tasks = taskRepository;

  final TaskRepository _tasks;

  /// 递归获取所有后代任务（包括子任务的子任务）。
  Future<List<Task>> getAllDescendantTasks(String taskId) async {
    final result = <Task>[];
    final children = await _tasks.listChildren(taskId);

    // 只处理普通任务，排除 project 和 milestone
    final normalChildren = children.where((t) => !isProjectOrMilestone(t)).toList();

    for (final child in normalChildren) {
      result.add(child);
      // 递归获取子任务的子任务
      final grandchildren = await getAllDescendantTasks(child.id);
      result.addAll(grandchildren);
    }

    return result;
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

