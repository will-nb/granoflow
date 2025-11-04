part of 'task_repository.dart';

// ignore_for_file: override_on_non_overriding_member

/// TaskRepository 变更方法 mixin - 核心部分
/// 
/// 包含创建任务和基础更新逻辑
/// 
/// 依赖：
/// - TaskRepositoryHelpers: 提供基础辅助方法
/// - TaskRepositorySectionQueries: 提供区域查询方法
/// - TaskRepositoryTaskHierarchy: 提供任务层级方法
mixin TaskRepositoryMutationsCore
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
}

