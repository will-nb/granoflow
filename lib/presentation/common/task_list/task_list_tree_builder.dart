import '../../../../data/models/task.dart';
import '../../../../core/services/sort_index_service.dart';
import '../../tasks/utils/task_collection_utils.dart';

/// 任务列表树构建工具类
///
/// 职责：任务层级树的构建
/// - 从任务列表构建 TaskTreeNode 层级树结构
/// - 递归构建子树
/// - 填充子任务映射
class TaskListTreeBuilder {
  TaskListTreeBuilder._();

  /// 构建任务层级树
  ///
  /// 从任务列表构建 TaskTreeNode 层级树结构。
  /// 显示所有根任务（包括关联项目/里程碑的），子任务按照 sortIndex 排序。
  ///
  /// [tasks] 要构建树的任务列表
  /// 返回根任务树的列表
  static List<TaskTreeNode> buildTaskTree(List<Task> tasks) {
    final byId = {for (final task in tasks) task.id: task};
    // 显示所有根任务，包括关联项目/里程碑的根任务
    final roots = collectRoots(tasks);
    return roots.map((root) => buildSubtree(root, byId)).toList();
  }

  /// 递归构建子树
  ///
  /// 为给定任务构建包含所有子任务的子树结构。
  ///
  /// [task] 当前任务
  /// [byId] 任务 ID 到任务的映射
  /// 返回包含当前任务及其所有子任务的树节点
  static TaskTreeNode buildSubtree(Task task, Map<String, Task> byId) {
    // 层级功能已移除，不再有子任务
    return TaskTreeNode(task: task, children: const <TaskTreeNode>[]);
  }

  /// 填充任务 ID 到是否有子任务的映射
  ///
  /// 递归遍历树，标记每个任务是否有子任务（非项目/非里程碑的子任务）。
  ///
  /// [node] 树节点
  /// [map] 输出的映射表（taskId -> hasChildren）
  /// [allTasks] 所有任务列表（目前未使用，保留以兼容现有代码）
  static void populateHasChildrenMap(
    TaskTreeNode node,
      Map<String, bool> map,
    List<Task> allTasks,
  ) {
    // 检查是否有非项目/非里程碑的子任务
    final hasChildren = node.children.isNotEmpty;
    map[node.task.id] = hasChildren;

    // 递归处理子任务
    for (final child in node.children) {
      populateHasChildrenMap(child, map, allTasks);
    }
  }
}

