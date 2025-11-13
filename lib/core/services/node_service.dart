import '../../data/models/node.dart';
import '../../data/repositories/node_repository.dart';
import '../../presentation/tasks/utils/sort_index_calculator.dart';

/// NodeService - 节点业务逻辑服务层
///
/// 封装节点的业务操作，包括：
/// - 节点创建和更新
/// - 节点状态管理
/// - 节点排序和移动
class NodeService {
  NodeService({
    required NodeRepository nodeRepository,
  }) : _repository = nodeRepository;

  final NodeRepository _repository;

  /// 创建节点
  ///
  /// [taskId] 所属任务 ID
  /// [title] 节点标题
  /// [parentId] 父节点 ID，null 表示根节点
  /// 返回创建的节点
  Future<Node> createNode({
    required String taskId,
    required String title,
    String? parentId,
  }) async {
    // 计算默认 sortIndex
    final sortIndex = await calculateDefaultSortIndex(taskId, parentId);
    
    return await _repository.createNode(
      taskId: taskId,
      title: title,
      parentId: parentId,
      sortIndex: sortIndex,
    );
  }

  /// 更新节点标题
  ///
  /// [nodeId] 节点 ID
  /// [title] 新标题
  Future<void> updateNodeTitle(String nodeId, String title) async {
    await _repository.updateNode(nodeId, title: title);
  }

  /// 更新节点状态
  ///
  /// [nodeId] 节点 ID
  /// [status] 新状态
  Future<void> updateNodeStatus(String nodeId, NodeStatus status) async {
    await _repository.updateNode(nodeId, status: status);
  }

  /// 删除节点（软删除，标记为 deleted 状态）
  ///
  /// [nodeId] 节点 ID
  /// 注意：删除节点时，所有子节点也会一起删除
  Future<void> deleteNode(String nodeId) async {
    await _repository.deleteNodeWithChildren(nodeId);
  }

  /// 恢复已删除的节点
  ///
  /// [nodeId] 节点 ID
  Future<void> restoreNode(String nodeId) async {
    await _repository.restoreNode(nodeId);
  }

  /// 批量重排序节点
  ///
  /// [taskId] 任务 ID（用于验证）
  /// [parentId] 父节点 ID，null 表示根节点（用于验证）
  /// [orderedIds] 已排序的节点 ID 列表
  /// 注意：只允许同级节点之间重排序
  Future<void> reorderNodes({
    required String taskId,
    required String? parentId,
    required List<String> orderedIds,
  }) async {
    if (orderedIds.isEmpty) return;

    // 验证所有节点属于同一父节点
    final nodes = await _repository.listNodesByTaskId(taskId);
    final targetNodes = nodes.where((n) => orderedIds.contains(n.id)).toList();
    
    if (targetNodes.isEmpty) {
      throw ArgumentError('No nodes found with the provided IDs');
    }

    // 验证所有节点的 parentId 是否相同
    final firstParentId = targetNodes.first.parentId;
    if (targetNodes.any((n) => n.parentId != firstParentId)) {
      throw ArgumentError('Cannot reorder nodes with different parent IDs');
    }

    if (firstParentId != parentId) {
      throw ArgumentError('Parent ID mismatch');
    }

    // 使用 Repository 的批量重排序方法
    await _repository.reorderNodes(orderedIds);
  }

  /// 移动节点到新的父节点
  ///
  /// [nodeId] 节点 ID
  /// [newParentId] 新的父节点 ID，null 表示移动到根节点
  /// [newSortIndex] 新的排序索引
  Future<void> moveNode(
    String nodeId,
    String? newParentId,
    double newSortIndex,
  ) async {
    await _repository.moveNode(nodeId, newParentId, newSortIndex);
  }

  /// 计算默认 sortIndex
  ///
  /// [taskId] 任务 ID
  /// [parentId] 父节点 ID，null 表示根节点
  /// 返回新的 sortIndex
  Future<double> calculateDefaultSortIndex(String taskId, String? parentId) async {
    // 获取同级节点列表
    final siblings = parentId == null
        ? await _repository.listNodesByTaskId(taskId)
            .then((nodes) => nodes.where((n) => n.parentId == null).toList())
        : await _repository.listChildrenByParentId(parentId);

    // 按 sortIndex 排序
    siblings.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    // 计算最后一个节点的 sortIndex
    final lastSortIndex = siblings.isEmpty ? null : siblings.last.sortIndex;

    // 使用 SortIndexCalculator.insertAtLast 计算新的 sortIndex
    return SortIndexCalculator.insertAtLast(lastSortIndex);
  }
}

