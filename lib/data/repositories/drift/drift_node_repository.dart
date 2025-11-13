import 'dart:async';

import 'package:drift/drift.dart';

import '../../database/database_adapter.dart';
import '../../drift/database.dart' hide Node;
import '../../drift/database.dart' as drift show Node;
import '../../models/node.dart' as domain;
import '../node_repository.dart';
import '../../../core/utils/id_generator.dart';

/// Drift 版本的 NodeRepository 实现
class DriftNodeRepository implements NodeRepository {
  DriftNodeRepository(this._adapter);

  final DatabaseAdapter _adapter;

  /// 获取 AppDatabase 实例
  AppDatabase get _db => AppDatabase.instance;

  @override
  Future<domain.Node> createNode({
    required String taskId,
    required String title,
    String? parentId,
    double? sortIndex,
  }) async {
    return await _adapter.writeTransaction(() async {
      final now = DateTime.now();
      final nodeId = IdGenerator.generateId();
      
      final entity = drift.Node(
        id: nodeId,
        parentId: parentId,
        taskId: taskId,
        title: title,
        status: domain.NodeStatus.pending,
        sortIndex: sortIndex ?? 0.0,
        createdAt: now,
        updatedAt: now,
      );

      await _db.into(_db.nodes).insert(entity);

      return _toNode(entity);
    });
  }

  @override
  Future<void> updateNode(
    String nodeId, {
    String? title,
    domain.NodeStatus? status,
    double? sortIndex,
  }) async {
    await _adapter.writeTransaction(() async {
      final companion = NodesCompanion(
        id: const Value.absent(),
        title: title != null ? Value(title) : const Value.absent(),
        status: status != null ? Value(status) : const Value.absent(),
        sortIndex: sortIndex != null ? Value(sortIndex) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      );

      await (_db.update(_db.nodes)..where((n) => n.id.equals(nodeId))).write(companion);
    });
  }

  @override
  Future<void> deleteNode(String nodeId) async {
    await updateNode(nodeId, status: domain.NodeStatus.deleted);
  }

  @override
  Future<void> deleteNodeWithChildren(String nodeId) async {
    await _adapter.writeTransaction(() async {
      // 递归查询所有子节点
      final allNodeIds = <String>[nodeId];
      await _collectChildNodeIds(nodeId, allNodeIds);

      // 批量更新所有节点状态为 deleted
      final now = DateTime.now();
      for (final id in allNodeIds) {
        final companion = NodesCompanion(
          id: const Value.absent(),
          status: const Value(domain.NodeStatus.deleted),
          updatedAt: Value(now),
        );
        await (_db.update(_db.nodes)..where((n) => n.id.equals(id))).write(companion);
      }
    });
  }

  /// 递归收集所有子节点 ID
  Future<void> _collectChildNodeIds(String parentId, List<String> result) async {
    final children = await listChildrenByParentId(parentId);
    for (final child in children) {
      result.add(child.id);
      await _collectChildNodeIds(child.id, result);
    }
  }

  @override
  Future<void> restoreNode(String nodeId) async {
    await updateNode(nodeId, status: domain.NodeStatus.pending);
  }

  @override
  Future<domain.Node?> findById(String id) async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.nodes)..where((n) => n.id.equals(id));
      final entity = await query.getSingleOrNull();
      if (entity == null) return null;
      return _toNode(entity);
    });
  }

  @override
  Stream<List<domain.Node>> watchNodesByTaskId(String taskId) {
    final query = _db.select(_db.nodes)
      ..where((n) => n.taskId.equals(taskId))
      ..orderBy([(n) => OrderingTerm(expression: n.sortIndex, mode: OrderingMode.asc)]);
    
    return query.watch().asyncMap((entities) async {
      if (entities.isEmpty) return <domain.Node>[];
      return _toNodes(entities);
    });
  }

  @override
  Future<List<domain.Node>> listNodesByTaskId(String taskId) async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.nodes)
        ..where((n) => n.taskId.equals(taskId))
        ..orderBy([(n) => OrderingTerm(expression: n.sortIndex, mode: OrderingMode.asc)]);
      final entities = await query.get();
      return _toNodes(entities);
    });
  }

  @override
  Future<List<domain.Node>> listChildrenByParentId(String parentId) async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.nodes)
        ..where((n) => n.parentId.equals(parentId))
        ..orderBy([(n) => OrderingTerm(expression: n.sortIndex, mode: OrderingMode.asc)]);
      final entities = await query.get();
      return _toNodes(entities);
    });
  }

  @override
  Future<void> reorderNodes(List<String> orderedIds) async {
    if (orderedIds.isEmpty) return;

    await _adapter.writeTransaction(() async {
      // 批量更新 sortIndex
      final now = DateTime.now();
      for (var i = 0; i < orderedIds.length; i++) {
        final nodeId = orderedIds[i];
        final sortIndex = i * 1024.0; // 使用 1024 作为间隔，便于后续插入
        final companion = NodesCompanion(
          id: const Value.absent(),
          sortIndex: Value(sortIndex),
          updatedAt: Value(now),
        );
        await (_db.update(_db.nodes)..where((n) => n.id.equals(nodeId))).write(companion);
      }
    });
  }

  @override
  Future<void> moveNode(
    String nodeId,
    String? newParentId,
    double newSortIndex,
  ) async {
    await _adapter.writeTransaction(() async {
      final companion = NodesCompanion(
        id: const Value.absent(),
        parentId: Value(newParentId),
        sortIndex: Value(newSortIndex),
        updatedAt: Value(DateTime.now()),
      );

      await (_db.update(_db.nodes)..where((n) => n.id.equals(nodeId))).write(companion);
    });
  }

  /// 将 Drift Node 实体转换为领域模型 Node
  domain.Node _toNode(drift.Node entity) {
    return domain.Node(
      id: entity.id,
      parentId: entity.parentId,
      taskId: entity.taskId,
      title: entity.title,
      status: entity.status,
      sortIndex: entity.sortIndex,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// 批量转换 Drift Node 实体为领域模型 Node
  List<domain.Node> _toNodes(List<drift.Node> entities) {
    return entities.map(_toNode).toList();
  }
}

