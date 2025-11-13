import '../models/node.dart';

/// 节点 Repository 接口
abstract class NodeRepository {
  /// 创建节点
  /// 
  /// [taskId] 所属任务 ID
  /// [title] 节点标题
  /// [parentId] 父节点 ID，根节点为 null
  /// [sortIndex] 排序索引，如果为 null 则自动计算
  Future<Node> createNode({
    required String taskId,
    required String title,
    String? parentId,
    double? sortIndex,
  });

  /// 更新节点
  /// 
  /// [nodeId] 节点 ID
  /// [title] 节点标题（可选）
  /// [status] 节点状态（可选）
  /// [sortIndex] 排序索引（可选）
  Future<void> updateNode(
    String nodeId, {
    String? title,
    NodeStatus? status,
    double? sortIndex,
  });

  /// 删除节点（软删除，标记为 deleted 状态）
  /// 
  /// [nodeId] 节点 ID
  Future<void> deleteNode(String nodeId);

  /// 删除节点及其所有子节点（软删除，标记为 deleted 状态）
  /// 
  /// [nodeId] 节点 ID
  Future<void> deleteNodeWithChildren(String nodeId);

  /// 恢复已删除的节点
  /// 
  /// [nodeId] 节点 ID
  Future<void> restoreNode(String nodeId);

  /// 根据 ID 查询节点
  /// 
  /// [id] 节点 ID
  /// 返回节点，如果不存在则返回 null
  Future<Node?> findById(String id);

  /// 监听任务的所有节点
  /// 
  /// [taskId] 任务 ID
  /// 返回 Stream，按 sortIndex 排序
  Stream<List<Node>> watchNodesByTaskId(String taskId);

  /// 查询任务的所有节点
  /// 
  /// [taskId] 任务 ID
  /// 返回节点列表，按 sortIndex 排序
  Future<List<Node>> listNodesByTaskId(String taskId);

  /// 查询子节点
  /// 
  /// [parentId] 父节点 ID
  /// 返回子节点列表，按 sortIndex 排序
  Future<List<Node>> listChildrenByParentId(String parentId);

  /// 批量重排序节点
  /// 
  /// [orderedIds] 已排序的节点 ID 列表
  Future<void> reorderNodes(List<String> orderedIds);

  /// 移动节点到新的父节点
  /// 
  /// [nodeId] 节点 ID
  /// [newParentId] 新的父节点 ID，null 表示移动到根节点
  /// [newSortIndex] 新的排序索引
  Future<void> moveNode(
    String nodeId,
    String? newParentId,
    double newSortIndex,
  );
}

