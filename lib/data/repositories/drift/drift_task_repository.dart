import 'dart:async';

import 'package:drift/drift.dart';

import '../../../core/utils/task_section_utils.dart';
import '../../database/database_adapter.dart';
import '../../drift/database.dart' hide Task, TaskLog;
import '../../drift/database.dart' as drift show Task, TaskLog;
import '../../drift/converters.dart';
import '../../models/task.dart' as domain;
import '../../models/task_log_entry.dart';
import '../task_repository.dart';

/// Drift 版本的 TaskRepository 实现
class DriftTaskRepository implements TaskRepository {
  DriftTaskRepository(this._adapter);

  final DatabaseAdapter _adapter;

  /// 获取 AppDatabase 实例
  AppDatabase get _db => AppDatabase.instance;

  @override
  Stream<List<domain.Task>> watchSection(domain.TaskSection section) {
    final query = _db.select(_db.tasks);
    final now = DateTime.now();

    // 使用 TaskSectionUtils 统一边界定义（严禁修改）
    switch (section) {
      case domain.TaskSection.overdue:
        // 已逾期：[~, <今天00:00:00)
        final today = TaskSectionUtils.getSectionEndTimeForQuery(section, now: now);
        query.where((t) =>
            t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index, domain.TaskStatus.paused.index]) &
            t.dueAt.isNotNull() &
            t.dueAt.isSmallerThanValue(today));
        break;
      case domain.TaskSection.today:
        // 今天：[>=今天00:00:00, <明天00:00:00)
        final startTime = TaskSectionUtils.getSectionStartTime(section, now: now);
        final endTime = TaskSectionUtils.getSectionEndTimeForQuery(section, now: now);
        query.where((t) =>
            t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index, domain.TaskStatus.paused.index]) &
            t.dueAt.isNotNull() &
            t.dueAt.isBiggerOrEqualValue(startTime) &
            t.dueAt.isSmallerThanValue(endTime));
        break;
      case domain.TaskSection.tomorrow:
        // 明天：[>=明天00:00:00, <后天00:00:00)
        final startTime = TaskSectionUtils.getSectionStartTime(section, now: now);
        final endTime = TaskSectionUtils.getSectionEndTimeForQuery(section, now: now);
        query.where((t) =>
            t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index, domain.TaskStatus.paused.index]) &
            t.dueAt.isNotNull() &
            t.dueAt.isBiggerOrEqualValue(startTime) &
            t.dueAt.isSmallerThanValue(endTime));
        break;
      case domain.TaskSection.thisWeek:
        // 本周：[>=后天00:00:00, <下周日00:00:00) （如果今天是周六，则为空范围）
        final startTime = TaskSectionUtils.getSectionStartTime(section, now: now);
        final endTime = TaskSectionUtils.getSectionEndTimeForQuery(section, now: now);
        // 检查是否为空范围（今天是周六时，startTime >= endTime）
        if (startTime.isBefore(endTime)) {
        query.where((t) =>
              t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index, domain.TaskStatus.paused.index]) &
            t.dueAt.isNotNull() &
              t.dueAt.isBiggerOrEqualValue(startTime) &
              t.dueAt.isSmallerThanValue(endTime));
        } else {
          // 空范围，返回空结果
          query.where((t) => t.id.equals('__empty__'));
        }
        break;
      case domain.TaskSection.thisMonth:
        // 当月：[>=下周日00:00:00, <下月1日00:00:00) （如果本周跨月，则为空范围）
        final startTime = TaskSectionUtils.getSectionStartTime(section, now: now);
        final endTime = TaskSectionUtils.getSectionEndTimeForQuery(section, now: now);
        // 检查是否为空范围
        if (startTime.isBefore(endTime)) {
        query.where((t) =>
              t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index, domain.TaskStatus.paused.index]) &
            t.dueAt.isNotNull() &
              t.dueAt.isBiggerOrEqualValue(startTime) &
              t.dueAt.isSmallerThanValue(endTime));
        } else {
          // 空范围，返回空结果
          query.where((t) => t.id.equals('__empty__'));
        }
        break;
      case domain.TaskSection.nextMonth:
        // 下月：[>=下月1日00:00:00, <下下月1日00:00:00)
        final startTime = TaskSectionUtils.getSectionStartTime(section, now: now);
        final endTime = TaskSectionUtils.getSectionEndTimeForQuery(section, now: now);
        query.where((t) =>
            t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index, domain.TaskStatus.paused.index]) &
            t.dueAt.isNotNull() &
            t.dueAt.isBiggerOrEqualValue(startTime) &
            t.dueAt.isSmallerThanValue(endTime));
        break;
      case domain.TaskSection.later:
        // 以后：[>=下下月1日00:00:00, ~)
        final startTime = TaskSectionUtils.getSectionStartTime(section, now: now);
        query.where((t) =>
            t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index, domain.TaskStatus.paused.index]) &
            (t.dueAt.isNull() | t.dueAt.isBiggerOrEqualValue(startTime)));
        break;
      case domain.TaskSection.completed:
        query.where((t) => t.status.equals(domain.TaskStatus.completedActive.index));
        break;
      case domain.TaskSection.archived:
        query.where((t) => t.status.equals(domain.TaskStatus.archived.index));
        break;
      case domain.TaskSection.trash:
        query.where((t) => t.status.equals(domain.TaskStatus.trashed.index));
        break;
    }

    return query.watch().asyncMap((entities) async {
      if (entities.isEmpty) return <domain.Task>[];
      return await _toTasks(entities);
    });
  }

  @override
  Stream<domain.TaskTreeNode> watchTaskTree(String rootTaskId) {
    // 监听根任务及其所有子任务的变化
    // 策略：
    // 1. 监听根任务的变化
    // 2. 监听所有子任务的变化（通过监听所有任务的 Stream，然后过滤出属于这棵树的）
    // 3. 当任何相关任务变化时，重新构建整个树
    // 
    // 注意：由于需要监听所有子任务，我们使用 watchAllTasks 然后过滤
    // 这是一个权衡：性能 vs 实时性
    return _watchAllTasksForTree(rootTaskId)
        .asyncMap((_) => _buildTaskTreeFromId(rootTaskId))
        .distinct((prev, next) => _taskTreeEquals(prev, next));
  }

  /// 监听任务树中所有任务的变化
  ///
  /// [rootTaskId] 根任务 ID
  /// 返回一个 Stream，当树中任何任务变化时触发
  ///
  /// 策略：监听根任务的变化，当根任务变化时重新构建整个树
  /// 这样可以捕获根任务及其所有子任务的变化（因为子任务变化会触发父任务的 updatedAt 更新）
  /// 注意：这是一个简化的实现，如果需要更细粒度的监听，可以后续优化
  Stream<void> _watchAllTasksForTree(String rootTaskId) {
    // 监听根任务的变化
    return watchTaskById(rootTaskId).map((_) => null);
  }

  /// 从任务 ID 构建任务树
  ///
  /// [rootTaskId] 根任务 ID
  /// 返回包含根任务及其所有子任务的 TaskTreeNode
  Future<domain.TaskTreeNode> _buildTaskTreeFromId(String rootTaskId) async {
    final rootTask = await findById(rootTaskId);
    if (rootTask == null) {
      throw StateError('Root task not found: $rootTaskId');
    }
    return await _buildTaskTreeFromRoot(rootTask);
  }

  /// 从根任务构建任务树（层级功能已移除，只返回单个任务）
  ///
  /// [rootTask] 根任务
  /// 返回只包含根任务的 TaskTreeNode（没有子任务）
  Future<domain.TaskTreeNode> _buildTaskTreeFromRoot(domain.Task rootTask) async {
    // 层级功能已移除，不再有子任务
    return domain.TaskTreeNode(
      task: rootTask,
      children: const <domain.TaskTreeNode>[],
    );
  }

  /// 比较两个任务树是否相等
  ///
  /// 用于 Stream.distinct，避免不必要的重建
  bool _taskTreeEquals(domain.TaskTreeNode a, domain.TaskTreeNode b) {
    if (a.task.id != b.task.id) return false;
    if (a.task.updatedAt != b.task.updatedAt) return false;
    if (a.children.length != b.children.length) return false;

    // 递归比较子节点
    for (var i = 0; i < a.children.length; i++) {
      if (!_taskTreeEquals(a.children[i], b.children[i])) {
        return false;
      }
    }

    return true;
  }

  @override
  Stream<List<domain.Task>> watchInbox() {
    // Inbox 任务：状态为 inbox 或 pending/doing（未完成的任务）
    final query = _db.select(_db.tasks)
      ..where((t) => t.status.isIn([
            domain.TaskStatus.inbox.index,
            domain.TaskStatus.pending.index,
            domain.TaskStatus.doing.index,
          ]));
    return query.watch().asyncMap((entities) async {
      if (entities.isEmpty) return <domain.Task>[];
      return await _toTasks(entities);
    });
  }

  @override
  @Deprecated('使用 ProjectRepository 和 ProjectService 替代')
  Stream<List<domain.Task>> watchProjects() {
    // 项目任务：有 projectId 的任务
    // 状态为 inbox、pending 或 doing
    final query = _db.select(_db.tasks)
      ..where((t) =>
          t.projectId.isNotNull() &
          t.status.isIn([
            domain.TaskStatus.inbox.index,
            domain.TaskStatus.pending.index,
            domain.TaskStatus.doing.index,
          ]));
    return query.watch().asyncMap((entities) async {
      if (entities.isEmpty) return <domain.Task>[];
      return await _toTasks(entities);
    });
  }

  @override
  Stream<List<domain.Task>> watchQuickTasks() {
    // 快速任务：没有父任务、没有项目、没有里程碑的独立任务
    // 状态为 inbox、pending 或 doing
    final query = _db.select(_db.tasks)
      ..where((t) =>
          t.parentId.isNull() &
          t.projectId.isNull() &
          t.milestoneId.isNull() &
          t.status.isIn([
            domain.TaskStatus.inbox.index,
            domain.TaskStatus.pending.index,
            domain.TaskStatus.doing.index,
          ]));
    return query.watch().asyncMap((entities) async {
      if (entities.isEmpty) return <domain.Task>[];
      return await _toTasks(entities);
    });
  }

  @override
  @Deprecated('使用 MilestoneRepository 和 MilestoneService 替代')
  Stream<List<domain.Task>> watchMilestones(String projectId) {
    // 里程碑任务：属于指定项目的里程碑任务
    // 状态为 inbox、pending 或 doing
    final query = _db.select(_db.tasks)
      ..where((t) =>
          t.projectId.equals(projectId) &
          t.milestoneId.isNotNull() &
          t.status.isIn([
            domain.TaskStatus.inbox.index,
            domain.TaskStatus.pending.index,
            domain.TaskStatus.doing.index,
          ]));
    return query.watch().asyncMap((entities) async {
      if (entities.isEmpty) return <domain.Task>[];
      return await _toTasks(entities);
    });
  }

  @override
  Stream<List<domain.Task>> watchTasksByProjectId(String projectId) {
    final query = _db.select(_db.tasks)
      ..where((t) => t.projectId.equals(projectId));
    return query.watch().asyncMap((entities) async {
      if (entities.isEmpty) return <domain.Task>[];
      return await _toTasks(entities);
    });
  }

  @override
  Stream<List<domain.Task>> watchTasksByMilestoneId(String milestoneId) {
    final query = _db.select(_db.tasks)
      ..where((t) => t.milestoneId.equals(milestoneId));
    return query.watch().asyncMap((entities) async {
      if (entities.isEmpty) return <domain.Task>[];
      return await _toTasks(entities);
    });
  }

  @override
  Future<List<domain.Task>> listTasksByMilestoneId(String milestoneId) async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.tasks)
        ..where((t) => t.milestoneId.equals(milestoneId));
      final entities = await query.get();
      return await _toTasks(entities);
    });
  }

  @override
  Stream<List<domain.Task>> watchInboxFiltered({
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  }) {
    final query = _db.select(_db.tasks)
      ..where((t) => t.status.isIn([
            domain.TaskStatus.inbox.index,
            domain.TaskStatus.pending.index,
            domain.TaskStatus.doing.index,
            domain.TaskStatus.paused.index,
          ]));

    // 应用项目/里程碑过滤条件
    if (projectId != null) {
      query.where((t) => t.projectId.equals(projectId));
    }
    if (milestoneId != null) {
      query.where((t) => t.milestoneId.equals(milestoneId));
    }
    if (showNoProject == true) {
      query.where((t) => t.projectId.isNull());
    }

    return query.watch().asyncMap((entities) async {
      if (entities.isEmpty) return <domain.Task>[];

      // 应用标签过滤（在内存中过滤，因为标签存储在 JSON 中）
      final filtered = _applyTagFilters(
        entities,
        contextTag: contextTag,
        priorityTag: priorityTag,
        urgencyTag: urgencyTag,
        importanceTag: importanceTag,
      );

      return await _toTasks(filtered);
    });
  }

  @override
  Future<domain.Task> createTask(domain.TaskDraft draft) async {
    final now = DateTime.now();
    final taskId = generateUuid();
    return createTaskWithId(draft, taskId, now, now);
  }

  @override
  Future<domain.Task> createTaskWithId(
    domain.TaskDraft draft,
    String taskId,
    DateTime createdAt,
    DateTime updatedAt,
  ) async {
    return await _adapter.writeTransaction(() async {
      final entity = drift.Task(
        id: taskId,
        title: draft.title,
        status: draft.status,
        dueAt: draft.dueAt,
        startedAt: null,
        endedAt: null,
        archivedAt: null,
        createdAt: createdAt,
        updatedAt: updatedAt,
        parentId: null, // 层级功能已移除，数据库列仍存在但不再使用
        projectId: draft.projectId,
        milestoneId: draft.milestoneId,
        sortIndex: draft.sortIndex,
        tags: List<String>.from(draft.tags),
        templateLockCount: 0,
        seedSlug: draft.seedSlug,
        allowInstantComplete: draft.allowInstantComplete,
        description: draft.description,
      );

      await _db.into(_db.tasks).insert(entity);

      // 保存日志（如果有）
      if (draft.logs.isNotEmpty) {
        final logEntities = draft.logs
            .map((log) => drift.TaskLog(
                  id: generateUuid(),
                  taskId: taskId,
                  timestamp: log.timestamp,
                  action: log.action,
                  previous: log.previous,
                  next: log.next,
                  actor: log.actor,
                ))
            .toList();
        for (final logEntity in logEntities) {
          await _db.into(_db.taskLogs).insert(logEntity);
        }
      }

      return _toTask(entity, draft.logs);
    });
  }

  @override
  Future<void> updateTask(String taskId, domain.TaskUpdate payload) async {
    await _adapter.writeTransaction(() async {
      final query = _db.select(_db.tasks)..where((t) => t.id.equals(taskId));
      final existing = await query.getSingleOrNull();
      if (existing == null) {
        throw StateError('Task not found: $taskId');
      }

      // 计算 projectId 和 milestoneId 的值
      final projectIdValue = payload.projectId != null 
          ? Value<String?>(payload.projectId!) 
          : (payload.clearProject == true ? Value<String?>(null) : const Value<String?>.absent());
      final milestoneIdValue = payload.milestoneId != null 
          ? Value<String?>(payload.milestoneId) 
          : (payload.clearMilestone == true ? Value<String?>(null) : const Value<String?>.absent());

      // 计算最终的 dueAt 值
      final finalDueAt = payload.dueAt ?? existing.dueAt;
      
      // 底层规则：如果任务有截止日期，状态一定不是 inbox
      // 如果最终有截止日期，且当前状态是 inbox，且 payload 没有明确指定状态，则自动改为 pending
      final finalStatus = payload.status ??
          (finalDueAt != null && existing.status == domain.TaskStatus.inbox
              ? domain.TaskStatus.pending
              : null);

      final companion = TasksCompanion(
        id: const Value.absent(),
        title: payload.title != null ? Value(payload.title!) : const Value.absent(),
        status: finalStatus != null ? Value(finalStatus) : const Value.absent(),
        dueAt: payload.dueAt != null ? Value(payload.dueAt) : const Value.absent(),
        startedAt: payload.startedAt != null ? Value(payload.startedAt) : const Value.absent(),
        endedAt: payload.endedAt != null ? Value(payload.endedAt) : const Value.absent(),
        archivedAt: payload.archivedAt != null ? Value(payload.archivedAt) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
        parentId: const Value<String?>.absent(), // 层级功能已移除，数据库列仍存在但不再使用
        projectId: projectIdValue,
        milestoneId: milestoneIdValue,
        sortIndex: payload.sortIndex != null ? Value(payload.sortIndex!) : const Value.absent(),
        tags: payload.tags != null ? Value(payload.tags!) : const Value.absent(),
        templateLockCount: payload.templateLockDelta != 0 ? Value(existing.templateLockCount + payload.templateLockDelta) : const Value.absent(),
        seedSlug: const Value.absent(),
        allowInstantComplete: payload.allowInstantComplete != null ? Value(payload.allowInstantComplete!) : const Value.absent(),
        description: payload.description != null ? Value(payload.description) : const Value.absent(),
      );

      await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(companion);

      // 处理日志
      if (payload.logs != null && payload.logs!.isNotEmpty) {
        for (final log in payload.logs!) {
          final logEntity = drift.TaskLog(
            id: generateUuid(),
            taskId: taskId,
            timestamp: log.timestamp,
            action: log.action,
            previous: log.previous,
            next: log.next,
            actor: log.actor,
          );
          await _db.into(_db.taskLogs).insert(logEntity);
        }
      }
    });
  }

  @override
  Future<void> moveTask({
    required String taskId,
    required String? targetParentId,
    required domain.TaskSection targetSection,
    required double sortIndex,
    DateTime? dueAt,
  }) async {
    await _adapter.writeTransaction(() async {
      // 查询当前任务状态，用于状态转换逻辑
      final query = _db.select(_db.tasks)..where((t) => t.id.equals(taskId));
      final existing = await query.getSingleOrNull();
      if (existing == null) {
        throw StateError('Task not found: $taskId');
      }

      var companion = TasksCompanion(
        parentId: const Value<String?>.absent(), // 层级功能已移除，数据库列仍存在但不再使用
        sortIndex: Value(sortIndex),
        dueAt: dueAt != null ? Value(dueAt) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      );

      // 根据 targetSection 更新状态
      TasksCompanion finalCompanion;
      switch (targetSection) {
        case domain.TaskSection.completed:
          // 获取完成时间，同步设置 dueAt 为完成时间
          final completedTime = DateTime.now();
          finalCompanion = companion.copyWith(
            status: Value(domain.TaskStatus.completedActive),
            endedAt: Value(completedTime),
            dueAt: Value(completedTime),  // 同步设置 dueAt 为完成时间
          );
          break;
        case domain.TaskSection.archived:
          finalCompanion = companion.copyWith(
            status: Value(domain.TaskStatus.archived),
            archivedAt: Value(DateTime.now()),
          );
          break;
        case domain.TaskSection.trash:
          finalCompanion = companion.copyWith(
            status: Value(domain.TaskStatus.trashed),
          );
          break;
        default:
          // 其他 section 保持当前状态
          finalCompanion = companion;
          // 底层规则：如果任务有截止日期，状态一定不是 inbox
          // 如果设置了 dueAt 且当前状态是 inbox，则自动改为 pending
          final finalDueAt = dueAt ?? existing.dueAt;
          if (finalDueAt != null && existing.status == domain.TaskStatus.inbox) {
            finalCompanion = finalCompanion.copyWith(
              status: Value(domain.TaskStatus.pending),
            );
          }
          break;
      }

      await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(finalCompanion);
    });
  }

  @override
  Future<void> markStatus({
    required String taskId,
    required domain.TaskStatus status,
  }) async {
    await _adapter.writeTransaction(() async {
      // 查询当前任务状态
      final query = _db.select(_db.tasks)..where((t) => t.id.equals(taskId));
      final existing = await query.getSingleOrNull();
      
      if (existing == null) {
        throw StateError('Task not found: $taskId');
      }

      // 检查是否从 pending 变为 doing，且还没有 startedAt
      final wasPending = existing.status == domain.TaskStatus.pending;
      final isDoing = status == domain.TaskStatus.doing;
      final shouldSetStartedAt = wasPending && isDoing && existing.startedAt == null;

      // 构建更新对象
      final companion = TasksCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        startedAt: shouldSetStartedAt ? Value(DateTime.now()) : const Value.absent(),
      );

      await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(companion);
    });
  }

  @override
  Future<void> archiveTask(String taskId) async {
    await _adapter.writeTransaction(() async {
      await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
        TasksCompanion(
          status: Value(domain.TaskStatus.archived),
          archivedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> softDelete(String taskId) async {
    await _adapter.writeTransaction(() async {
      await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
        TasksCompanion(
          status: Value(domain.TaskStatus.trashed),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<int> purgeObsolete(DateTime olderThan) async {
    // 清理过时的已删除/已归档任务
    // 条件：状态为 trashed 或 archived，且 updatedAt < olderThan
    return await _adapter.writeTransaction(() async {
      // 查找需要清理的任务
      final query = _db.select(_db.tasks)
        ..where((t) =>
            (t.status.equals(domain.TaskStatus.trashed.index) |
                t.status.equals(domain.TaskStatus.archived.index)) &
            t.updatedAt.isSmallerThanValue(olderThan));
      final entities = await query.get();

      if (entities.isEmpty) return 0;

      final ids = entities.map((e) => e.id).toList();
      var totalDeleted = 0;

      // 批量删除任务及其日志
      for (final id in ids) {
        // 删除任务日志（外键级联删除会自动处理，但为了明确性，我们手动删除）
        await (_db.delete(_db.taskLogs)..where((t) => t.taskId.equals(id))).go();
        // 删除任务
        await (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
        totalDeleted++;
      }

      return totalDeleted;
    });
  }

  @override
  Future<int> clearAllTrashedTasks() async {
    return await _adapter.writeTransaction(() async {
      final query = _db.select(_db.tasks)
        ..where((t) => t.status.equals(domain.TaskStatus.trashed.index));
      final entities = await query.get();
      final ids = entities.map((e) => e.id).toList();
      for (final id in ids) {
        await (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
      }
      return ids.length;
    });
  }

  @override
  Future<void> adjustTemplateLock({
    required String taskId,
    required int delta,
  }) async {
    await _adapter.writeTransaction(() async {
      final query = _db.select(_db.tasks)..where((t) => t.id.equals(taskId));
      final existing = await query.getSingleOrNull();
      if (existing == null) {
        throw StateError('Task not found: $taskId');
      }
      final nextValue = existing.templateLockCount + delta;
      await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
        TasksCompanion(
          templateLockCount: Value(nextValue < 0 ? 0 : nextValue),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<domain.Task?> findById(String id) async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.tasks)..where((t) => t.id.equals(id));
      final entity = await query.getSingleOrNull();
      if (entity == null) return null;
      return await _toTask(entity);
    });
  }

  @override
  Future<domain.Task?> findByTaskId(String taskId) {
    return findById(taskId);
  }

  @override
  Stream<domain.Task?> watchTaskById(String id) {
    final query = _db.select(_db.tasks)..where((t) => t.id.equals(id));
    return query.watchSingleOrNull().asyncMap((entity) async {
      if (entity == null) return null;
      return await _toTask(entity);
    });
  }

  @override
  Future<domain.Task?> findBySlug(String slug) async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.tasks)..where((t) => t.seedSlug.equals(slug));
      final entity = await query.getSingleOrNull();
      if (entity == null) return null;
      return await _toTask(entity);
    });
  }

  @override
  Future<List<domain.Task>> listRoots() async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.tasks)
        ..where((t) => t.parentId.isNull());
      final entities = await query.get();
      return await _toTasks(entities);
    });
  }


  @override
  Future<void> upsertTasks(List<domain.Task> tasks) async {
    if (tasks.isEmpty) return;

    await _adapter.writeTransaction(() async {
      for (final task in tasks) {
        final entity = drift.Task(
          id: task.id,
          title: task.title,
          status: task.status,
          dueAt: task.dueAt,
          startedAt: task.startedAt,
          endedAt: task.endedAt,
          archivedAt: task.archivedAt,
          createdAt: task.createdAt,
          updatedAt: task.updatedAt,
          parentId: null, // 层级功能已移除
          projectId: task.projectId,
          milestoneId: task.milestoneId,
          sortIndex: task.sortIndex,
          tags: List<String>.from(task.tags),
          templateLockCount: task.templateLockCount,
          seedSlug: task.seedSlug,
          allowInstantComplete: task.allowInstantComplete,
          description: task.description,
        );

        await _db.into(_db.tasks).insertOnConflictUpdate(entity);

        // 保存日志
        if (task.logs.isNotEmpty) {
          // 先删除旧日志
          await (_db.delete(_db.taskLogs)..where((t) => t.taskId.equals(task.id))).go();
          // 插入新日志
          final logEntities = task.logs
              .map((log) => drift.TaskLog(
                    id: generateUuid(),
                    taskId: task.id,
                    timestamp: log.timestamp,
                    action: log.action,
                    previous: log.previous,
                    next: log.next,
                    actor: log.actor,
                  ))
              .toList();
          for (final logEntity in logEntities) {
            await _db.into(_db.taskLogs).insert(logEntity);
          }
        }
      }
    });
  }

  @override
  Future<List<domain.Task>> listAll() async {
    return await _adapter.readTransaction(() async {
      final entities = await _db.select(_db.tasks).get();
      return await _toTasks(entities);
    });
  }

  @override
  Future<List<domain.Task>> searchByTitle(
    String query, {
    domain.TaskStatus? status,
    int limit = 10,
  }) async {
    return await _adapter.readTransaction(() async {
      final dbQuery = _db.select(_db.tasks)
        ..where((t) => t.title.like('%$query%'))
        ..limit(limit);
      if (status != null) {
        dbQuery.where((t) => t.status.equals(status.index));
      }
      final entities = await dbQuery.get();
      return await _toTasks(entities);
    });
  }

  @override
  Future<void> batchUpdate(Map<String, domain.TaskUpdate> updates) async {
    if (updates.isEmpty) return;

    await _adapter.writeTransaction(() async {
      for (final entry in updates.entries) {
        final taskId = entry.key;
        final payload = entry.value;

        final query = _db.select(_db.tasks)..where((t) => t.id.equals(taskId));
        final existing = await query.getSingleOrNull();
        if (existing == null) continue;

        final companion = TasksCompanion(
          title: payload.title != null ? Value(payload.title!) : const Value.absent(),
          status: payload.status != null ? Value(payload.status!) : const Value.absent(),
          dueAt: payload.dueAt != null ? Value(payload.dueAt) : const Value.absent(),
          startedAt: payload.startedAt != null ? Value(payload.startedAt) : const Value.absent(),
          endedAt: payload.endedAt != null ? Value(payload.endedAt) : const Value.absent(),
          archivedAt: payload.archivedAt != null ? Value(payload.archivedAt) : const Value.absent(),
          updatedAt: Value(DateTime.now()),
          parentId: const Value<String?>.absent(), // 层级功能已移除，数据库列仍存在但不再使用
          projectId: payload.projectId != null ? Value(payload.projectId) : (payload.clearProject == true ? Value<String?>(null) : const Value.absent()),
          milestoneId: payload.milestoneId != null ? Value(payload.milestoneId) : (payload.clearMilestone == true ? Value<String?>(null) : const Value.absent()),
          sortIndex: payload.sortIndex != null ? Value(payload.sortIndex!) : const Value.absent(),
          tags: payload.tags != null ? Value(payload.tags!) : const Value.absent(),
          templateLockCount: payload.templateLockDelta != 0 ? Value(existing.templateLockCount + payload.templateLockDelta) : const Value.absent(),
          allowInstantComplete: payload.allowInstantComplete != null ? Value(payload.allowInstantComplete!) : const Value.absent(),
          description: payload.description != null ? Value(payload.description) : const Value.absent(),
        );

        await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(companion);

        // 处理日志
        if (payload.logs != null && payload.logs!.isNotEmpty) {
          for (final log in payload.logs!) {
            final logEntity = drift.TaskLog(
              id: generateUuid(),
              taskId: taskId,
              timestamp: log.timestamp,
              action: log.action,
              previous: log.previous,
              next: log.next,
              actor: log.actor,
            );
            await _db.into(_db.taskLogs).insert(logEntity);
          }
        }
      }
    });
  }

  @override
  Future<List<domain.Task>> listSectionTasks(domain.TaskSection section) async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.tasks);
      final now = DateTime.now();

      // 使用 TaskSectionUtils 统一边界定义（严禁修改）
      switch (section) {
        case domain.TaskSection.overdue:
          // 已逾期：[~, <今天00:00:00)
          final today = TaskSectionUtils.getSectionEndTimeForQuery(section, now: now);
          query.where((t) =>
              t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index, domain.TaskStatus.paused.index]) &
              t.dueAt.isNotNull() &
              t.dueAt.isSmallerThanValue(today));
          break;
        case domain.TaskSection.today:
          // 今天：[>=今天00:00:00, <明天00:00:00)
          final startTime = TaskSectionUtils.getSectionStartTime(section, now: now);
          final endTime = TaskSectionUtils.getSectionEndTimeForQuery(section, now: now);
          query.where((t) =>
              t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index, domain.TaskStatus.paused.index]) &
              t.dueAt.isNotNull() &
              t.dueAt.isBiggerOrEqualValue(startTime) &
              t.dueAt.isSmallerThanValue(endTime));
          break;
        case domain.TaskSection.tomorrow:
          // 明天：[>=明天00:00:00, <后天00:00:00)
          final startTime = TaskSectionUtils.getSectionStartTime(section, now: now);
          final endTime = TaskSectionUtils.getSectionEndTimeForQuery(section, now: now);
          query.where((t) =>
              t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index, domain.TaskStatus.paused.index]) &
              t.dueAt.isNotNull() &
              t.dueAt.isBiggerOrEqualValue(startTime) &
              t.dueAt.isSmallerThanValue(endTime));
          break;
        case domain.TaskSection.thisWeek:
          // 本周：[>=后天00:00:00, <下周日00:00:00) （如果今天是周六，则为空范围）
          final startTime = TaskSectionUtils.getSectionStartTime(section, now: now);
          final endTime = TaskSectionUtils.getSectionEndTimeForQuery(section, now: now);
          // 检查是否为空范围（今天是周六时，startTime >= endTime）
          if (startTime.isBefore(endTime)) {
          query.where((t) =>
                t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index, domain.TaskStatus.paused.index]) &
              t.dueAt.isNotNull() &
                t.dueAt.isBiggerOrEqualValue(startTime) &
                t.dueAt.isSmallerThanValue(endTime));
          } else {
            // 空范围，返回空结果
            query.where((t) => t.id.equals('__empty__'));
          }
          break;
        case domain.TaskSection.thisMonth:
          // 当月：[>=下周日00:00:00, <下月1日00:00:00) （如果本周跨月，则为空范围）
          final startTime = TaskSectionUtils.getSectionStartTime(section, now: now);
          final endTime = TaskSectionUtils.getSectionEndTimeForQuery(section, now: now);
          // 检查是否为空范围
          if (startTime.isBefore(endTime)) {
          query.where((t) =>
                t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index, domain.TaskStatus.paused.index]) &
              t.dueAt.isNotNull() &
                t.dueAt.isBiggerOrEqualValue(startTime) &
                t.dueAt.isSmallerThanValue(endTime));
          } else {
            // 空范围，返回空结果
            query.where((t) => t.id.equals('__empty__'));
          }
          break;
        case domain.TaskSection.nextMonth:
          // 下月：[>=下月1日00:00:00, <下下月1日00:00:00)
          final startTime = TaskSectionUtils.getSectionStartTime(section, now: now);
          final endTime = TaskSectionUtils.getSectionEndTimeForQuery(section, now: now);
          query.where((t) =>
              t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index, domain.TaskStatus.paused.index]) &
              t.dueAt.isNotNull() &
              t.dueAt.isBiggerOrEqualValue(startTime) &
              t.dueAt.isSmallerThanValue(endTime));
          break;
        case domain.TaskSection.later:
          // 以后：[>=下下月1日00:00:00, ~)
          final startTime = TaskSectionUtils.getSectionStartTime(section, now: now);
          query.where((t) =>
              t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index, domain.TaskStatus.paused.index]) &
              (t.dueAt.isNull() | t.dueAt.isBiggerOrEqualValue(startTime)));
          break;
        case domain.TaskSection.completed:
          query.where((t) => t.status.equals(domain.TaskStatus.completedActive.index));
          break;
        case domain.TaskSection.archived:
          query.where((t) => t.status.equals(domain.TaskStatus.archived.index));
          break;
        case domain.TaskSection.trash:
          query.where((t) => t.status.equals(domain.TaskStatus.trashed.index));
          break;
      }

      final entities = await query.get();
      return await _toTasks(entities);
    });
  }

  @override
  Future<List<domain.Task>> listCompletedTasks({
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
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.tasks)
        ..where((t) => t.status.equals(domain.TaskStatus.completedActive.index))
        ..orderBy([(t) => OrderingTerm(expression: t.endedAt, mode: OrderingMode.desc)])
        ..limit(limit, offset: offset);

      // 应用项目/里程碑过滤条件
      if (projectId != null) {
        query.where((t) => t.projectId.equals(projectId));
      }
      if (milestoneId != null) {
        query.where((t) => t.milestoneId.equals(milestoneId));
      }
      if (showNoProject == true) {
        query.where((t) => t.projectId.isNull());
      }

      // 获取实体
      var entities = await query.get();

      // 应用标签过滤（在内存中过滤，因为标签存储在 JSON 中）
      entities = _applyTagFilters(
        entities,
        contextTag: contextTag,
        priorityTag: priorityTag,
        urgencyTag: urgencyTag,
        importanceTag: importanceTag,
      );

      return await _toTasks(entities);
    });
  }

  @override
  Future<List<domain.Task>> listArchivedTasks({
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
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.tasks)
        ..where((t) => t.status.equals(domain.TaskStatus.archived.index))
        ..orderBy([(t) => OrderingTerm(expression: t.archivedAt, mode: OrderingMode.desc)])
        ..limit(limit, offset: offset);

      // 应用项目/里程碑过滤条件
      if (projectId != null) {
        query.where((t) => t.projectId.equals(projectId));
      }
      if (milestoneId != null) {
        query.where((t) => t.milestoneId.equals(milestoneId));
      }
      if (showNoProject == true) {
        query.where((t) => t.projectId.isNull());
      }

      // 获取实体
      var entities = await query.get();

      // 应用标签过滤（在内存中过滤，因为标签存储在 JSON 中）
      entities = _applyTagFilters(
        entities,
        contextTag: contextTag,
        priorityTag: priorityTag,
        urgencyTag: urgencyTag,
        importanceTag: importanceTag,
      );

      return await _toTasks(entities);
    });
  }

  @override
  Future<int> countCompletedTasks() async {
    return await _adapter.readTransaction(() async {
      final query = _db.selectOnly(_db.tasks)
        ..addColumns([_db.tasks.id.count()])
        ..where(_db.tasks.status.equals(domain.TaskStatus.completedActive.index));
      final result = await query.getSingle();
      return result.read(_db.tasks.id.count()) ?? 0;
    });
  }

  @override
  Future<int> countArchivedTasks() async {
    return await _adapter.readTransaction(() async {
      final query = _db.selectOnly(_db.tasks)
        ..addColumns([_db.tasks.id.count()])
        ..where(_db.tasks.status.equals(domain.TaskStatus.archived.index));
      final result = await query.getSingle();
      return result.read(_db.tasks.id.count()) ?? 0;
    });
  }

  @override
  Future<List<domain.Task>> listTrashedTasks({
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
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.tasks)
        ..where((t) => t.status.equals(domain.TaskStatus.trashed.index))
        ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)])
        ..limit(limit, offset: offset);

      // 应用项目/里程碑过滤条件
      if (projectId != null) {
        query.where((t) => t.projectId.equals(projectId));
      }
      if (milestoneId != null) {
        query.where((t) => t.milestoneId.equals(milestoneId));
      }
      if (showNoProject == true) {
        query.where((t) => t.projectId.isNull());
      }

      // 获取实体
      var entities = await query.get();

      // 应用标签过滤（在内存中过滤，因为标签存储在 JSON 中）
      entities = _applyTagFilters(
        entities,
        contextTag: contextTag,
        priorityTag: priorityTag,
        urgencyTag: urgencyTag,
        importanceTag: importanceTag,
      );

      return await _toTasks(entities);
    });
  }

  @override
  Future<int> countTrashedTasks() async {
    return await _adapter.readTransaction(() async {
      final query = _db.selectOnly(_db.tasks)
        ..addColumns([_db.tasks.id.count()])
        ..where(_db.tasks.status.equals(domain.TaskStatus.trashed.index));
      final result = await query.getSingle();
      return result.read(_db.tasks.id.count()) ?? 0;
    });
  }

  /// 将 Drift Task 实体转换为领域模型 Task
  Future<domain.Task> _toTask(drift.Task entity, [List<TaskLogEntry>? logs]) async {
    final taskLogs = logs ?? await _loadLogsForTask(entity.id);
    return domain.Task(
      id: entity.id,
      title: entity.title,
      status: entity.status,
      dueAt: entity.dueAt,
      startedAt: entity.startedAt,
      endedAt: entity.endedAt,
      archivedAt: entity.archivedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      // 层级功能已移除，parentId 字段已从 Task 模型中移除
      projectId: entity.projectId,
      milestoneId: entity.milestoneId,
      sortIndex: entity.sortIndex,
      tags: List<String>.unmodifiable(entity.tags),
      templateLockCount: entity.templateLockCount,
      seedSlug: entity.seedSlug,
      allowInstantComplete: entity.allowInstantComplete,
      description: entity.description,
      logs: List<TaskLogEntry>.unmodifiable(taskLogs),
    );
  }

  /// 批量转换 Drift Task 实体为领域模型 Task
  Future<List<domain.Task>> _toTasks(List<drift.Task> entities) async {
    if (entities.isEmpty) return [];

    final taskIds = entities.map((e) => e.id).toList();
    final logsByTask = await _loadLogsForTasks(taskIds);

    return entities.map((entity) {
      final logs = logsByTask[entity.id] ?? const <TaskLogEntry>[];
      return domain.Task(
        id: entity.id,
        title: entity.title,
        status: entity.status,
        dueAt: entity.dueAt,
        startedAt: entity.startedAt,
        endedAt: entity.endedAt,
        archivedAt: entity.archivedAt,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        // 层级功能已移除，parentId 字段已从 Task 模型中移除
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
    }).toList();
  }

  /// 加载单个任务的日志
  Future<List<TaskLogEntry>> _loadLogsForTask(String taskId) async {
    final query = _db.select(_db.taskLogs)
      ..where((t) => t.taskId.equals(taskId))
      ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc)]);
    final entities = await query.get();
    return entities.map(_toLogEntry).toList();
  }

  /// 批量加载多个任务的日志
  Future<Map<String, List<TaskLogEntry>>> _loadLogsForTasks(List<String> taskIds) async {
    if (taskIds.isEmpty) return {};

    final query = _db.select(_db.taskLogs)
      ..where((t) => t.taskId.isIn(taskIds))
      ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc)]);
    final entities = await query.get();

    final logsByTask = <String, List<TaskLogEntry>>{};
    for (final entity in entities) {
      logsByTask.putIfAbsent(entity.taskId ?? '', () => []).add(_toLogEntry(entity));
    }
    return logsByTask;
  }

  /// 将 Drift TaskLog 实体转换为 TaskLogEntry
  TaskLogEntry _toLogEntry(drift.TaskLog entity) {
    return TaskLogEntry(
      timestamp: entity.timestamp,
      action: entity.action,
      previous: entity.previous,
      next: entity.next,
      actor: entity.actor,
    );
  }

  /// 应用标签过滤条件
  ///
  /// [entities] 要过滤的任务实体列表
  /// [contextTag] 上下文标签
  /// [priorityTag] 优先级标签
  /// [urgencyTag] 紧急度标签
  /// [importanceTag] 重要度标签
  /// 返回过滤后的任务实体列表
  List<drift.Task> _applyTagFilters(
    List<drift.Task> entities, {
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
  }) {
    if (contextTag == null &&
        priorityTag == null &&
        urgencyTag == null &&
        importanceTag == null) {
      return entities;
    }

    return entities.where((entity) {
      final tags = entity.tags;
      if (contextTag != null && !tags.contains(contextTag)) return false;
      if (priorityTag != null && !tags.contains(priorityTag)) return false;
      if (urgencyTag != null && !tags.contains(urgencyTag)) return false;
      if (importanceTag != null && !tags.contains(importanceTag)) return false;
      return true;
    }).toList();
  }

  /// 应用标签列表过滤条件（任务必须包含所有标签）
  ///
  /// [entities] 要过滤的任务实体列表
  /// [tags] 标签列表
  /// 返回过滤后的任务实体列表
  List<drift.Task> _applyTagsFilter(
    List<drift.Task> entities,
    List<String> tags,
  ) {
    if (tags.isEmpty) {
      return entities;
    }

    return entities.where((entity) {
      final taskTags = entity.tags;
      // 任务必须包含所有指定的标签
      return tags.every((tag) => taskTags.contains(tag));
    }).toList();
  }

  @override
  Future<Map<DateTime, List<domain.Task>>> getCompletedRootTasksByDateRange({
    required DateTime start,
    required DateTime end,
    String? projectId,
    List<String>? tags,
  }) async {
    return await _adapter.readTransaction(() async {
      // 规范化日期：只保留年月日
      final startDate = DateTime(start.year, start.month, start.day);
      final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);

      final query = _db.select(_db.tasks)
        ..where((t) =>
            t.status.equals(domain.TaskStatus.completedActive.index) &
            t.parentId.isNull() &
            t.endedAt.isNotNull() &
            t.endedAt.isBiggerOrEqualValue(startDate) &
            t.endedAt.isSmallerOrEqualValue(endDate));

      // 排除指定状态
      query.where((t) =>
          t.status.isNotIn([
            domain.TaskStatus.inbox.index,
            domain.TaskStatus.trashed.index,
            domain.TaskStatus.pseudoDeleted.index,
            domain.TaskStatus.archived.index,
          ]));

      // 应用项目筛选
      if (projectId != null) {
        query.where((t) => t.projectId.equals(projectId));
      }

      // 获取实体
      var entities = await query.get();

      // 应用标签过滤（在内存中过滤，因为标签存储在 JSON 中）
      if (tags != null && tags.isNotEmpty) {
        entities = _applyTagsFilter(entities, tags);
      }

      // 转换为领域模型
      final tasks = await _toTasks(entities);

      // 按完成日期分组
      final result = <DateTime, List<domain.Task>>{};
      for (final task in tasks) {
        if (task.endedAt == null) continue;
        final date = DateTime(
          task.endedAt!.year,
          task.endedAt!.month,
          task.endedAt!.day,
        );
        result.putIfAbsent(date, () => []).add(task);
      }

      return result;
    });
  }

}
