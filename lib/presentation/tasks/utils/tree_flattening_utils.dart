import '../../../data/models/task.dart';

/// Represents a flattened task node with its depth in the tree.
class FlattenedTaskNode {
  const FlattenedTaskNode(this.task, this.depth);

  final Task task;
  final int depth;
}

/// Flattens a task tree into a list with depth information.
/// 
/// Performs a depth-first traversal of the tree.
/// 
/// [node]: The root node of the tree to flatten
/// [depth]: Starting depth (defaults to 0)
/// [includeRoot]: Whether to include the root node itself (defaults to true)
List<FlattenedTaskNode> flattenTree(
  TaskTreeNode node, {
  int depth = 0,
  bool includeRoot = true,
}) {
  final result = <FlattenedTaskNode>[];
  if (includeRoot) {
    result.add(FlattenedTaskNode(node.task, depth));
  }
  for (final child in node.children) {
    result.addAll(flattenTree(child, depth: depth + 1, includeRoot: true));
  }
  return result;
}

