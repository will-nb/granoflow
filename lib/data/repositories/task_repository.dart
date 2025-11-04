import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../../core/services/tag_service.dart';
import '../../core/utils/task_section_utils.dart';
import '../isar/task_entity.dart';
import '../models/task.dart';

abstract class TaskRepository {
  Stream<List<Task>> watchSection(TaskSection section);

  Stream<TaskTreeNode> watchTaskTree(int rootTaskId);

  Stream<List<Task>> watchInbox();

  @Deprecated('使用 ProjectRepository 和 ProjectService 替代')
  Stream<List<Task>> watchProjects();

  Stream<List<Task>> watchQuickTasks();

  @Deprecated('使用 MilestoneRepository 和 MilestoneService 替代')
  Stream<List<Task>> watchMilestones(int projectId);

  Stream<List<Task>> watchTasksByProjectId(String projectId);

  Stream<List<Task>> watchTasksByMilestoneId(String milestoneId);

  Future<List<Task>> listTasksByMilestoneId(String milestoneId);

  Stream<List<Task>> watchInboxFiltered({
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  });

  Future<Task> createTask(TaskDraft draft);

  Future<void> updateTask(int taskId, TaskUpdate payload);

  Future<void> moveTask({
    required int taskId,
    required int? targetParentId,
    required TaskSection targetSection,
    required double sortIndex,
    DateTime? dueAt,
  });

  Future<void> markStatus({required int taskId, required TaskStatus status});

  Future<void> archiveTask(int taskId);

  Future<void> softDelete(int taskId);

  Future<int> purgeObsolete(DateTime olderThan);

  /// 清空回收站：批量永久删除所有回收站任务
  /// 返回删除的任务数量
  Future<int> clearAllTrashedTasks();

  Future<void> adjustTemplateLock({required int taskId, required int delta});

  Future<Task?> findById(int id);

  /// 监听单个任务的变化
  Stream<Task?> watchTaskById(int id);

  Future<Task?> findBySlug(String slug);

  Future<List<Task>> listRoots();

  Future<List<Task>> listChildren(int parentId);

  /// 列出父任务的所有子任务（包括 trashed 状态）
  /// 用于在父任务展开时显示已删除的子任务
  Future<List<Task>> listChildrenIncludingTrashed(int parentId);

  Future<void> upsertTasks(List<Task> tasks);

  Future<List<Task>> listAll();

  Future<List<Task>> searchByTitle(
    String query, {
    TaskStatus? status,
    int limit,
  });

  /// 批量更新：按 id -> TaskUpdate 的映射执行更新
  Future<void> batchUpdate(Map<int, TaskUpdate> updates);

  /// 列出某个区域内用于排序的任务（与 UI 一致，已排序的叶任务）
  Future<List<Task>> listSectionTasks(TaskSection section);

  /// 分页查询已完成任务（按完成时间降序）
  Future<List<Task>> listCompletedTasks({
    required int limit,
    required int offset,
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  });

  /// 分页查询已归档任务（按归档时间降序）
  Future<List<Task>> listArchivedTasks({
    required int limit,
    required int offset,
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  });

  /// 获取已完成任务总数
  Future<int> countCompletedTasks();

  /// 获取已归档任务总数
  Future<int> countArchivedTasks();

  /// 分页查询已删除任务（按删除时间降序，使用 updatedAt 作为删除时间）
  Future<List<Task>> listTrashedTasks({
    required int limit,
    required int offset,
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  });

  /// 获取已删除任务总数
  Future<int> countTrashedTasks();
}

class IsarTaskRepository implements TaskRepository {
  IsarTaskRepository(this._isar, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Isar _isar;
  final DateTime Function() _clock;

  @override
  Stream<List<Task>> watchSection(TaskSection section) {
    return _watchQuery(() => _fetchSection(section));
  }

  @override
  Stream<TaskTreeNode> watchTaskTree(int rootTaskId) {
    return _watchQuery(() => _buildTree(rootTaskId));
  }

  @override
  Stream<List<Task>> watchInbox() {
    return _watchQuery(() async {
      final results = await _isar.taskEntitys
          .filter()
          .statusEqualTo(TaskStatus.inbox)
          .sortBySortIndex()
          .thenByCreatedAtDesc()
          .findAll();
      // 移除过滤，让 inbox 页面显示所有任务（包括关联项目的）
      final tasks = results.map(_toDomain).toList(growable: false);
      return tasks;
    });
  }

  @override
  Stream<List<Task>> watchInboxFiltered({
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  }) {
    return _watchQuery(() async {
      final entities = await _isar.taskEntitys
          .filter()
          .statusEqualTo(TaskStatus.inbox)
          .sortBySortIndex()
          .thenByCreatedAtDesc()
          .findAll();
      // 移除 _isRegularTask 过滤，让 inbox 页面显示所有任务（包括关联项目的）
      // 然后按标签和项目过滤
      final filtered = entities.where((entity) {
            final tags = entity.tags;
            // 规范化标签后进行比较（兼容旧数据）
            if (contextTag != null && contextTag.isNotEmpty) {
              final normalizedContextTag = TagService.normalizeSlug(contextTag);
              if (!tags.any(
                (tag) => TagService.normalizeSlug(tag) == normalizedContextTag,
              )) {
                return false;
              }
            }
            if (priorityTag != null && priorityTag.isNotEmpty) {
              final normalizedPriorityTag = TagService.normalizeSlug(
                priorityTag,
              );
              if (!tags.any(
                (tag) => TagService.normalizeSlug(tag) == normalizedPriorityTag,
              )) {
                return false;
              }
            }
            if (urgencyTag != null && urgencyTag.isNotEmpty) {
              final normalizedUrgencyTag = TagService.normalizeSlug(urgencyTag);
              if (!tags.any(
                (tag) => TagService.normalizeSlug(tag) == normalizedUrgencyTag,
              )) {
                return false;
              }
            }
            if (importanceTag != null && importanceTag.isNotEmpty) {
              final normalizedImportanceTag = TagService.normalizeSlug(
                importanceTag,
              );
              if (!tags.any(
                (tag) =>
                    TagService.normalizeSlug(tag) == normalizedImportanceTag,
              )) {
                return false;
              }
            }
            
            // 项目筛选（与分页查询逻辑一致）
            if (showNoProject == true) {
              if (entity.projectId != null && entity.projectId!.isNotEmpty) {
                return false;
              }
            } else {
              // 项目ID筛选
              if (projectId != null && projectId.isNotEmpty) {
                if (entity.projectId != projectId) {
                  return false;
                }
                
                // 里程碑ID筛选（仅在指定项目时有效）
                if (milestoneId != null && milestoneId.isNotEmpty) {
                  if (entity.milestoneId != milestoneId) {
                    return false;
                  }
                }
              } else {
                // 如果没有指定项目，但有指定showNoProject=false，则不筛选
                // 但如果指定了里程碑ID但没有项目ID，应该过滤掉所有任务
                if (milestoneId != null && milestoneId.isNotEmpty) {
                  return false; // 里程碑筛选必须指定项目
                }
              }
            }
            
            return true;
          })
          .map(_toDomain)
          .toList(growable: false);
      return filtered;
    });
  }

  @override
  @Deprecated('使用 ProjectRepository 和 ProjectService 替代')
  Stream<List<Task>> watchProjects() {
    throw UnimplementedError(
      'watchProjects 已废弃，请使用 ProjectService.watchActiveProjects()',
    );
  }

  @override
  Stream<List<Task>> watchQuickTasks() {
    return _watchQuery(() async {
      final entities = await _isar.taskEntitys
          .filter()
          .parentIdIsNull()
          .findAll();
      // 过滤出普通任务且状态为活跃的
      final filtered = entities
          .where(_isRegularTask)
          .where((entity) => _isActiveQuickTaskStatus(entity.status))
          .toList(growable: false);
      filtered.sort((a, b) {
        final aDue =
            a.dueAt ?? DateTime.fromMillisecondsSinceEpoch(4102444800000);
        final bDue =
            b.dueAt ?? DateTime.fromMillisecondsSinceEpoch(4102444800000);
        final compare = aDue.compareTo(bDue);
        if (compare != 0) {
          return compare;
        }
        return a.createdAt.compareTo(b.createdAt);
      });
      return filtered.map(_toDomain).toList(growable: false);
    });
  }

  @override
  @Deprecated('使用 MilestoneRepository 和 MilestoneService 替代')
  Stream<List<Task>> watchMilestones(int projectId) {
    throw UnimplementedError(
      'watchMilestones 已废弃，请使用 MilestoneService.watchMilestones()',
    );
  }

  @override
  Stream<List<Task>> watchTasksByProjectId(String projectId) {
    return _watchQuery(() async {
      final entities = await _isar.taskEntitys
          .filter()
          .projectIdEqualTo(projectId)
          .findAll();
      return entities.map(_toDomain).toList(growable: false);
    });
  }

  @override
  Stream<List<Task>> watchTasksByMilestoneId(String milestoneId) {
    return _watchQuery(() async {
      final entities = await _isar.taskEntitys
          .filter()
          .milestoneIdEqualTo(milestoneId)
          .findAll();
      return entities.map(_toDomain).toList(growable: false);
    });
  }

  @override
  Future<List<Task>> listTasksByMilestoneId(String milestoneId) async {
    final entities = await _isar.taskEntitys
        .filter()
        .milestoneIdEqualTo(milestoneId)
        .findAll();
    return entities.map(_toDomain).toList(growable: false);
  }

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
      entity
        ..templateLockCount = (entity.templateLockCount + delta).clamp(
          0,
          1 << 31,
        )
        ..updatedAt = _clock();
      await _isar.taskEntitys.put(entity);
    });
  }

  @override
  Future<Task?> findById(int id) async {
    final entity = await _isar.taskEntitys.get(id);
    return entity == null ? null : _toDomain(entity);
  }

  @override
  Stream<Task?> watchTaskById(int id) {
    return _watchQuery(() async {
      final entity = await _isar.taskEntitys.get(id);
      return entity == null ? null : _toDomain(entity);
    });
  }

  @override
  Future<Task?> findBySlug(String slug) async {
    final entity = await _isar.taskEntitys
        .filter()
        .seedSlugEqualTo(slug)
        .findFirst();
    return entity == null ? null : _toDomain(entity);
  }

  @override
  Future<List<Task>> listRoots() async {
    final roots = await _isar.taskEntitys
        .filter()
        .parentIdIsNull()
        .sortBySortIndex()
        .thenByCreatedAtDesc()
        .findAll();
    // 过滤出普通任务（没有关联项目或里程碑）
    return roots
        .where(_isRegularTask)
        .map(_toDomain)
        .toList(growable: false);
  }

  @override
  Future<List<Task>> listChildren(int parentId) async {
    final children = await _isar.taskEntitys
        .filter()
        .parentIdEqualTo(parentId)
        .sortBySortIndex()
        .thenByCreatedAtDesc()
        .findAll();
    // 过滤掉 trashed 状态的任务和里程碑（里程碑只能在项目详情页显示）
    return children
        .where(
          (entity) =>
              entity.status != TaskStatus.trashed &&
              entity.milestoneId == null, // 排除里程碑
        )
        .map(_toDomain)
        .toList(growable: false);
  }

  @override
  Future<List<Task>> listChildrenIncludingTrashed(int parentId) async {
    final children = await _isar.taskEntitys
        .filter()
        .parentIdEqualTo(parentId)
        .sortBySortIndex()
        .thenByCreatedAtDesc()
        .findAll();
    // 只排除里程碑（里程碑只能在项目详情页显示），包含 trashed 状态的任务
    return children
        .where(
          (entity) => entity.milestoneId == null, // 排除里程碑
        )
        .map(_toDomain)
        .toList(growable: false);
  }

  /// 递归获取所有后代任务（包括 trashed 状态）
  /// 
  /// [parentId] 父任务 ID
  /// 返回所有后代任务的列表（包括 trashed 状态，排除里程碑）
  Future<List<Task>> _getAllDescendantsIncludingTrashed(int parentId) async {
    final result = <Task>[];
    final children = await listChildrenIncludingTrashed(parentId);
    for (final child in children) {
      result.add(child);
      result.addAll(await _getAllDescendantsIncludingTrashed(child.id));
    }
    return result;
  }

  @override
  Future<void> upsertTasks(List<Task> tasks) async {
    await _isar.writeTxn(() async {
      for (final task in tasks) {
        final entity = _fromDomain(task);
        await _isar.taskEntitys.put(entity);
      }
    });
  }

  @override
  Future<List<Task>> listAll() async {
    final records = await _isar.taskEntitys.where().findAll();
    return records.map(_toDomain).toList(growable: false);
  }

  @override
  Future<List<Task>> searchByTitle(
    String query, {
    TaskStatus? status,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) {
      return const <Task>[];
    }
    QueryBuilder<TaskEntity, TaskEntity, QAfterFilterCondition> builder = _isar
        .taskEntitys
        .filter()
        .titleContains(query, caseSensitive: false);
    if (status != null) {
      builder = builder.statusEqualTo(status);
    }
    final results = await builder.sortByUpdatedAtDesc().findAll();
    // 过滤出普通任务（没有关联项目或里程碑）
    final regularTasks = results
        .where(_isRegularTask)
        .take(limit)
        .map(_toDomain)
        .toList(growable: false);
    return regularTasks;
  }

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

  @override
  Future<List<Task>> listSectionTasks(TaskSection section) async {
    // 复用 _fetchSection（已是叶任务，并按 sortIndex 排序）
    return _fetchSection(section);
  }

  @override
  Future<List<Task>> listCompletedTasks({
    required int limit,
    required int offset,
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  }) async {
    // 查询所有已完成任务（只查询根任务，parentId == null）
    final allTasks = await _isar.taskEntitys
        .filter()
        .statusEqualTo(TaskStatus.completedActive)
        .parentIdIsNull()
        .findAll();

    // 转换为 Domain 模型
    var tasks = allTasks.map(_toDomain).toList();

    // 应用标签筛选（内存筛选，参考watchInboxFiltered的实现）
    tasks = tasks.where((task) {
      final tags = task.tags;
      
      // 场景标签筛选
      if (contextTag != null && contextTag.isNotEmpty) {
        final normalizedContextTag = TagService.normalizeSlug(contextTag);
        if (!tags.any(
          (tag) => TagService.normalizeSlug(tag) == normalizedContextTag,
        )) {
          return false;
        }
      }
      
      // 优先级标签筛选（兼容旧数据）
      if (priorityTag != null && priorityTag.isNotEmpty) {
        final normalizedPriorityTag = TagService.normalizeSlug(priorityTag);
        if (!tags.any(
          (tag) => TagService.normalizeSlug(tag) == normalizedPriorityTag,
        )) {
          return false;
        }
      }
      
      // 紧急度标签筛选
      if (urgencyTag != null && urgencyTag.isNotEmpty) {
        final normalizedUrgencyTag = TagService.normalizeSlug(urgencyTag);
        if (!tags.any(
          (tag) => TagService.normalizeSlug(tag) == normalizedUrgencyTag,
        )) {
          return false;
        }
      }
      
      // 重要度标签筛选
      if (importanceTag != null && importanceTag.isNotEmpty) {
        final normalizedImportanceTag = TagService.normalizeSlug(importanceTag);
        if (!tags.any(
          (tag) => TagService.normalizeSlug(tag) == normalizedImportanceTag,
        )) {
          return false;
        }
      }
      
      // 项目筛选（数据库层筛选）
      // 如果指定了showNoProject，只显示无项目的任务
      if (showNoProject == true) {
        if (task.projectId != null && task.projectId!.isNotEmpty) {
          return false;
        }
      } else {
        // 项目ID筛选
        if (projectId != null && projectId.isNotEmpty) {
          if (task.projectId != projectId) {
            return false;
          }
          
          // 里程碑ID筛选（仅在指定项目时有效）
          if (milestoneId != null && milestoneId.isNotEmpty) {
            if (task.milestoneId != milestoneId) {
              return false;
            }
          }
        } else {
          // 如果没有指定项目，但有指定showNoProject=false，则不筛选
          // 但如果指定了里程碑ID但没有项目ID，应该过滤掉所有任务
          if (milestoneId != null && milestoneId.isNotEmpty) {
            return false; // 里程碑筛选必须指定项目
          }
        }
      }
      
      return true;
    }).toList(growable: false);

    // 手动排序：按 endedAt 降序，null 值排在最后
    tasks.sort((a, b) {
      if (a.endedAt == null && b.endedAt == null) return 0;
      if (a.endedAt == null) return 1; // a 的 endedAt 为 null，排在后面
      if (b.endedAt == null) return -1; // b 的 endedAt 为 null，a 排在前面
      return b.endedAt!.compareTo(a.endedAt!); // 降序排列
    });

    // 应用分页
    final endIndex = (offset + limit).clamp(0, tasks.length);
    return tasks.sublist(offset.clamp(0, tasks.length), endIndex);
  }

  @override
  Future<List<Task>> listArchivedTasks({
    required int limit,
    required int offset,
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[ArchiveTask] listArchivedTasks: limit=$limit, offset=$offset',
      );
    }
    
    // 查询所有已归档任务（只查询根任务，parentId == null）
    final allTasks = await _isar.taskEntitys
        .filter()
        .statusEqualTo(TaskStatus.archived)
        .parentIdIsNull()
        .findAll();

    if (kDebugMode) {
      debugPrint(
        '[ArchiveTask] listArchivedTasks: Found ${allTasks.length} archived tasks in DB',
      );
    }

    // 转换为 Domain 模型
    var tasks = allTasks.map(_toDomain).toList();

    // 应用标签筛选（内存筛选，参考watchInboxFiltered的实现）
    tasks = tasks.where((task) {
      final tags = task.tags;
      
      // 场景标签筛选
      if (contextTag != null && contextTag.isNotEmpty) {
        final normalizedContextTag = TagService.normalizeSlug(contextTag);
        if (!tags.any(
          (tag) => TagService.normalizeSlug(tag) == normalizedContextTag,
        )) {
          return false;
        }
      }
      
      // 优先级标签筛选（兼容旧数据）
      if (priorityTag != null && priorityTag.isNotEmpty) {
        final normalizedPriorityTag = TagService.normalizeSlug(priorityTag);
        if (!tags.any(
          (tag) => TagService.normalizeSlug(tag) == normalizedPriorityTag,
        )) {
          return false;
        }
      }
      
      // 紧急度标签筛选
      if (urgencyTag != null && urgencyTag.isNotEmpty) {
        final normalizedUrgencyTag = TagService.normalizeSlug(urgencyTag);
        if (!tags.any(
          (tag) => TagService.normalizeSlug(tag) == normalizedUrgencyTag,
        )) {
          return false;
        }
      }
      
      // 重要度标签筛选
      if (importanceTag != null && importanceTag.isNotEmpty) {
        final normalizedImportanceTag = TagService.normalizeSlug(importanceTag);
        if (!tags.any(
          (tag) => TagService.normalizeSlug(tag) == normalizedImportanceTag,
        )) {
          return false;
        }
      }
      
      // 项目筛选（数据库层筛选）
      // 如果指定了showNoProject，只显示无项目的任务
      if (showNoProject == true) {
        if (task.projectId != null && task.projectId!.isNotEmpty) {
          return false;
        }
      } else {
        // 项目ID筛选
        if (projectId != null && projectId.isNotEmpty) {
          if (task.projectId != projectId) {
            return false;
          }
          
          // 里程碑ID筛选（仅在指定项目时有效）
          if (milestoneId != null && milestoneId.isNotEmpty) {
            if (task.milestoneId != milestoneId) {
              return false;
            }
          }
        } else {
          // 如果没有指定项目，但有指定showNoProject=false，则不筛选
          // 但如果指定了里程碑ID但没有项目ID，应该过滤掉所有任务
          if (milestoneId != null && milestoneId.isNotEmpty) {
            return false; // 里程碑筛选必须指定项目
          }
        }
      }
      
      return true;
    }).toList(growable: false);

    // 手动排序：按 archivedAt 降序，null 值排在最后
    tasks.sort((a, b) {
      if (a.archivedAt == null && b.archivedAt == null) return 0;
      if (a.archivedAt == null) return 1; // a 的 archivedAt 为 null，排在后面
      if (b.archivedAt == null) return -1; // b 的 archivedAt 为 null，a 排在前面
      return b.archivedAt!.compareTo(a.archivedAt!); // 降序排列
    });

    if (kDebugMode && tasks.isNotEmpty) {
      debugPrint(
        '[ArchiveTask] listArchivedTasks: First task archivedAt=${tasks.first.archivedAt}, Last task archivedAt=${tasks.last.archivedAt}',
      );
    }

    // 应用分页
    final endIndex = (offset + limit).clamp(0, tasks.length);
    final result = tasks.sublist(offset.clamp(0, tasks.length), endIndex);
    
    if (kDebugMode) {
      debugPrint(
        '[ArchiveTask] listArchivedTasks: Returning ${result.length} tasks (offset=$offset, total=${tasks.length})',
      );
    }
    
    return result;
  }

  @override
  Future<int> countCompletedTasks() async {
    // 只统计根任务（parentId == null）
    return await _isar.taskEntitys
        .filter()
        .statusEqualTo(TaskStatus.completedActive)
        .parentIdIsNull()
        .count();
  }

  @override
  Future<int> countArchivedTasks() async {
    // 只统计根任务（parentId == null）
    final count = await _isar.taskEntitys
        .filter()
        .statusEqualTo(TaskStatus.archived)
        .parentIdIsNull()
        .count();
    
    if (kDebugMode) {
      debugPrint('[ArchiveTask] countArchivedTasks: count=$count');
    }
    
    return count;
  }

  @override
  Future<List<Task>> listTrashedTasks({
    required int limit,
    required int offset,
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[TrashTask] listTrashedTasks: limit=$limit, offset=$offset',
      );
    }
    
    // 查询所有已删除任务（status == trashed）
    final allTasks = await _isar.taskEntitys
        .filter()
        .statusEqualTo(TaskStatus.trashed)
        .findAll();

    if (kDebugMode) {
      debugPrint(
        '[TrashTask] listTrashedTasks: Found ${allTasks.length} trashed tasks in DB',
      );
    }

    // 转换为 Domain 模型
    var tasks = allTasks.map(_toDomain).toList();

    // 应用标签筛选（内存筛选，参考watchInboxFiltered的实现）
    tasks = tasks.where((task) {
      final tags = task.tags;
      
      // 场景标签筛选
      if (contextTag != null && contextTag.isNotEmpty) {
        final normalizedContextTag = TagService.normalizeSlug(contextTag);
        if (!tags.any(
          (tag) => TagService.normalizeSlug(tag) == normalizedContextTag,
        )) {
          return false;
        }
      }
      
      // 优先级标签筛选（兼容旧数据）
      if (priorityTag != null && priorityTag.isNotEmpty) {
        final normalizedPriorityTag = TagService.normalizeSlug(priorityTag);
        if (!tags.any(
          (tag) => TagService.normalizeSlug(tag) == normalizedPriorityTag,
        )) {
          return false;
        }
      }
      
      // 紧急度标签筛选
      if (urgencyTag != null && urgencyTag.isNotEmpty) {
        final normalizedUrgencyTag = TagService.normalizeSlug(urgencyTag);
        if (!tags.any(
          (tag) => TagService.normalizeSlug(tag) == normalizedUrgencyTag,
        )) {
          return false;
        }
      }
      
      // 重要度标签筛选
      if (importanceTag != null && importanceTag.isNotEmpty) {
        final normalizedImportanceTag = TagService.normalizeSlug(importanceTag);
        if (!tags.any(
          (tag) => TagService.normalizeSlug(tag) == normalizedImportanceTag,
        )) {
          return false;
        }
      }
      
      // 项目筛选（数据库层筛选）
      // 如果指定了showNoProject，只显示无项目的任务
      if (showNoProject == true) {
        if (task.projectId != null && task.projectId!.isNotEmpty) {
          return false;
        }
      } else {
        // 项目ID筛选
        if (projectId != null && projectId.isNotEmpty) {
          if (task.projectId != projectId) {
            return false;
          }
          
          // 里程碑ID筛选（仅在指定项目时有效）
          if (milestoneId != null && milestoneId.isNotEmpty) {
            if (task.milestoneId != milestoneId) {
              return false;
            }
          }
        } else {
          // 如果没有指定项目，但有指定showNoProject=false，则不筛选
          // 但如果指定了里程碑ID但没有项目ID，应该过滤掉所有任务
          if (milestoneId != null && milestoneId.isNotEmpty) {
            return false; // 里程碑筛选必须指定项目
          }
        }
      }
      
      return true;
    }).toList(growable: false);

    // 手动排序：按 updatedAt 降序（作为删除时间的近似值）
    tasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // 降序排列

    if (kDebugMode && tasks.isNotEmpty) {
      debugPrint(
        '[TrashTask] listTrashedTasks: First task updatedAt=${tasks.first.updatedAt}, Last task updatedAt=${tasks.last.updatedAt}',
      );
    }

    // 应用分页
    final endIndex = (offset + limit).clamp(0, tasks.length);
    final result = tasks.sublist(offset.clamp(0, tasks.length), endIndex);
    
    if (kDebugMode) {
      debugPrint(
        '[TrashTask] listTrashedTasks: Returning ${result.length} tasks (offset=$offset, total=${tasks.length})',
      );
    }
    
    return result;
  }

  @override
  Future<int> countTrashedTasks() async {
    final count = await _isar.taskEntitys
        .filter()
        .statusEqualTo(TaskStatus.trashed)
        .count();
    
    if (kDebugMode) {
      debugPrint('[TrashTask] countTrashedTasks: count=$count');
    }
    
    return count;
  }

  /// 判断是否为普通任务（没有关联项目或里程碑）
  /// 同步所有子任务的状态和时间字段（在事务中执行）
  /// 
  /// [parentTaskId] 父任务 ID
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

  bool _isRegularTask(TaskEntity entity) {
    return entity.projectId == null && entity.milestoneId == null;
  }

  bool _isActiveQuickTaskStatus(TaskStatus status) {
    return status != TaskStatus.archived &&
        status != TaskStatus.trashed &&
        status != TaskStatus.pseudoDeleted &&
        status != TaskStatus.completedActive;
  }

  Future<List<Task>> _fetchSection(TaskSection section) async {
    final now = _clock();

    // 使用 TaskSectionUtils 统一边界定义（严禁修改）
    // 边界定义见 TaskSectionUtils 文件顶部的注释
    final sectionStart = TaskSectionUtils.getSectionStartTime(section, now: now);
    final sectionEnd = TaskSectionUtils.getSectionEndTimeForQuery(section, now: now);

    List<TaskEntity> results;
    
    switch (section) {
      case TaskSection.overdue:
        // 已逾期：[~, <今天00:00:00)
        // 使用 dueAtLessThan 而不是 dueAtBetween，因为 overdue 没有明确的开始时间
        final todayStart = DateTime(now.year, now.month, now.day);
        results = await _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtLessThan(todayStart, include: false)
            .findAll();
        break;
      case TaskSection.today:
        // 今天：[>=今天00:00:00, <明天00:00:00)
        results = await _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtBetween(sectionStart, sectionEnd, includeUpper: false)
            .findAll();
        break;
      case TaskSection.tomorrow:
        // 明天：[>=明天00:00:00, <后天00:00:00)
        results = await _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtBetween(sectionStart, sectionEnd, includeUpper: false)
            .findAll();
        break;
      case TaskSection.thisWeek:
        // 本周：[>=后天00:00:00, <下周日00:00:00) （如果今天是周六，则为空范围）
        // 检查是否为空范围：如果开始时间 >= 结束时间，则为空范围
        if (sectionStart.isBefore(sectionEnd)) {
          results = await _isar.taskEntitys
              .filter()
              .statusEqualTo(TaskStatus.pending)
              .dueAtBetween(sectionStart, sectionEnd, includeUpper: false)
              .findAll();
        } else {
          // 空范围：使用一个永远为 false 的条件（dueAt 必须同时 < today 和 > today+365）
          final todayStart = DateTime(now.year, now.month, now.day);
          results = await _isar.taskEntitys
              .filter()
              .statusEqualTo(TaskStatus.pending)
              .dueAtLessThan(todayStart, include: false)
              .and()
              .dueAtGreaterThan(
                todayStart.add(const Duration(days: 365)),
                include: false,
              )
              .findAll();
        }
        break;
      case TaskSection.thisMonth:
        // 当月：[>=下周日00:00:00, <下月1日00:00:00) （如果本周跨月，则为空范围）
        // 检查是否为空范围：如果开始时间 >= 结束时间，则为空范围
        if (sectionStart.isBefore(sectionEnd)) {
          results = await _isar.taskEntitys
              .filter()
              .statusEqualTo(TaskStatus.pending)
              .dueAtBetween(sectionStart, sectionEnd, includeUpper: false)
              .findAll();
        } else {
          // 空范围：使用一个永远为 false 的条件（dueAt 必须同时 < today 和 > today+365）
          final todayStart = DateTime(now.year, now.month, now.day);
          results = await _isar.taskEntitys
              .filter()
              .statusEqualTo(TaskStatus.pending)
              .dueAtLessThan(todayStart, include: false)
              .and()
              .dueAtGreaterThan(
                todayStart.add(const Duration(days: 365)),
                include: false,
              )
              .findAll();
        }
        break;
      case TaskSection.nextMonth:
        // 下月：[>=下月1日00:00:00, <下下月1日00:00:00)
        results = await _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtBetween(sectionStart, sectionEnd, includeUpper: false)
            .findAll();
        break;
      case TaskSection.later:
        // 以后：[>=下下月1日00:00:00, ~) 或 dueAt == null
        // 由于 Isar 的 OR 查询语法限制，需要分别查询并合并结果
        // 查询1: dueAt == null 的任务
        final nullTasks = await _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtIsNull()
            .findAll();
        // 查询2: dueAt >= sectionStart 的任务
        final dateTasks = await _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtGreaterThan(sectionStart, include: true)
            .findAll();
        // 合并结果并去重（按 id）
        final allTasks = <int, TaskEntity>{};
        for (final task in nullTasks) {
          allTasks[task.id] = task;
        }
        for (final task in dateTasks) {
          allTasks[task.id] = task;
        }
        results = allTasks.values.toList();
        break;
      case TaskSection.completed:
        results = await _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.completedActive)
            .findAll();
        break;
      case TaskSection.archived:
        results = await _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.archived)
            .findAll();
        break;
      case TaskSection.trash:
        results = await _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.trashed)
            .findAll();
        break;
    }

    // CRITICAL FIX: Removed _filterLeafTasks() call to support parent task display
    //
    // Problem: The original code called _filterLeafTasks(results) which filtered out
    // ALL tasks that have children, regardless of whether those children are in the
    // current section or not. This caused severe display issues:
    //
    // 1. Parent tasks completely disappeared from their own sections
    // 2. Parent tasks couldn't be shown with simplified headers when "following" children
    // 3. The entire task hierarchy system broke down
    //
    // Example of the bug:
    // - Parent task (id=2) due today, child task (id=1) also due today
    // - Parent has children → _filterLeafTasks removes parent from results
    // - Today section shows only child (id=1)
    // - But child's parentId=2 → UI tries to display parent header → parent not in list!
    // - Result: Empty screen because rendering fails
    //
    // Another example:
    // - Parent task due next week, child due today
    // - Today section: _filterLeafTasks removes child (it's a leaf, but parent is elsewhere)
    // - Next week: _filterLeafTasks removes parent (it has a child, even though child is elsewhere!)
    // - Result: Parent disappears completely from all sections!
    //
    // Solution: Return ALL tasks matching the date criteria. Let the UI layer handle
    // hierarchy display through:
    // - collectRoots(): Filters tasks to show roots (no parent OR parent not in list)
    // - TaskWithParentChain: Queries and displays parent headers on demand
    // - TaskTreeView: Shows parent with children when both in same section
    //
    // This separation of concerns is architecturally correct:
    // - Data layer: Returns tasks by date/status criteria (domain logic)
    // - UI layer: Handles display logic and parent-child relationships (presentation logic)
    // 移除过滤，让 tasks 页面显示所有任务（包括关联项目的）
    // Inbox 页面使用 watchInbox() 方法，它会单独过滤普通任务
    final tasks = results.map(_toDomain).toList(growable: false);

    // 在内存中排序：先按日期（不含时间）升序，再按 sortIndex 升序，最后按 createdAt 降序
    // 使用统一的排序工具函数
    tasks.sort((a, b) {
      // 1. 比较 dueAt 的日期部分（忽略时间）
      final aDate = a.dueAt;
      final bDate = b.dueAt;

      if (aDate == null && bDate == null) {
        // 两者都没有 dueAt，按 sortIndex 升序 → createdAt 降序
        final sortIndexComparison = a.sortIndex.compareTo(b.sortIndex);
        if (sortIndexComparison != 0) return sortIndexComparison;
        return b.createdAt.compareTo(a.createdAt);
      }

      if (aDate == null) return 1; // 没有 dueAt 的排在后面
      if (bDate == null) return -1;

      // 提取日期部分（年-月-日，忽略时分秒）
      final aDayOnly = DateTime(aDate.year, aDate.month, aDate.day);
      final bDayOnly = DateTime(bDate.year, bDate.month, bDate.day);

      final dateComparison = aDayOnly.compareTo(bDayOnly);
      if (dateComparison != 0) return dateComparison;

      // 2. 日期相同，按 sortIndex 升序
      final sortIndexComparison = a.sortIndex.compareTo(b.sortIndex);
      if (sortIndexComparison != 0) return sortIndexComparison;

      // 3. sortIndex 也相同，按 createdAt 降序（新任务在前）
      return b.createdAt.compareTo(a.createdAt);
    });


    return tasks;
  }

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

  Stream<T> _watchQuery<T>(Future<T> Function() fetcher) {
    late StreamController<T> controller;
    StreamSubscription<void>? subscription;
    Future<void> emit() async {
      try {
        final value = await fetcher();
        if (!controller.isClosed) {
          controller.add(value);
        }
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    controller = StreamController<T>(
      onListen: () {
        emit();
        subscription = _isar.taskEntitys
            .watchLazy(fireImmediately: false)
            .listen((_) => emit());
      },
      onCancel: () async {
        await subscription?.cancel();
      },
    );

    return controller.stream;
  }

  Task _toDomain(TaskEntity entity) {
    // 规范化 tags（兼容旧数据，去除前缀）
    final normalizedTags = entity.tags
        .map((tag) => TagService.normalizeSlug(tag))
        .toList(growable: false);

    return Task(
      id: entity.id,
      taskId: entity.taskId,
      title: entity.title,
      status: entity.status,
      dueAt: entity.dueAt,
      startedAt: entity.startedAt,
      endedAt: entity.endedAt,
      archivedAt: entity.archivedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      parentId: entity.parentId,
      parentTaskId: entity.parentTaskId,
      projectId: entity.projectId,
      milestoneId: entity.milestoneId,
      sortIndex: entity.sortIndex,
      tags: List.unmodifiable(normalizedTags),
      templateLockCount: entity.templateLockCount,
      seedSlug: entity.seedSlug,
      allowInstantComplete: entity.allowInstantComplete,
      description: entity.description,
      logs: List.unmodifiable(entity.logs.map(_logToDomain)),
    );
  }

  TaskEntity _fromDomain(Task task) {
    final entity = TaskEntity()
      ..id = task.id
      ..taskId = task.taskId
      ..title = task.title
      ..status = task.status
      ..dueAt = task.dueAt
      ..startedAt = task.startedAt
      ..endedAt = task.endedAt
      ..archivedAt = task.archivedAt
      ..createdAt = task.createdAt
      ..updatedAt = task.updatedAt
      ..parentId = task.parentId
      ..parentTaskId = task.parentTaskId
      ..projectId = task.projectId
      ..milestoneId = task.milestoneId
      ..sortIndex = task.sortIndex
      ..tags = task.tags.map((tag) => TagService.normalizeSlug(tag)).toList()
      ..templateLockCount = task.templateLockCount
      ..seedSlug = task.seedSlug
      ..allowInstantComplete = task.allowInstantComplete
      ..description = task.description
      ..logs = task.logs.map(_logFromDomain).toList();
    return entity;
  }

  TaskLogEntry _logToDomain(TaskLogEntryEntity entity) {
    return TaskLogEntry(
      timestamp: entity.timestamp,
      action: entity.action,
      previous: entity.previous,
      next: entity.next,
      actor: entity.actor,
    );
  }

  TaskLogEntryEntity _logFromDomain(TaskLogEntry entry) {
    return TaskLogEntryEntity()
      ..timestamp = entry.timestamp
      ..action = entry.action
      ..previous = entry.previous
      ..next = entry.next
      ..actor = entry.actor;
  }

  TaskStatus _sectionToStatus(TaskSection section) {
    switch (section) {
      case TaskSection.overdue:
      case TaskSection.today:
      case TaskSection.tomorrow:
      case TaskSection.thisWeek:
      case TaskSection.thisMonth:
      case TaskSection.nextMonth:
      case TaskSection.later:
        return TaskStatus.pending;
      case TaskSection.completed:
        return TaskStatus.completedActive;
      case TaskSection.archived:
        return TaskStatus.archived;
      case TaskSection.trash:
        return TaskStatus.trashed;
    }
  }

  /// 查询最新创建的任务
  Future<Task?> _getLatestTask() async {
    try {
      final tasks = await _isar.taskEntitys
          .where()
          .sortByCreatedAtDesc()
          .limit(1)
          .findAll();

      return tasks.isNotEmpty ? _toDomain(tasks.first) : null;
    } catch (e) {
      debugPrint('Error querying latest task: $e');
      return null;
    }
  }

  /// 解析taskId格式，提取日期和后缀
  Map<String, dynamic>? _parseTaskId(String taskId) {
    try {
      if (taskId.isEmpty) return null;

      final parts = taskId.split('-');
      if (parts.length != 2) return null;

      final datePart = parts[0];
      final suffixPart = parts[1];

      if (datePart.length != 8) return null;

      final suffixInt = int.tryParse(suffixPart);
      if (suffixInt == null) return null;

      return {'date': datePart, 'suffix': suffixInt};
    } catch (e) {
      debugPrint('Error parsing taskId: $e');
      return null;
    }
  }

  Future<String> _generateTaskId(DateTime now) async {
    final dateString =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    try {
      final latestTask = await _getLatestTask();

      if (latestTask == null) {
        return '$dateString-0001';
      }

      final parsed = _parseTaskId(latestTask.taskId);
      if (parsed == null) {
        return '$dateString-0001';
      }

      final latestDate = parsed['date'] as String;
      final latestSuffix = parsed['suffix'] as int;

      if (latestDate == dateString) {
        // 如果是今天，后缀+1
        final nextSuffix = (latestSuffix + 1).toString().padLeft(4, '0');
        return '$dateString-$nextSuffix';
      } else {
        // 如果不是今天，从0001开始
        return '$dateString-0001';
      }
    } catch (e) {
      debugPrint('Error generating taskId: $e');
      return '$dateString-0001';
    }
  }
}
