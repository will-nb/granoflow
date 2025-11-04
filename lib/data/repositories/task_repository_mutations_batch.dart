part of 'task_repository.dart';

// ignore_for_file: override_on_non_overriding_member

/// TaskRepository 变更方法 mixin - 批量操作
/// 
/// 包含批量操作和删除相关的方法，如 softDelete、purgeObsolete、batchUpdate 等
/// 
/// 依赖：
/// - TaskRepositoryHelpers: 提供基础辅助方法
/// - TaskRepositorySectionQueries: 提供区域查询方法
/// - TaskRepositoryTaskHierarchy: 提供任务层级方法
/// - TaskRepositoryMutationsCore: 提供 _applyTaskUpdate 方法
mixin TaskRepositoryMutationsBatch
    on TaskRepositoryHelpers,
        TaskRepositorySectionQueries,
        TaskRepositoryTaskHierarchy,
        TaskRepositoryMutationsCore {
  /// 软删除任务（移动到回收站）
  @override
  Future<void> softDelete(int taskId) async {
    // 在事务外获取所有后代任务（避免在事务中异步查询）
    final descendants = await _getAllDescendantsIncludingTrashed(taskId);
    
    await _isar.writeTxn(() async {
      final entity = await _isar.taskEntitys.get(taskId);
      if (entity == null || entity.templateLockCount > 0) {
        return;
      }
      
      // 获取统一的操作时间
      final operationTime = _clock();
      
      entity
        ..status = TaskStatus.trashed
        ..updatedAt = operationTime;
      await _isar.taskEntitys.put(entity);
      
      // 在事务中同步所有子任务为 trashed 状态
      if (descendants.isNotEmpty) {
        _syncDescendantsStatusInTransaction(
          descendants,
          TaskStatus.trashed,
          operationTime,
        );
      }
    });
  }

  /// 清理过期的伪删除记录
  @override
  Future<int> purgeObsolete(DateTime olderThan) async {
    return _isar.writeTxn<int>(() async {
      final obsolete = await _isar.taskEntitys
          .filter()
          .statusEqualTo(TaskStatus.pseudoDeleted)
          .updatedAtLessThan(olderThan)
          .findAll();
      await _isar.taskEntitys.deleteAll(obsolete.map((e) => e.id).toList());
      return obsolete.length;
    });
  }

  /// 清空回收站：批量永久删除所有回收站任务
  /// 返回删除的任务数量
  @override
  Future<int> clearAllTrashedTasks() async {
    return _isar.writeTxn<int>(() async {
      // 查询所有回收站任务
      final trashedTasks = await _isar.taskEntitys
          .filter()
          .statusEqualTo(TaskStatus.trashed)
          .findAll();
      
      if (trashedTasks.isEmpty) {
        return 0;
      }
      
      final now = DateTime.now();
      final taskIds = <int>[];
      
      // 批量更新状态为 pseudoDeleted
      for (final task in trashedTasks) {
        task.status = TaskStatus.pseudoDeleted;
        task.updatedAt = now;
        taskIds.add(task.id);
      }
      
      // 保存更新
      await _isar.taskEntitys.putAll(trashedTasks);
      
      // 物理删除（清理伪删除记录）
      await _isar.taskEntitys.deleteAll(taskIds);
      
      if (kDebugMode) {
        debugPrint('[TaskRepository] clearAllTrashedTasks: Deleted ${taskIds.length} tasks');
      }
      
      return taskIds.length;
    });
  }

  /// 调整模板锁定计数
  @override
  Future<void> adjustTemplateLock({
    required int taskId,
    required int delta,
  }) async {
    await _isar.writeTxn(() async {
      final entity = await _isar.taskEntitys.get(taskId);
      if (entity == null) {
        return;
      }
      entity.templateLockCount =
          (entity.templateLockCount + delta).clamp(0, 1 << 31);
      await _isar.taskEntitys.put(entity);
    });
  }

  /// 批量插入或更新任务
  @override
  Future<void> upsertTasks(List<Task> tasks) async {
    await _isar.writeTxn(() async {
      for (final task in tasks) {
        final entity = _fromDomain(task);
        await _isar.taskEntitys.put(entity);
      }
    });
  }

  /// 批量更新任务
  @override
  Future<void> batchUpdate(Map<int, TaskUpdate> updates) async {
    if (updates.isEmpty) return;
    await _isar.writeTxn(() async {
      for (final entry in updates.entries) {
        final entity = await _isar.taskEntitys.get(entry.key);
        if (entity == null) continue;
        final payload = entry.value;
        final oldParentId = entity.parentId;

        // 使用统一的更新逻辑，确保状态转换逻辑被正确应用
        _applyTaskUpdate(entity, payload, taskId: entry.key);

        await _isar.taskEntitys.put(entity);
        if (kDebugMode) {
          debugPrint(
            '[DnD] {event: repo:batchUpdate, id: ${entry.key}, clearParent: ${payload.clearParent == true}, oldParentId: $oldParentId, newParentId: ${entity.parentId}, dueAt: ${entity.dueAt}, status: ${entity.status}}',
          );
        }
      }
    });
  }
}

