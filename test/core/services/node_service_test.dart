import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/services/node_service.dart';
import 'package:granoflow/data/models/node.dart';
import 'package:granoflow/data/repositories/node_repository.dart';

class MockNodeRepository implements NodeRepository {
  final Map<String, Node> _nodes = {};
  final List<Node> _allNodes = [];

  @override
  Future<Node> createNode({
    required String taskId,
    required String title,
    String? parentId,
    double? sortIndex,
  }) async {
    final node = Node(
      id: 'node-${_nodes.length + 1}',
      taskId: taskId,
      title: title,
      status: NodeStatus.pending,
      sortIndex: sortIndex ?? 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      parentId: parentId,
    );
    _nodes[node.id] = node;
    _allNodes.add(node);
    return node;
  }

  @override
  Future<void> updateNode(
    String nodeId, {
    String? title,
    NodeStatus? status,
    double? sortIndex,
  }) async {
    final node = _nodes[nodeId];
    if (node != null) {
      _nodes[nodeId] = node.copyWith(
        title: title,
        status: status,
        sortIndex: sortIndex,
        updatedAt: DateTime.now(),
      );
      final index = _allNodes.indexWhere((n) => n.id == nodeId);
      if (index != -1) {
        _allNodes[index] = _nodes[nodeId]!;
      }
    }
  }

  @override
  Future<void> deleteNode(String nodeId) async {
    await updateNode(nodeId, status: NodeStatus.deleted);
  }

  @override
  Future<void> deleteNodeWithChildren(String nodeId) async {
    final children = await listChildrenByParentId(nodeId);
    for (final child in children) {
      await deleteNodeWithChildren(child.id);
    }
    await deleteNode(nodeId);
  }

  @override
  Future<void> restoreNode(String nodeId) async {
    await updateNode(nodeId, status: NodeStatus.pending);
  }

  @override
  Future<Node?> findById(String id) async {
    return _nodes[id];
  }

  @override
  Stream<List<Node>> watchNodesByTaskId(String taskId) {
    return Stream.value(
      _allNodes.where((n) => n.taskId == taskId).toList(),
    );
  }

  @override
  Future<List<Node>> listNodesByTaskId(String taskId) async {
    return _allNodes.where((n) => n.taskId == taskId).toList();
  }

  @override
  Future<List<Node>> listChildrenByParentId(String parentId) async {
    return _allNodes
        .where((n) => n.parentId == parentId)
        .toList()
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
  }

  @override
  Future<void> reorderNodes(List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      await updateNode(orderedIds[i], sortIndex: i * 1024.0);
    }
  }

  @override
  Future<void> moveNode(
    String nodeId,
    String? newParentId,
    double newSortIndex,
  ) async {
    final node = _nodes[nodeId];
    if (node != null) {
      _nodes[nodeId] = node.copyWith(
        parentId: newParentId,
        sortIndex: newSortIndex,
        updatedAt: DateTime.now(),
      );
      final index = _allNodes.indexWhere((n) => n.id == nodeId);
      if (index != -1) {
        _allNodes[index] = _nodes[nodeId]!;
      }
    }
  }

  @override
  Future<void> updateNodeStatusWithChildren(String nodeId, NodeStatus status) async {
    // 递归收集所有子节点 ID
    final allNodeIds = <String>[nodeId];
    await _collectChildNodeIds(nodeId, allNodeIds);
    
    // 批量更新所有节点状态
    for (final id in allNodeIds) {
      await updateNode(id, status: status);
    }
  }

  Future<void> _collectChildNodeIds(String parentId, List<String> allNodeIds) async {
    final children = await listChildrenByParentId(parentId);
    for (final child in children) {
      allNodeIds.add(child.id);
      await _collectChildNodeIds(child.id, allNodeIds);
    }
  }

}

void main() {
  group('NodeService', () {
    late MockNodeRepository repository;
    late NodeService service;

    setUp(() {
      repository = MockNodeRepository();
      service = NodeService(nodeRepository: repository);
    });

    group('节点创建', () {
      test('应该能够创建根节点', () async {
        final node = await service.createNode(
          taskId: 'task-1',
          title: 'Root Node',
        );

        expect(node.id, isNotEmpty);
        expect(node.taskId, 'task-1');
        expect(node.title, 'Root Node');
        expect(node.parentId, isNull);
        expect(node.sortIndex, greaterThanOrEqualTo(0.0));
      });

      test('应该能够创建子节点', () async {
        final parent = await service.createNode(
          taskId: 'task-1',
          title: 'Parent',
        );

        final child = await service.createNode(
          taskId: 'task-1',
          title: 'Child',
          parentId: parent.id,
        );

        expect(child.parentId, parent.id);
      });

      test('应该自动计算 sortIndex', () async {
        final node1 = await service.createNode(
          taskId: 'task-1',
          title: 'Node 1',
        );

        final node2 = await service.createNode(
          taskId: 'task-1',
          title: 'Node 2',
        );

        expect(node2.sortIndex, greaterThan(node1.sortIndex));
      });
    });

    group('节点状态管理', () {
      test('应该能够切换节点状态', () async {
        final node = await service.createNode(
          taskId: 'task-1',
          title: 'Test Node',
        );

        await service.updateNodeStatus(node.id, NodeStatus.finished);

        final updated = await repository.findById(node.id);
        expect(updated, isNotNull);
        expect(updated!.status, NodeStatus.finished);
      });

      test('删除节点时应该同时删除子节点', () async {
        final parent = await service.createNode(
          taskId: 'task-1',
          title: 'Parent',
        );

        final child = await service.createNode(
          taskId: 'task-1',
          title: 'Child',
          parentId: parent.id,
        );

        await service.deleteNode(parent.id);

        final deletedParent = await repository.findById(parent.id);
        final deletedChild = await repository.findById(child.id);

        expect(deletedParent, isNotNull);
        expect(deletedParent!.status, NodeStatus.deleted);
        expect(deletedChild, isNotNull);
        expect(deletedChild!.status, NodeStatus.deleted);
      });
    });

    group('节点排序', () {
      test('应该能够重排序同级节点', () async {
        final node1 = await service.createNode(taskId: 'task-1', title: 'Node 1');
        final node2 = await service.createNode(taskId: 'task-1', title: 'Node 2');
        final node3 = await service.createNode(taskId: 'task-1', title: 'Node 3');

        await service.reorderNodes(
          taskId: 'task-1',
          parentId: null,
          orderedIds: [node3.id, node1.id, node2.id],
        );

        final nodes = await repository.listNodesByTaskId('task-1');
        final rootNodes = nodes.where((n) => n.parentId == null).toList();
        rootNodes.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

        expect(rootNodes[0].id, node3.id);
        expect(rootNodes[1].id, node1.id);
        expect(rootNodes[2].id, node2.id);
      });

      test('应该验证节点属于同一父节点', () async {
        final parent1 = await service.createNode(taskId: 'task-1', title: 'Parent 1');
        final parent2 = await service.createNode(taskId: 'task-1', title: 'Parent 2');

        final child1 = await service.createNode(
          taskId: 'task-1',
          title: 'Child 1',
          parentId: parent1.id,
        );

        final child2 = await service.createNode(
          taskId: 'task-1',
          title: 'Child 2',
          parentId: parent2.id,
        );

        expect(
          () => service.reorderNodes(
            taskId: 'task-1',
            parentId: parent1.id,
            orderedIds: [child1.id, child2.id],
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}

