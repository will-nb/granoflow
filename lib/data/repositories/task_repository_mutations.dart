part of 'task_repository.dart';

// ignore_for_file: override_on_non_overriding_member
// 这些方法实现抽象类 TaskRepository 中定义的方法，@override 注解是正确的
// analyzer 无法正确识别 part of 文件中的 override 关系

/// TaskRepository 变更方法 mixin
/// 
/// 包含所有数据变更方法，如 createTask、updateTask、markStatus 等
/// 
/// 依赖：
/// - TaskRepositoryHelpers: 提供基础辅助方法
/// - TaskRepositorySectionQueries: 提供区域查询方法
/// - TaskRepositoryTaskHierarchy: 提供任务层级方法
mixin TaskRepositoryMutations
    on TaskRepositoryHelpers,
        TaskRepositorySectionQueries,
        TaskRepositoryTaskHierarchy {
  /// 创建任务
  @override
  Future<Task> createTask(TaskDraft draft) async {
    return _isar.writeTxn<Task>(() async {
      final now = _clock();
      final taskId = await _generateTaskId(now);
      final entity = TaskEntity()
        ..taskId = taskId
        ..title = draft.title
        ..status = draft.status
        ..dueAt = draft.dueAt
        ..startedAt = null
        ..endedAt = null
        ..archivedAt = null
        ..createdAt = now
        ..updatedAt = now
        ..parentId = draft.parentId
        ..parentTaskId = draft.parentTaskId ?? draft.parentId
        ..projectId = draft.projectId
        ..projectIsarId = null
        ..milestoneId = draft.milestoneId
        ..milestoneIsarId = null
        ..sortIndex = draft.sortIndex
        ..tags = draft.tags.map((tag) => TagService.normalizeSlug(tag)).toList()
        ..templateLockCount = 0
        ..seedSlug = draft.seedSlug
        ..allowInstantComplete = draft.allowInstantComplete
        ..description = draft.description
        ..logs = draft.logs.map(_logFromDomain).toList();
      final id = await _isar.taskEntitys.put(entity);
      entity.id = id;
      return _toDomain(entity);
    });
  }

  /// 应用任务更新到实体对象
  ///
  /// 包含状态转换逻辑（dueAt 变化时自动转换为 pending）和所有字段更新逻辑
  /// 这是一个私有辅助方法，不涉及数据库操作，只处理实体对象的修改
  ///
  /// [entity] 要更新的实体对象（会被直接修改）
  /// [payload] 更新内容
  /// [taskId] 任务 ID（仅用于调试日志）
  void _applyTaskUpdate(TaskEntity entity, TaskUpdate payload, {int? taskId}) {
    // 保存旧状态，用于触发器逻辑判断
    final oldStatus = entity.status;
    
    // 触发器逻辑：如果截止日期发生变化，自动将状态转换为 pending
    // 判断截止日期是否变化（忽略 null 的情况）
    final dueAtChanged = payload.dueAt != null && payload.dueAt != entity.dueAt;
    if (dueAtChanged) {
      // 无论当前状态是什么，只要截止日期变化，都转换为 pending
      // 但如果 payload.status 显式指定了值，则使用指定的值（显式指定优先）
      if (payload.status == null) {
        entity.status = TaskStatus.pending;
      }
    }

    // 应用字段更新
    entity
      ..title = payload.title ?? entity.title
      ..status = payload.status ?? entity.status
      ..dueAt = payload.dueAt ?? entity.dueAt
      ..startedAt = payload.startedAt ?? entity.startedAt
      ..endedAt = payload.endedAt ?? entity.endedAt
      ..archivedAt = payload.archivedAt ?? entity.archivedAt
      ..sortIndex = payload.sortIndex ?? entity.sortIndex
      ..tags = payload.tags != null
          ? payload.tags!.map((tag) => TagService.normalizeSlug(tag)).toList()
          : entity.tags
      ..templateLockCount =
          (entity.templateLockCount + payload.templateLockDelta).clamp(
            0,
            1 << 31,
          )
      ..allowInstantComplete =
          payload.allowInstantComplete ?? entity.allowInstantComplete
      ..description = payload.description ?? entity.description
      ..logs = payload.logs != null
          ? payload.logs!.map(_logFromDomain).toList()
          : entity.logs
      ..updatedAt = _clock();

    // 触发器逻辑：如果状态从非完成状态变为 completedActive，自动记录完成时间
    // 这个逻辑必须在字段更新之后执行，确保使用的是新状态
    final newStatus = entity.status;
    final wasNotCompleted = oldStatus != TaskStatus.completedActive;
    final isNowCompleted = newStatus == TaskStatus.completedActive;
    
    if (wasNotCompleted && isNowCompleted) {
      // 如果状态从非完成变为完成，且 endedAt 为空（包括原来为空且 payload 也没有指定），
      // 则自动设置为当前时间
      // 如果 payload 中显式指定了 endedAt（包括 null），则使用指定的值（已在上面应用）
      // 如果 endedAt 已经有值，保持不变
      if (payload.endedAt == null && entity.endedAt == null) {
        // payload 没有指定 endedAt，且原来的 endedAt 也是 null，自动设置
        entity.endedAt = _clock();
      }
      // 其他情况：
      // - payload.endedAt 有值：使用指定的值（已在上面应用）
      // - entity.endedAt 有值但 payload.endedAt 为 null：保持原值（已在上面应用为 entity.endedAt）
    }

    // 触发器逻辑：如果状态从非归档状态变为 archived，自动记录归档时间
    final wasNotArchived = oldStatus != TaskStatus.archived;
    final isNowArchived = newStatus == TaskStatus.archived;
    
    if (wasNotArchived && isNowArchived) {
      // 如果状态从非归档变为归档，且 archivedAt 为空（包括原来为空且 payload 也没有指定），
      // 则自动设置为当前时间
      // 如果 payload 中显式指定了 archivedAt（包括 null），则使用指定的值（已在上面应用）
      // 如果 archivedAt 已经有值，保持不变
      if (payload.archivedAt == null && entity.archivedAt == null) {
        // payload 没有指定 archivedAt，且原来的 archivedAt 也是 null，自动设置
        entity.archivedAt = _clock();
      }
      // 其他情况：
      // - payload.archivedAt 有值：使用指定的值（已在上面应用）
      // - entity.archivedAt 有值但 payload.archivedAt 为 null：保持原值（已在上面应用为 entity.archivedAt）
    }

    final shouldClearParent = payload.clearParent == true;
    if (shouldClearParent) {
      entity.parentId = null;
      entity.parentTaskId = null;
    } else {
      if (payload.parentId != null) {
        entity.parentId = payload.parentId;
        if (payload.parentTaskId != null) {
          entity.parentTaskId = payload.parentTaskId;
        } else if (_isRegularTask(entity)) {
          // 只有普通任务才设置 parentTaskId
          entity.parentTaskId = payload.parentId;
        }
      } else if (payload.parentTaskId != null) {
        entity.parentTaskId = payload.parentTaskId;
      }
    }

    if (payload.clearProject == true) {
      entity.projectId = null;
      entity.projectIsarId = null;
    } else if (payload.projectId != null) {
      entity.projectId = payload.projectId;
    }

    if (payload.clearMilestone == true) {
      entity.milestoneId = null;
      entity.milestoneIsarId = null;
    } else if (payload.milestoneId != null) {
      entity.milestoneId = payload.milestoneId;
    }
  }

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

  /// 移动任务到指定位置
  @override
  Future<void> moveTask({
    required int taskId,
    required int? targetParentId,
    required TaskSection targetSection,
    required double sortIndex,
    DateTime? dueAt,
  }) async {
    // 通过 updateTask 统一处理，显式指定 status 确保状态根据 section 正确设置
    // 显式指定的 status 优先级高于自动状态转换逻辑
    final status = _sectionToStatus(targetSection);
    await updateTask(
      taskId,
      TaskUpdate(
        parentId: targetParentId,
        parentTaskId: targetParentId,
        clearParent:
            targetParentId == null, // 如果 targetParentId 为 null，清空 parentId
        status: status,
        sortIndex: sortIndex,
        dueAt: dueAt,
      ),
    );
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
