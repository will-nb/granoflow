import '../../../../data/models/task.dart';
import '../../tasks/utils/tree_flattening_utils.dart';

/// 任务列表插入索引转换工具类
///
/// 职责：插入位置的索引转换和查找
/// - 将扁平化列表索引转换为根任务插入索引
/// - 根据插入索引查找前后任务
class TaskListInsertionIndexConverter {
  TaskListInsertionIndexConverter._();

  /// 将扁平化列表索引转换为根任务插入索引
  ///
  /// [flattenedIndex] 扁平化列表索引
  /// [flattenedTasks] 扁平化任务列表
  /// [taskIdToIndex] 任务 ID 到根任务索引的映射
  /// [rootTasks] 根任务列表
  /// [filteredTasks] 所有任务列表（用于查找父任务）
  /// 返回根任务插入索引
  static int convertFlattenedIndexToRootInsertionIndex(
    int flattenedIndex,
    List<FlattenedTaskNode> flattenedTasks,
    Map<int, int> taskIdToIndex,
    List<Task> rootTasks,
    List<Task> filteredTasks,
  ) {
    // 特殊情况：顶部插入
    if (flattenedIndex == 0) {
      return 0;
    }

    // 特殊情况：底部插入
    if (flattenedIndex >= flattenedTasks.length) {
      return rootTasks.length;
    }

    // 一般情况：找到对应的任务，然后找到它的根父任务
    final task = flattenedTasks[flattenedIndex].task;
    final rootIndex = taskIdToIndex[task.id];

    if (rootIndex != null) {
      // 如果任务是根任务，返回它的索引
      return rootIndex;
    }

    // 如果是子任务，找到它的根父任务
    // 使用 filteredTasks 查找父任务（数据已在内存中）
    Task? currentTask = task;
    while (currentTask != null && currentTask.parentId != null) {
      final parentId = currentTask.parentId!;
      final parent = filteredTasks.firstWhere(
        (t) => t.id == parentId,
        orElse: () => throw StateError('Parent task not found'),
      );
      final parentRootIndex = taskIdToIndex[parent.id];
      if (parentRootIndex != null) {
        // 找到根父任务，返回它的索引 + 1（插入到它之后）
        return parentRootIndex + 1;
      }
      currentTask = parent;
    }

    // 如果找不到根父任务，返回根任务列表长度（底部插入）
    return rootTasks.length;
  }

  /// 从插入索引转换为 beforeTask/afterTask
  ///
  /// [insertionIndex] 插入位置索引（扁平化列表索引）
  /// [flattenedTasks] 扁平化任务列表
  /// [rootTasks] 根任务列表
  /// [taskIdToIndex] 任务 ID 到根任务索引的映射
  /// [filteredTasks] 所有任务列表（用于查找父任务）
  /// 返回包含 beforeTask、afterTask 和 targetType 的记录
  static ({
    Task? beforeTask,
    Task? afterTask,
    String targetType,
  }) findTasksForInsertionIndex(
    int insertionIndex,
    List<FlattenedTaskNode> flattenedTasks,
    List<Task> rootTasks,
    Map<int, int> taskIdToIndex,
    List<Task> filteredTasks,
  ) {
    // 将扁平化列表索引转换为根任务插入索引
    final rootInsertionIndex = convertFlattenedIndexToRootInsertionIndex(
      insertionIndex,
      flattenedTasks,
      taskIdToIndex,
      rootTasks,
      filteredTasks,
    );

    // 根据根任务插入索引确定 beforeTask、afterTask 和 targetType
    if (rootInsertionIndex == 0) {
      // 顶部插入
      return (
        beforeTask: null,
        afterTask: rootTasks.isEmpty ? null : rootTasks.first,
        targetType: 'first',
      );
    } else if (rootInsertionIndex >= rootTasks.length) {
      // 底部插入
      return (
        beforeTask: rootTasks.isEmpty ? null : rootTasks.last,
        afterTask: null,
        targetType: 'last',
      );
    } else {
      // 中间插入
      return (
        beforeTask: rootTasks[rootInsertionIndex - 1],
        afterTask: rootTasks[rootInsertionIndex],
        targetType: 'between',
      );
    }
  }
}

