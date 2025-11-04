import '../../../../data/models/task.dart';
import '../../tasks/utils/tree_flattening_utils.dart';

/// 任务列表扁平化工具类
///
/// 职责：任务树的扁平化处理
/// - 根据展开状态扁平化任务树
class TaskListFlattener {
  TaskListFlattener._();

  /// 扁平化任务树，根据展开状态决定是否包含子任务
  ///
  /// 只有当父任务展开时才包含其子任务。
  /// 默认所有任务都是收缩状态（不展开子任务）。
  ///
  /// [node] 要扁平化的树节点
  /// [depth] 当前深度（从0开始）
  /// [expandedTaskIds] 已展开的任务 ID 集合
  /// 返回扁平化的任务节点列表
  static List<FlattenedTaskNode> flattenTreeWithExpansion(
    TaskTreeNode node, {
    int depth = 0,
    required Set<int> expandedTaskIds,
  }) {
    final result = <FlattenedTaskNode>[];
    // 总是包含当前任务
    result.add(FlattenedTaskNode(node.task, depth));

    // 只有当当前任务展开时才包含子任务
    if (expandedTaskIds.contains(node.task.id)) {
      for (final child in node.children) {
        result.addAll(
          flattenTreeWithExpansion(
            child,
            depth: depth + 1,
            expandedTaskIds: expandedTaskIds,
          ),
        );
      }
    }

    return result;
  }
}

