import 'package:uuid/uuid.dart';

import '../../database/database_adapter.dart';
import '../../models/task.dart';
import '../../objectbox/converters.dart';
import '../../objectbox/milestone_entity.dart';
import '../../objectbox/project_entity.dart';
import '../../objectbox/task_entity.dart';
import '../../objectbox/task_log_entity.dart';
import '../task_repository.dart';

class ObjectBoxTaskRepository implements TaskRepository {
  const ObjectBoxTaskRepository(this._adapter);

  final DatabaseAdapter _adapter;
  static const _uuid = Uuid();

  @override
  Future<void> upsertTasks(List<Task> tasks) async {
    if (tasks.isEmpty) return;
    
    await _adapter.writeTransaction(() async {
      // 转换任务为实体
      final entities = <TaskEntity>[];
      final logEntities = <TaskLogEntity>[];
      
      for (final task in tasks) {
        final entity = TaskEntity(
          id: task.id,
          title: task.title,
          statusIndex: taskStatusToIndex(task.status),
          dueAt: task.dueAt,
          startedAt: task.startedAt,
          endedAt: task.endedAt,
          archivedAt: task.archivedAt,
          createdAt: task.createdAt,
          updatedAt: task.updatedAt,
          parentId: task.parentId,
          projectId: task.projectId,
          milestoneId: task.milestoneId,
          sortIndex: task.sortIndex,
          tags: List<String>.from(task.tags),
          templateLockCount: task.templateLockCount,
          seedSlug: task.seedSlug,
          allowInstantComplete: task.allowInstantComplete,
          description: task.description,
        );
        entities.add(entity);
        
        // 转换日志
        if (task.logs.isNotEmpty) {
          // 先保存实体以获取 obxId
          await _adapter.put<TaskEntity>(entity);
          final obxId = entity.obxId;
          
          for (final log in task.logs) {
            final logEntity = _createLogEntity(
              taskId: task.id,
              taskObxId: obxId,
              entry: log,
            );
            logEntities.add(logEntity);
          }
        }
      }
      
      // 批量保存实体（如果还没有保存）
      if (logEntities.isEmpty) {
        await _adapter.putMany<TaskEntity>(entities);
      }
      
      // 批量保存日志
      if (logEntities.isNotEmpty) {
        await _adapter.putMany<TaskLogEntity>(logEntities);
      }
    });
  }

  @override
  Future<void> adjustTemplateLock({required String taskId, required int delta}) async {
    await _adapter.writeTransaction(() async {
      final entity = await _findEntityByBusinessId(taskId);
      if (entity == null) {
        throw StateError('Task not found: $taskId');
      }
      final nextValue = entity.templateLockCount + delta;
      entity.templateLockCount = nextValue < 0 ? 0 : nextValue;
      entity.updatedAt = DateTime.now();
      await _adapter.put<TaskEntity>(entity);
    });
  }

  @override
  Future<void> archiveTask(String taskId) {
    throw UnimplementedError('ObjectBoxTaskRepository.archiveTask');
  }

  @override
  Future<void> batchUpdate(Map<String, TaskUpdate> updates) async {
    if (updates.isEmpty) return;
    
    await _adapter.writeTransaction(() async {
      final entities = await _adapter.findAll<TaskEntity>();
      final entityMap = <String, TaskEntity>{};
      for (final entity in entities) {
        entityMap[entity.id] = entity;
      }
      
      final updatedEntities = <TaskEntity>[];
      final logEntities = <TaskLogEntity>[];
      
      for (final entry in updates.entries) {
        final taskId = entry.key;
        final payload = entry.value;
        
        final entity = entityMap[taskId];
        if (entity == null) {
          // 任务不存在，跳过
          continue;
        }
        
        // 应用更新
        if (payload.title != null) {
          entity.title = payload.title!;
        }
        if (payload.status != null) {
          entity.statusIndex = taskStatusToIndex(payload.status!);
        }
        if (payload.dueAt != null) {
          entity.dueAt = payload.dueAt;
        }
        if (payload.startedAt != null) {
          entity.startedAt = payload.startedAt;
        }
        if (payload.endedAt != null) {
          entity.endedAt = payload.endedAt;
        }
        if (payload.archivedAt != null) {
          entity.archivedAt = payload.archivedAt;
        }
        if (payload.sortIndex != null) {
          entity.sortIndex = payload.sortIndex!;
        }
        if (payload.tags != null) {
          entity.tags = List<String>.from(payload.tags!);
        }
        if (payload.templateLockDelta != 0) {
          final nextValue = entity.templateLockCount + payload.templateLockDelta;
          entity.templateLockCount = nextValue < 0 ? 0 : nextValue;
        }
        if (payload.allowInstantComplete != null) {
          entity.allowInstantComplete = payload.allowInstantComplete!;
        }
        if (payload.description != null) {
          entity.description = payload.description;
        }
        if (payload.clearParent == true) {
          entity.parentId = null;
          entity.parent.targetId = 0;
        } else if (payload.parentId != null) {
          entity.parentId = payload.parentId;
          final parentTask = entityMap[payload.parentId];
          if (parentTask != null) {
            entity.parent.targetId = parentTask.obxId;
          }
        }
        if (payload.clearProject == true) {
          entity.projectId = null;
          entity.project.targetId = 0;
        } else if (payload.projectId != null) {
          entity.projectId = payload.projectId;
          // 需要查找项目的 obxId
          final projects = await _adapter.findAll<ProjectEntity>();
          final project = projects.firstWhere(
                (p) => p.id == payload.projectId,
                orElse: () => throw StateError(
                  'Project ${payload.projectId} not found',
                ),
              );
          entity.project.targetId = project.obxId;
        }
        if (payload.clearMilestone == true) {
          entity.milestoneId = null;
          entity.milestone.targetId = 0;
        } else if (payload.milestoneId != null) {
          entity.milestoneId = payload.milestoneId;
          // 需要查找里程碑的 obxId
          final milestones = await _adapter.findAll<MilestoneEntity>();
          final milestone = milestones.firstWhere(
                (m) => m.id == payload.milestoneId,
                orElse: () => throw StateError(
                  'Milestone ${payload.milestoneId} not found',
                ),
              );
          entity.milestone.targetId = milestone.obxId;
        }
        
        entity.updatedAt = DateTime.now();
        updatedEntities.add(entity);
        
        // 处理日志
        if (payload.logs != null && payload.logs!.isNotEmpty) {
          for (final log in payload.logs!) {
            final logEntity = _createLogEntity(
              taskId: taskId,
              taskObxId: entity.obxId,
              entry: log,
            );
            logEntities.add(logEntity);
          }
        }
      }
      
      // 批量保存更新的实体
      if (updatedEntities.isNotEmpty) {
        await _adapter.putMany<TaskEntity>(updatedEntities);
      }
      
      // 批量保存日志
      if (logEntities.isNotEmpty) {
        await _adapter.putMany<TaskLogEntity>(logEntities);
      }
    });
  }

  @override
  Future<int> clearAllTrashedTasks() {
    throw UnimplementedError('ObjectBoxTaskRepository.clearAllTrashedTasks');
  }

  @override
  Future<int> countArchivedTasks() {
    throw UnimplementedError('ObjectBoxTaskRepository.countArchivedTasks');
  }

  @override
  Future<int> countCompletedTasks() {
    throw UnimplementedError('ObjectBoxTaskRepository.countCompletedTasks');
  }

  @override
  Future<int> countTrashedTasks() {
    throw UnimplementedError('ObjectBoxTaskRepository.countTrashedTasks');
  }

  @override
  Future<Task> createTask(TaskDraft draft) async {
    final now = DateTime.now();
    final taskId = _uuid.v4();
    return createTaskWithId(draft, taskId, now, now);
  }

  @override
  Future<Task> createTaskWithId(
    TaskDraft draft,
    String taskId,
    DateTime createdAt,
    DateTime updatedAt,
  ) async {
    return await _adapter.writeTransaction(() async {
      final entity = TaskEntity(
        id: taskId,
        title: draft.title,
        statusIndex: taskStatusToIndex(draft.status),
        dueAt: draft.dueAt,
        startedAt: null, // draft 中没有 startedAt
        endedAt: null, // draft 中没有 endedAt
        archivedAt: null, // draft 中没有 archivedAt
        createdAt: createdAt,
        updatedAt: updatedAt,
        parentId: draft.parentId,
        projectId: draft.projectId,
        milestoneId: draft.milestoneId,
        sortIndex: draft.sortIndex,
        tags: List<String>.from(draft.tags),
        templateLockCount: 0, // TaskDraft 中没有 templateLockCount 字段，默认为 0
        seedSlug: draft.seedSlug,
        allowInstantComplete: draft.allowInstantComplete,
        description: draft.description,
      );

      // 使用新的 DatabaseAdapter API
      // 注意：ObjectBox put 会修改实体的 obxId，所以直接使用 entity
      await _adapter.put<TaskEntity>(entity);
      
      // 获取 obxId（ObjectBox put 会设置实体的 obxId）
      final obxId = entity.obxId;

      // 保存日志（如果有）
      if (draft.logs.isNotEmpty) {
        final logEntities = draft.logs
            .map((log) => _createLogEntity(
                  taskId: taskId,
                  taskObxId: obxId,
                  entry: log,
                ))
            .toList();
        await _adapter.putMany<TaskLogEntity>(logEntities);
      }

      return _toTask(entity, draft.logs);
    });
  }

  /// 创建 TaskLogEntity
  TaskLogEntity _createLogEntity({
    required String taskId,
    required int taskObxId,
    required TaskLogEntry entry,
  }) {
    final logEntity = TaskLogEntity(
      id: _uuid.v4(),
      taskId: taskId,
      timestamp: entry.timestamp,
      action: entry.action,
      previous: entry.previous,
      next: entry.next,
      actor: entry.actor,
    );
    logEntity.task.targetId = taskObxId;
    return logEntity;
  }

  @override
  Future<void> markStatus({
    required String taskId,
    required TaskStatus status,
  }) {
    throw UnimplementedError('ObjectBoxTaskRepository.markStatus');
  }

  @override
  Future<void> moveTask({
    required String taskId,
    required String? targetParentId,
    required TaskSection targetSection,
    required double sortIndex,
    DateTime? dueAt,
  }) {
    throw UnimplementedError('ObjectBoxTaskRepository.moveTask');
  }

  @override
  Future<int> purgeObsolete(DateTime olderThan) {
    throw UnimplementedError('ObjectBoxTaskRepository.purgeObsolete');
  }

  @override
  Future<void> softDelete(String taskId) async {
    await updateTask(
      taskId,
      const TaskUpdate(status: TaskStatus.trashed),
    );
  }

  @override
  Future<List<Task>> listAll() async {
    return await _adapter.readTransaction(() async {
      // 使用新的 DatabaseAdapter API
      final entities = await _adapter.findAll<TaskEntity>();
      if (entities.isEmpty) {
        return <Task>[];
      }

      // 加载所有任务的日志
      final logEntities = await _adapter.findAll<TaskLogEntity>();
      final logsByTask = _loadLogsForTasksFromEntities(
        logEntities,
        entities.map((e) => e.id).toList(),
      );

      return entities
          .map(
            (entity) => _toTask(
              entity,
              logsByTask[entity.id] ?? const <TaskLogEntry>[],
            ),
          )
          .toList(growable: false);
    });
  }

  /// 加载任务的日志（从实体列表）
  Map<String, List<TaskLogEntry>> _loadLogsForTasksFromEntities(
    List<TaskLogEntity> logEntities,
    List<String> taskIds,
  ) {
    if (taskIds.isEmpty) {
      return {};
    }

    final logsByTask = <String, List<TaskLogEntry>>{};

    for (final log in logEntities) {
      if (log.taskId != null && taskIds.contains(log.taskId)) {
        logsByTask.putIfAbsent(log.taskId!, () => []).add(_toLogEntry(log));
      }
    }

    return logsByTask;
  }

  /// 将 TaskEntity 转换为 Task
  Task _toTask(TaskEntity entity, List<TaskLogEntry> logs) {
    return Task(
      id: entity.id,
      title: entity.title,
      status: taskStatusFromIndex(entity.statusIndex),
      dueAt: entity.dueAt,
      startedAt: entity.startedAt,
      endedAt: entity.endedAt,
      archivedAt: entity.archivedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      parentId: entity.parentId,
      projectId: entity.projectId,
      milestoneId: entity.milestoneId,
      sortIndex: entity.sortIndex,
      tags: List<String>.unmodifiable(entity.tags),
      templateLockCount: entity.templateLockCount,
      seedSlug: entity.seedSlug,
      allowInstantComplete: entity.allowInstantComplete,
      description: entity.description,
      logs: List<TaskLogEntry>.unmodifiable(logs),
    );
  }

  /// 将 TaskLogEntity 转换为 TaskLogEntry
  TaskLogEntry _toLogEntry(TaskLogEntity entity) {
    return TaskLogEntry(
      timestamp: entity.timestamp,
      action: entity.action,
      previous: entity.previous,
      next: entity.next,
      actor: entity.actor,
    );
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
  }) {
    throw UnimplementedError('ObjectBoxTaskRepository.listArchivedTasks');
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
  }) {
    throw UnimplementedError('ObjectBoxTaskRepository.listTrashedTasks');
  }

  @override
  Future<List<Task>> listChildren(String parentId) async {
    return await _adapter.readTransaction(() async {
      // 子任务：parentId 匹配，且状态不是 trashed
      final entities = await _adapter.findAll<TaskEntity>();
      final childEntities = entities
          .where((e) =>
              e.parentId == parentId &&
              e.statusIndex != taskStatusToIndex(TaskStatus.trashed))
          .toList();

      if (childEntities.isEmpty) {
        return <Task>[];
      }

      // 加载日志
      final logEntities = await _adapter.findAll<TaskLogEntity>();
      final logsByTask = _loadLogsForTasksFromEntities(
        logEntities,
        childEntities.map((e) => e.id).toList(),
      );

      return childEntities
          .map(
            (entity) => _toTask(
              entity,
              logsByTask[entity.id] ?? const <TaskLogEntry>[],
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Future<List<Task>> listChildrenIncludingTrashed(String parentId) {
    throw UnimplementedError(
      'ObjectBoxTaskRepository.listChildrenIncludingTrashed',
    );
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
  }) {
    throw UnimplementedError('ObjectBoxTaskRepository.listCompletedTasks');
  }

  @override
  Future<List<Task>> listRoots() async {
    return await _adapter.readTransaction(() async {
      // 根任务：parentId 为 null
      final entities = await _adapter.findAll<TaskEntity>();
      final rootEntities = entities.where((e) => e.parentId == null).toList();

      if (rootEntities.isEmpty) {
        return <Task>[];
      }

      // 加载日志
      final logEntities = await _adapter.findAll<TaskLogEntity>();
      final logsByTask = _loadLogsForTasksFromEntities(
        logEntities,
        rootEntities.map((e) => e.id).toList(),
      );

      return rootEntities
          .map(
            (entity) => _toTask(
              entity,
              logsByTask[entity.id] ?? const <TaskLogEntry>[],
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Future<List<Task>> listSectionTasks(TaskSection section) async {
    return await _adapter.readTransaction(() async {
      final entities = await _adapter.findAll<TaskEntity>();
      
      // 根据 section 过滤任务
      final filteredEntities = entities.where((entity) {
        final status = taskStatusFromIndex(entity.statusIndex);
        
        switch (section) {
          case TaskSection.overdue:
            // 过期任务：状态为 pending/doing，且 dueAt < 今天
            if (status != TaskStatus.pending && status != TaskStatus.doing) {
              return false;
            }
            if (entity.dueAt == null) return false;
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            return entity.dueAt!.isBefore(today);
            
          case TaskSection.today:
            // 今天：状态为 pending/doing，且 dueAt 是今天
            if (status != TaskStatus.pending && status != TaskStatus.doing) {
              return false;
            }
            if (entity.dueAt == null) return false;
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final tomorrow = today.add(const Duration(days: 1));
            return entity.dueAt!.isAfter(today) && entity.dueAt!.isBefore(tomorrow);
            
          case TaskSection.tomorrow:
            // 明天：状态为 pending/doing，且 dueAt 是明天
            if (status != TaskStatus.pending && status != TaskStatus.doing) {
              return false;
            }
            if (entity.dueAt == null) return false;
            final now = DateTime.now();
            final tomorrow = DateTime(now.year, now.month, now.day + 1);
            final dayAfterTomorrow = tomorrow.add(const Duration(days: 1));
            return entity.dueAt!.isAfter(tomorrow) && entity.dueAt!.isBefore(dayAfterTomorrow);
            
          case TaskSection.thisWeek:
            // 本周：状态为 pending/doing，且 dueAt 在本周
            if (status != TaskStatus.pending && status != TaskStatus.doing) {
              return false;
            }
            if (entity.dueAt == null) return false;
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final nextWeek = today.add(const Duration(days: 7));
            return entity.dueAt!.isAfter(today) && entity.dueAt!.isBefore(nextWeek);
            
          case TaskSection.thisMonth:
            // 本月：状态为 pending/doing，且 dueAt 在本月
            if (status != TaskStatus.pending && status != TaskStatus.doing) {
              return false;
            }
            if (entity.dueAt == null) return false;
            final now = DateTime.now();
            final thisMonth = DateTime(now.year, now.month, 1);
            final nextMonth = DateTime(now.year, now.month + 1, 1);
            return entity.dueAt!.isAfter(thisMonth) && entity.dueAt!.isBefore(nextMonth);
            
          case TaskSection.nextMonth:
            // 下月：状态为 pending/doing，且 dueAt 在下月
            if (status != TaskStatus.pending && status != TaskStatus.doing) {
              return false;
            }
            if (entity.dueAt == null) return false;
            final now = DateTime.now();
            final nextMonth = DateTime(now.year, now.month + 1, 1);
            final monthAfterNext = DateTime(now.year, now.month + 2, 1);
            return entity.dueAt!.isAfter(nextMonth) && entity.dueAt!.isBefore(monthAfterNext);
            
          case TaskSection.later:
            // 以后：状态为 pending/doing，且 dueAt 在下月之后或为 null
            if (status != TaskStatus.pending && status != TaskStatus.doing) {
              return false;
            }
            if (entity.dueAt == null) return true;
            final now = DateTime.now();
            final monthAfterNext = DateTime(now.year, now.month + 2, 1);
            return entity.dueAt!.isAfter(monthAfterNext);
            
          case TaskSection.completed:
            return status == TaskStatus.completedActive;
            
          case TaskSection.archived:
            return status == TaskStatus.archived;
            
          case TaskSection.trash:
            return status == TaskStatus.trashed;
        }
      }).toList();

      if (filteredEntities.isEmpty) {
        return <Task>[];
      }

      // 加载日志
      final logEntities = await _adapter.findAll<TaskLogEntity>();
      final logsByTask = _loadLogsForTasksFromEntities(
        logEntities,
        filteredEntities.map((e) => e.id).toList(),
      );

      return filteredEntities
          .map(
            (entity) => _toTask(
              entity,
              logsByTask[entity.id] ?? const <TaskLogEntry>[],
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Future<List<Task>> listTasksByMilestoneId(String milestoneId) {
    throw UnimplementedError('ObjectBoxTaskRepository.listTasksByMilestoneId');
  }

  @override
  Future<List<Task>> searchByTitle(
    String query, {
    TaskStatus? status,
    int limit = 50,
  }) {
    throw UnimplementedError('ObjectBoxTaskRepository.searchByTitle');
  }

  @override
  Future<void> updateTask(String taskId, TaskUpdate payload) async {
    await _adapter.writeTransaction(() async {
      final entity = await _findEntityByBusinessId(taskId);
      if (entity == null) {
        throw StateError('Task not found: $taskId');
      }

      if (payload.title != null) {
        entity.title = payload.title!;
      }
      if (payload.status != null) {
        entity.statusIndex = taskStatusToIndex(payload.status!);
      }
      if (payload.dueAt != null) {
        entity.dueAt = payload.dueAt;
      }
      if (payload.startedAt != null) {
        entity.startedAt = payload.startedAt;
      }
      if (payload.endedAt != null) {
        entity.endedAt = payload.endedAt;
      }
      if (payload.archivedAt != null) {
        entity.archivedAt = payload.archivedAt;
      }
      if (payload.sortIndex != null) {
        entity.sortIndex = payload.sortIndex!;
      }
      if (payload.tags != null) {
        entity.tags = List<String>.from(payload.tags!);
      }
      if (payload.templateLockDelta != 0) {
        final nextValue = entity.templateLockCount + payload.templateLockDelta;
        entity.templateLockCount = nextValue < 0 ? 0 : nextValue;
      }
      if (payload.allowInstantComplete != null) {
        entity.allowInstantComplete = payload.allowInstantComplete!;
      }
      if (payload.description != null) {
        entity.description = payload.description;
      }
      if (payload.clearParent == true) {
        entity.parentId = null;
        entity.parent.targetId = 0;
      } else       if (payload.parentId != null) {
        entity.parentId = payload.parentId;
        // 如果需要设置 ObjectBox 关系，需要查找父任务的 obxId
        final parentTask = await _findEntityByBusinessId(payload.parentId!);
        if (parentTask == null) {
          throw StateError('Parent task ${payload.parentId} not found');
        }
        entity.parent.targetId = parentTask.obxId;
      }
      if (payload.clearProject == true) {
        entity.projectId = null;
        entity.project.targetId = 0;
      } else if (payload.projectId != null) {
        entity.projectId = payload.projectId;
        // 如果需要设置 ObjectBox 关系，需要查找项目的 obxId
        final projects = await _adapter.findAll<ProjectEntity>();
        final project = projects.firstWhere(
              (p) => p.id == payload.projectId,
              orElse: () => throw StateError(
                'Project ${payload.projectId} not found',
              ),
            );
        entity.project.targetId = project.obxId;
      }
      if (payload.clearMilestone == true) {
        entity.milestoneId = null;
        entity.milestone.targetId = 0;
      } else if (payload.milestoneId != null) {
        entity.milestoneId = payload.milestoneId;
        // 如果需要设置 ObjectBox 关系，需要查找里程碑的 obxId
        final milestones = await _adapter.findAll<MilestoneEntity>();
        final milestone = milestones.firstWhere(
              (m) => m.id == payload.milestoneId,
              orElse: () => throw StateError(
                'Milestone ${payload.milestoneId} not found',
              ),
            );
        entity.milestone.targetId = milestone.obxId;
      }

      entity.updatedAt = DateTime.now();
      await _adapter.put<TaskEntity>(entity);

      // 保存日志（如果有）
      if (payload.logs != null && payload.logs!.isNotEmpty) {
        final logEntities = payload.logs!
            .map((log) => _createLogEntity(
                  taskId: taskId,
                  taskObxId: entity.obxId,
                  entry: log,
                ))
            .toList();
        await _adapter.putMany<TaskLogEntity>(logEntities);
      }
    });
  }

  /// 查找任务实体（通过业务 ID）
  Future<TaskEntity?> _findEntityByBusinessId(String id) async {
    // 使用 DatabaseAdapter 查询所有任务，然后过滤
    // TODO: 优化为使用 QueryBuilder 查询
    final entities = await _adapter.findAll<TaskEntity>();
    for (final entity in entities) {
      if (entity.id == id) {
        return entity;
      }
    }
    return null;
  }

  @override
  Future<Task?> findById(String id) async {
    return await _adapter.readTransaction(() async {
      final entity = await _findEntityByBusinessId(id);
      if (entity == null) {
        return null;
      }

      // 加载日志
      final logEntities = await _adapter.findAll<TaskLogEntity>();
      final logs = logEntities
          .where((log) => log.taskId == id)
          .map(_toLogEntry)
          .toList();

      return _toTask(entity, logs);
    });
  }

  @override
  Future<Task?> findBySlug(String slug) async {
    return await _adapter.readTransaction(() async {
      // 使用 DatabaseAdapter 查询所有任务，然后过滤
      // TODO: 优化为使用 QueryBuilder 查询
      final entities = await _adapter.findAll<TaskEntity>();
      
      for (final entity in entities) {
        if (entity.seedSlug == slug) {
          // 加载日志
          final logEntities = await _adapter.findAll<TaskLogEntity>();
          final logs = logEntities
              .where((log) => log.taskId == entity.id)
              .map(_toLogEntry)
              .toList();
          return _toTask(entity, logs);
        }
      }
      return null;
    });
  }

  @override
  Future<Task?> findByTaskId(String taskId) async {
    // findByTaskId 和 findById 相同（都是通过业务 ID 查找）
    return findById(taskId);
  }

  @override
  Stream<List<Task>> watchInbox() {
    // Inbox 任务：状态为 inbox 或 pending/doing（未完成的任务）
    return _adapter.watch<TaskEntity>((builder) {
      return builder
        ..filter((entity) {
          final status = taskStatusFromIndex(entity.statusIndex);
          return status == TaskStatus.inbox ||
              status == TaskStatus.pending ||
              status == TaskStatus.doing;
        });
    }).asyncMap((entities) async {
      if (entities.isEmpty) {
        return <Task>[];
      }

      // 加载日志
      final logEntities = await _adapter.findAll<TaskLogEntity>();
      final logsByTask = _loadLogsForTasksFromEntities(
        logEntities,
        entities.map((e) => e.id).toList(),
      );

      return entities
          .map(
            (entity) => _toTask(
              entity,
              logsByTask[entity.id] ?? const <TaskLogEntry>[],
            ),
          )
          .toList(growable: false);
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
    throw UnimplementedError('ObjectBoxTaskRepository.watchInboxFiltered');
  }

  @override
  Stream<List<Task>> watchMilestones(String projectId) {
    throw UnimplementedError('ObjectBoxTaskRepository.watchMilestones');
  }

  @override
  Stream<List<Task>> watchProjects() {
    throw UnimplementedError('ObjectBoxTaskRepository.watchProjects');
  }

  @override
  Stream<List<Task>> watchQuickTasks() {
    throw UnimplementedError('ObjectBoxTaskRepository.watchQuickTasks');
  }

  @override
  Stream<List<Task>> watchSection(TaskSection section) {
    // 使用 DatabaseAdapter 的 watch 方法监听任务变化
    return _adapter.watch<TaskEntity>((builder) {
      return builder
        ..filter((entity) {
          final status = taskStatusFromIndex(entity.statusIndex);
          
          switch (section) {
            case TaskSection.overdue:
              // 过期任务：状态为 pending/doing，且 dueAt < 今天
              if (status != TaskStatus.pending && status != TaskStatus.doing) {
                return false;
              }
              if (entity.dueAt == null) return false;
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              return entity.dueAt!.isBefore(today);
              
            case TaskSection.today:
              // 今天：状态为 pending/doing，且 dueAt 是今天
              if (status != TaskStatus.pending && status != TaskStatus.doing) {
                return false;
              }
              if (entity.dueAt == null) return false;
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final tomorrow = today.add(const Duration(days: 1));
              return entity.dueAt!.isAfter(today) && entity.dueAt!.isBefore(tomorrow);
              
            case TaskSection.tomorrow:
              // 明天：状态为 pending/doing，且 dueAt 是明天
              if (status != TaskStatus.pending && status != TaskStatus.doing) {
                return false;
              }
              if (entity.dueAt == null) return false;
              final now = DateTime.now();
              final tomorrow = DateTime(now.year, now.month, now.day + 1);
              final dayAfterTomorrow = tomorrow.add(const Duration(days: 1));
              return entity.dueAt!.isAfter(tomorrow) && entity.dueAt!.isBefore(dayAfterTomorrow);
              
            case TaskSection.thisWeek:
              // 本周：状态为 pending/doing，且 dueAt 在本周
              if (status != TaskStatus.pending && status != TaskStatus.doing) {
                return false;
              }
              if (entity.dueAt == null) return false;
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final nextWeek = today.add(const Duration(days: 7));
              return entity.dueAt!.isAfter(today) && entity.dueAt!.isBefore(nextWeek);
              
            case TaskSection.thisMonth:
              // 本月：状态为 pending/doing，且 dueAt 在本月
              if (status != TaskStatus.pending && status != TaskStatus.doing) {
                return false;
              }
              if (entity.dueAt == null) return false;
              final now = DateTime.now();
              final thisMonth = DateTime(now.year, now.month, 1);
              final nextMonth = DateTime(now.year, now.month + 1, 1);
              return entity.dueAt!.isAfter(thisMonth) && entity.dueAt!.isBefore(nextMonth);
              
            case TaskSection.nextMonth:
              // 下月：状态为 pending/doing，且 dueAt 在下月
              if (status != TaskStatus.pending && status != TaskStatus.doing) {
                return false;
              }
              if (entity.dueAt == null) return false;
              final now = DateTime.now();
              final nextMonth = DateTime(now.year, now.month + 1, 1);
              final monthAfterNext = DateTime(now.year, now.month + 2, 1);
              return entity.dueAt!.isAfter(nextMonth) && entity.dueAt!.isBefore(monthAfterNext);
              
            case TaskSection.later:
              // 以后：状态为 pending/doing，且 dueAt 在下月之后或为 null
              if (status != TaskStatus.pending && status != TaskStatus.doing) {
                return false;
              }
              if (entity.dueAt == null) return true;
              final now = DateTime.now();
              final monthAfterNext = DateTime(now.year, now.month + 2, 1);
              return entity.dueAt!.isAfter(monthAfterNext);
              
            case TaskSection.completed:
              return status == TaskStatus.completedActive;
              
            case TaskSection.archived:
              return status == TaskStatus.archived;
              
            case TaskSection.trash:
              return status == TaskStatus.trashed;
          }
        });
    }).asyncMap((entities) async {
      if (entities.isEmpty) {
        return <Task>[];
      }

      // 加载日志
      final logEntities = await _adapter.findAll<TaskLogEntity>();
      final logsByTask = _loadLogsForTasksFromEntities(
        logEntities,
        entities.map((e) => e.id).toList(),
      );

      return entities
          .map(
            (entity) => _toTask(
              entity,
              logsByTask[entity.id] ?? const <TaskLogEntry>[],
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Stream<List<Task>> watchTasksByMilestoneId(String milestoneId) {
    return _adapter.watch<TaskEntity>((builder) {
      return builder
        ..filter((entity) => entity.milestoneId == milestoneId);
    }).asyncMap((entities) async {
      if (entities.isEmpty) {
        return <Task>[];
      }

      // 加载日志
      final logEntities = await _adapter.findAll<TaskLogEntity>();
      final logsByTask = _loadLogsForTasksFromEntities(
        logEntities,
        entities.map((e) => e.id).toList(),
      );

      return entities
          .map(
            (entity) => _toTask(
              entity,
              logsByTask[entity.id] ?? const <TaskLogEntry>[],
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Stream<List<Task>> watchTasksByProjectId(String projectId) {
    return _adapter.watch<TaskEntity>((builder) {
      return builder
        ..filter((entity) => entity.projectId == projectId);
    }).asyncMap((entities) async {
      if (entities.isEmpty) {
        return <Task>[];
      }

      // 加载日志
      final logEntities = await _adapter.findAll<TaskLogEntity>();
      final logsByTask = _loadLogsForTasksFromEntities(
        logEntities,
        entities.map((e) => e.id).toList(),
      );

      return entities
          .map(
            (entity) => _toTask(
              entity,
              logsByTask[entity.id] ?? const <TaskLogEntry>[],
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Stream<Task?> watchTaskById(String id) {
    return _adapter.watch<TaskEntity>((builder) {
      return builder
        ..filter((entity) => entity.id == id);
    }).asyncMap((entities) async {
      if (entities.isEmpty) {
        return null;
      }

      final entity = entities.first;
      
      // 加载日志
      final logEntities = await _adapter.findAll<TaskLogEntity>();
      final logs = logEntities
          .where((log) => log.taskId == id)
          .map(_toLogEntry)
          .toList();

      return _toTask(entity, logs);
    });
  }

  @override
  Stream<TaskTreeNode> watchTaskTree(String rootTaskId) {
    throw UnimplementedError('ObjectBoxTaskRepository.watchTaskTree');
  }
}
