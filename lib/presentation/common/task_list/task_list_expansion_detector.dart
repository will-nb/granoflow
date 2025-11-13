import '../../../../data/models/task.dart';
import '../../tasks/utils/tree_flattening_utils.dart';

/// 任务列表扩展区检测工具类
///
/// 职责：检测子任务是否移出父任务的扩展区
/// - 用于判断子任务拖拽时是否需要升级为根任务
class TaskListExpansionDetector {
  TaskListExpansionDetector._();

  /// 层级功能已移除，不再需要检查扩展区
  static bool isMovedOutOfExpandedArea(
    Task task,
    String? hoveredTaskId,
    int? hoveredInsertionIndex,
    List<FlattenedTaskNode> flattenedTasks,
    List<Task> filteredTasks,
  ) {
    // 层级功能已移除，所有任务都是平级的，不存在扩展区
    return false;
  }
}

