part of 'task_repository.dart';

// ignore_for_file: override_on_non_overriding_member

/// TaskRepository 变更方法 mixin - 状态相关操作
/// 
/// 包含任务状态更新相关的方法，如 updateTask、markStatus、archiveTask
/// 
/// 依赖：
/// - TaskRepositoryHelpers: 提供基础辅助方法
/// - TaskRepositorySectionQueries: 提供区域查询方法
/// - TaskRepositoryTaskHierarchy: 提供任务层级方法
/// - TaskRepositoryMutationsCore: 提供 _applyTaskUpdate 方法
mixin TaskRepositoryMutationsStatus
    on TaskRepositoryHelpers,
        TaskRepositorySectionQueries,
        TaskRepositoryTaskHierarchy,
        TaskRepositoryMutationsCore {
  /// 更新任务
  @override
  Future<void> updateTask(int taskId, TaskUpdate payload) async {
    // 如果状态可能发生变化，在事务外先获取所有后代任务
    final oldEntity = await _isar.taskEntitys.get(taskId);
    final oldStatus = oldEntity?.status;
    final statusChanged = payload.status != null && oldStatus != payload.status;
    List<Task> descendants = [];
    
    if (statusChanged) {
      descendants = await _getAllDescendantsIncludingTrashed(taskId);
    }
    
    await _isar.writeTxn(() async {
      final entity = await _isar.taskEntitys.get(taskId);
      if (entity == null) {
        return;
      }

      final oldParentId = entity.parentId;

      // 应用更新逻辑
      _applyTaskUpdate(entity, payload, taskId: taskId);

      final newStatus = entity.status;
      final operationTime = entity.updatedAt; // 使用 _applyTaskUpdate 中设置的时间

      await _isar.taskEntitys.put(entity);
      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: repo:updateTask, id: $taskId, clearParent: ${payload.clearParent == true}, oldParentId: $oldParentId, newParentId: ${entity.parentId}, dueAt: ${entity.dueAt}, sortIndex: ${entity.sortIndex}, status: ${entity.status}}',
        );
      }

      // 如果状态发生变化，同步所有子任务的状态和时间字段
      if (statusChanged) {
        DateTime? endedAt;
        DateTime? archivedAt;

        if (newStatus == TaskStatus.completedActive) {
          endedAt = entity.endedAt ?? operationTime;
        }

        if (newStatus == TaskStatus.archived) {
          archivedAt = entity.archivedAt ?? operationTime;
        }

        // 在事务中同步所有子任务的状态和时间字段
        if (descendants.isNotEmpty) {
          _syncDescendantsStatusInTransaction(
            descendants,
            newStatus,
            operationTime,
            endedAt: endedAt,
            archivedAt: archivedAt,
          );
        }
      }
    });
  }

  /// 设置任务的 projectIsarId 和 milestoneIsarId（用于导入）
  @override
  Future<void> setTaskProjectAndMilestoneIsarId(
    int taskId,
    int? projectIsarId,
    int? milestoneIsarId,
  ) async {
    await _isar.writeTxn(() async {
      final entity = await _isar.taskEntitys.get(taskId);
      if (entity == null) {
        return;
      }

      entity
        ..projectIsarId = projectIsarId
        ..milestoneIsarId = milestoneIsarId;

      await _isar.taskEntitys.put(entity);
    });
  }

  /// 标记任务状态
  @override
  Future<void> markStatus({
    required int taskId,
    required TaskStatus status,
  }) async {
    // 在事务外获取所有后代任务（避免在事务中异步查询）
    final descendants = await _getAllDescendantsIncludingTrashed(taskId);
    
    await _isar.writeTxn(() async {
      final entity = await _isar.taskEntitys.get(taskId);
      if (entity == null) {
        if (kDebugMode) {
          debugPrint('[ArchiveTask] markStatus: taskId=$taskId not found');
        }
        return;
      }
      
      // 保存旧状态，用于触发器逻辑判断
      final oldStatus = entity.status;
      
      if (kDebugMode && status == TaskStatus.archived) {
        debugPrint(
          '[ArchiveTask] markStatus: taskId=$taskId, oldStatus=$oldStatus, newStatus=$status, oldArchivedAt=${entity.archivedAt}',
        );
      }
      
      // 获取统一的操作时间
      final operationTime = _clock();
      
      entity
        ..status = status
        ..updatedAt = operationTime;
      
      // 触发器逻辑：如果状态从非完成状态变为 completedActive，自动记录完成时间
      final wasNotCompleted = oldStatus != TaskStatus.completedActive;
      final isNowCompleted = status == TaskStatus.completedActive;
      DateTime? endedAt;
      
      if (wasNotCompleted && isNowCompleted && entity.endedAt == null) {
        entity.endedAt = operationTime;
        endedAt = operationTime;
      } else if (wasNotCompleted && isNowCompleted) {
        endedAt = entity.endedAt;
      }
      
      // 触发器逻辑：如果状态从非归档状态变为 archived，自动记录归档时间
      final wasNotArchived = oldStatus != TaskStatus.archived;
      final isNowArchived = status == TaskStatus.archived;
      DateTime? archivedAt;
      
      if (wasNotArchived && isNowArchived) {
        if (entity.archivedAt == null) {
          entity.archivedAt = operationTime;
          archivedAt = operationTime;
          if (kDebugMode) {
            debugPrint(
              '[ArchiveTask] markStatus: ArchivedAt trigger fired, set to ${entity.archivedAt}',
            );
          }
        } else {
          archivedAt = entity.archivedAt;
          if (kDebugMode) {
            debugPrint(
              '[ArchiveTask] markStatus: ArchivedAt already set to ${entity.archivedAt}, not updating',
            );
          }
        }
      }
      
      await _isar.taskEntitys.put(entity);
      
      if (kDebugMode && status == TaskStatus.archived) {
        debugPrint(
          '[ArchiveTask] markStatus: taskId=$taskId saved, finalArchivedAt=${entity.archivedAt}',
        );
      }
      
      // 在事务中同步所有子任务的状态和时间字段
      if (descendants.isNotEmpty) {
        _syncDescendantsStatusInTransaction(
          descendants,
          status,
          operationTime,
          endedAt: endedAt,
          archivedAt: archivedAt,
        );
      }
    });
  }

  /// 归档任务
  @override
  Future<void> archiveTask(int taskId) async {
    if (kDebugMode) {
      final existing = await _isar.taskEntitys.get(taskId);
      debugPrint(
        '[ArchiveTask] archiveTask called: taskId=$taskId, currentStatus=${existing?.status}, currentArchivedAt=${existing?.archivedAt}',
      );
    }
    await markStatus(taskId: taskId, status: TaskStatus.archived);
    if (kDebugMode) {
      final updated = await _isar.taskEntitys.get(taskId);
      debugPrint(
        '[ArchiveTask] archiveTask completed: taskId=$taskId, newStatus=${updated?.status}, newArchivedAt=${updated?.archivedAt}',
      );
    }
  }
}

