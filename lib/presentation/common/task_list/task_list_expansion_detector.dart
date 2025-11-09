import '../../../../data/models/task.dart';
import '../../tasks/utils/tree_flattening_utils.dart';

/// 任务列表扩展区检测工具类
///
/// 职责：检测子任务是否移出父任务的扩展区
/// - 用于判断子任务拖拽时是否需要升级为根任务
class TaskListExpansionDetector {
  TaskListExpansionDetector._();

  /// 检查子任务是否移动出父任务的扩展区
  ///
  /// [task] 被拖拽的子任务
  /// [hoveredTaskId] 当前悬停的任务 ID（如果是任务表面）
  /// [hoveredInsertionIndex] 当前悬停的插入位置索引（如果是插入间隔）
  /// [flattenedTasks] 扁平化任务列表
  /// [filteredTasks] 所有任务列表（用于查找父任务）
  /// 返回 true 如果移动出扩展区，应该提升为 level 1
    static bool isMovedOutOfExpandedArea(
      Task task,
      String? hoveredTaskId,
      int? hoveredInsertionIndex,
      List<FlattenedTaskNode> flattenedTasks,
      List<Task> filteredTasks,
    ) {
    if (task.parentId == null) {
      return false; // 根任务不存在扩展区
    }

    // 使用 filteredTasks 查找父任务（数据已在内存中）
    final parentTask = filteredTasks.firstWhere(
      (t) => t.id == task.parentId,
      orElse: () => throw StateError('Parent task not found'),
    );

    // 找到父任务在扁平化列表中的位置索引
    int? parentFlattenedIndex;
    int? lastChildFlattenedIndex;

    for (var i = 0; i < flattenedTasks.length; i++) {
      final flattenedTask = flattenedTasks[i];
      if (flattenedTask.task.id == parentTask.id) {
        parentFlattenedIndex = i;
      }
      // 找到父任务的最后一个子任务
      if (flattenedTask.task.parentId == parentTask.id) {
        lastChildFlattenedIndex = i;
      }
    }

    if (parentFlattenedIndex == null) {
      return false;
    }

    // 如果父任务未展开（没有子任务在扁平化列表中），拖拽目标肯定不在扩展区内
    if (lastChildFlattenedIndex == null) {
      return true;
    }

    // 检查拖拽目标是否在父任务的扩展区内
    // 扩展区范围：parentFlattenedIndex + 1 到 lastChildFlattenedIndex + 1
    // 注意：到达这里时 parentFlattenedIndex 和 lastChildFlattenedIndex 都已确认非 null
    final parentIndex = parentFlattenedIndex;
    final lastChildIndex = lastChildFlattenedIndex;

    if (hoveredTaskId != null) {
      // 拖拽到任务表面：检查该任务是否在扩展区内
      for (var i = parentIndex + 1; i <= lastChildIndex; i++) {
        if (flattenedTasks[i].task.id == hoveredTaskId) {
          return false; // 在扩展区内
        }
      }
      return true; // 不在扩展区内
    }

    if (hoveredInsertionIndex != null) {
      // 拖拽到插入间隔：检查插入位置是否在扩展区内
      // 插入位置在 parentFlattenedIndex + 1 到 lastChildFlattenedIndex + 1 之间，说明在扩展区内
      if (hoveredInsertionIndex > parentIndex &&
          hoveredInsertionIndex <= lastChildIndex + 1) {
        return false; // 在扩展区内
      }
      return true; // 不在扩展区内
    }

    return false;
  }
}

