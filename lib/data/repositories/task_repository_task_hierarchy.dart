part of 'task_repository.dart';

/// TaskRepository 任务层级相关方法 mixin
/// 
/// 包含任务树构建、子任务状态同步等层级相关方法
/// 
/// 依赖：
/// - TaskRepositoryHelpers: 提供基础辅助方法
mixin TaskRepositoryTaskHierarchy on TaskRepositoryHelpers {
  /// 构建任务树
  Future<TaskTreeNode> _buildTree(int rootTaskId) async {
    final entity = await _isar.taskEntitys.get(rootTaskId);
    if (entity == null) {
      throw StateError('Task $rootTaskId not found');
    }
    final children = await _isar.taskEntitys
        .filter()
        .parentIdEqualTo(rootTaskId)
        .sortBySortIndex()
        .findAll();
    final nodes = await Future.wait(
      children.map((child) => _buildTree(child.id)),
    );
    return TaskTreeNode(task: _toDomain(entity), children: nodes);
  }

  /// 递归获取所有后代任务（包括 trashed 状态）
  /// 
  /// [parentId] 父任务 ID
  /// 返回所有后代任务的列表（包括 trashed 状态，排除里程碑）
  /// 
  /// 注意：此方法需要访问 listChildrenIncludingTrashed，它来自 TaskRepositoryQueries
  Future<List<Task>> _getAllDescendantsIncludingTrashed(int parentId) async {
    final result = <Task>[];
    // 直接查询数据库，避免依赖 Queries mixin 的方法（解决循环依赖）
    final childrenEntities = await _isar.taskEntitys
        .filter()
        .parentIdEqualTo(parentId)
        .sortBySortIndex()
        .thenByCreatedAtDesc()
        .findAll();
    // 只排除里程碑（里程碑只能在项目详情页显示），包含 trashed 状态的任务
    final children = childrenEntities
        .where((entity) => entity.milestoneId == null)
        .map(_toDomain)
        .toList();
    for (final child in children) {
      result.add(child);
      result.addAll(await _getAllDescendantsIncludingTrashed(child.id));
    }
    return result;
  }

  /// 同步所有子任务的状态和时间字段（在事务中执行）
  /// 
  /// [descendants] 要同步的后代任务列表
  /// [status] 要设置的状态
  /// [operationTime] 操作时间（用于 updatedAt）
  /// [endedAt] 完成时间（如果状态是 completedActive）
  /// [archivedAt] 归档时间（如果状态是 archived）
  /// 
  /// 注意：此方法必须在事务中调用，且需要先获取后代任务列表
  void _syncDescendantsStatusInTransaction(
    List<Task> descendants,
    TaskStatus status,
    DateTime operationTime, {
    DateTime? endedAt,
    DateTime? archivedAt,
  }) {
    for (final descendant in descendants) {
      // 在事务中获取实体（已在事务中）
      final entity = _isar.taskEntitys.getSync(descendant.id);
      if (entity == null) continue;

      // 保存旧状态，用于触发器逻辑判断
      final oldStatus = entity.status;

      // 设置状态和更新时间
      entity.status = status;
      entity.updatedAt = operationTime;

      // 触发器逻辑：如果状态从非完成状态变为 completedActive，设置 endedAt
      final wasNotCompleted = oldStatus != TaskStatus.completedActive;
      final isNowCompleted = status == TaskStatus.completedActive;
      if (wasNotCompleted && isNowCompleted) {
        if (endedAt != null) {
          entity.endedAt = endedAt;
        } else if (entity.endedAt == null) {
          entity.endedAt = operationTime;
        }
      }

      // 触发器逻辑：如果状态从非归档状态变为 archived，设置 archivedAt
      final wasNotArchived = oldStatus != TaskStatus.archived;
      final isNowArchived = status == TaskStatus.archived;
      if (wasNotArchived && isNowArchived) {
        if (archivedAt != null) {
          entity.archivedAt = archivedAt;
        } else if (entity.archivedAt == null) {
          entity.archivedAt = operationTime;
        }
      }

      _isar.taskEntitys.putSync(entity);
    }
  }
}

