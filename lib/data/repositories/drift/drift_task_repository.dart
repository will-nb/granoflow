import 'dart:async';

import 'package:drift/drift.dart';

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
    final today = DateTime(now.year, now.month, now.day);

    switch (section) {
      case domain.TaskSection.overdue:
        query.where((t) =>
            t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index]) &
            t.dueAt.isNotNull() &
            t.dueAt.isSmallerThanValue(today));
        break;
      case domain.TaskSection.today:
        final tomorrow = today.add(const Duration(days: 1));
        query.where((t) =>
            t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index]) &
            t.dueAt.isNotNull() &
            t.dueAt.isBiggerOrEqualValue(today) &
            t.dueAt.isSmallerThanValue(tomorrow));
        break;
      case domain.TaskSection.tomorrow:
        final tomorrow = today.add(const Duration(days: 1));
        final dayAfterTomorrow = tomorrow.add(const Duration(days: 1));
        query.where((t) =>
            t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index]) &
            t.dueAt.isNotNull() &
            t.dueAt.isBiggerOrEqualValue(tomorrow) &
            t.dueAt.isSmallerThanValue(dayAfterTomorrow));
        break;
      case domain.TaskSection.thisWeek:
        final nextWeek = today.add(const Duration(days: 7));
        query.where((t) =>
            t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index]) &
            t.dueAt.isNotNull() &
            t.dueAt.isBiggerOrEqualValue(today) &
            t.dueAt.isSmallerThanValue(nextWeek));
        break;
      case domain.TaskSection.thisMonth:
        final thisMonth = DateTime(now.year, now.month, 1);
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        query.where((t) =>
            t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index]) &
            t.dueAt.isNotNull() &
            t.dueAt.isBiggerOrEqualValue(thisMonth) &
            t.dueAt.isSmallerThanValue(nextMonth));
        break;
      case domain.TaskSection.nextMonth:
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        final monthAfterNext = DateTime(now.year, now.month + 2, 1);
        query.where((t) =>
            t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index]) &
            t.dueAt.isNotNull() &
            t.dueAt.isBiggerOrEqualValue(nextMonth) &
            t.dueAt.isSmallerThanValue(monthAfterNext));
        break;
      case domain.TaskSection.later:
        final monthAfterNext = DateTime(now.year, now.month + 2, 1);
        query.where((t) =>
            t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index]) &
            (t.dueAt.isNull() | t.dueAt.isBiggerOrEqualValue(monthAfterNext)));
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
    // TODO: 实现
    throw UnimplementedError('watchTaskTree will be implemented');
  }

  @override
  Stream<List<domain.Task>> watchInbox() {
    // TODO: 实现
    throw UnimplementedError('watchInbox will be implemented');
  }

  @override
  @Deprecated('使用 ProjectRepository 和 ProjectService 替代')
  Stream<List<domain.Task>> watchProjects() {
    // TODO: 实现
    throw UnimplementedError('watchProjects will be implemented');
  }

  @override
  Stream<List<domain.Task>> watchQuickTasks() {
    // TODO: 实现
    throw UnimplementedError('watchQuickTasks will be implemented');
  }

  @override
  @Deprecated('使用 MilestoneRepository 和 MilestoneService 替代')
  Stream<List<domain.Task>> watchMilestones(String projectId) {
    // TODO: 实现
    throw UnimplementedError('watchMilestones will be implemented');
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
    // TODO: 实现
    throw UnimplementedError('watchTasksByMilestoneId will be implemented');
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
          ]));

    // 应用过滤条件
    if (projectId != null) {
      query.where((t) => t.projectId.equals(projectId));
    }
    if (milestoneId != null) {
      query.where((t) => t.milestoneId.equals(milestoneId));
    }
    if (showNoProject == true) {
      query.where((t) => t.projectId.isNull());
    }
    // TODO: 实现标签过滤（contextTag, priorityTag, urgencyTag, importanceTag）
    // 标签存储在 tags 字段（List<String>），需要使用 JSON 查询或内存过滤

    return query.watch().asyncMap((entities) async {
      if (entities.isEmpty) return <domain.Task>[];
      
      // 在内存中应用标签过滤
      var filtered = entities;
      if (contextTag != null || priorityTag != null || urgencyTag != null || importanceTag != null) {
        filtered = entities.where((entity) {
          final tags = entity.tags;
          if (contextTag != null && !tags.contains(contextTag)) return false;
          if (priorityTag != null && !tags.contains(priorityTag)) return false;
          if (urgencyTag != null && !tags.contains(urgencyTag)) return false;
          if (importanceTag != null && !tags.contains(importanceTag)) return false;
          return true;
        }).toList();
      }
      
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
        parentId: draft.parentId,
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

      final companion = TasksCompanion(
        id: const Value.absent(),
        title: payload.title != null ? Value(payload.title!) : const Value.absent(),
        status: payload.status != null ? Value(payload.status!) : const Value.absent(),
        dueAt: payload.dueAt != null ? Value(payload.dueAt) : const Value.absent(),
        startedAt: payload.startedAt != null ? Value(payload.startedAt) : const Value.absent(),
        endedAt: payload.endedAt != null ? Value(payload.endedAt) : const Value.absent(),
        archivedAt: payload.archivedAt != null ? Value(payload.archivedAt) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
        parentId: payload.parentId != null ? Value(payload.parentId) : (payload.clearParent == true ? const Value.absent() : const Value.absent()),
        projectId: payload.projectId != null ? Value(payload.projectId) : (payload.clearProject == true ? const Value.absent() : const Value.absent()),
        milestoneId: payload.milestoneId != null ? Value(payload.milestoneId) : (payload.clearMilestone == true ? const Value.absent() : const Value.absent()),
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
      var companion = TasksCompanion(
        parentId: targetParentId != null ? Value(targetParentId) : const Value.absent(),
        sortIndex: Value(sortIndex),
        dueAt: dueAt != null ? Value(dueAt) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      );

      // 根据 targetSection 更新状态
      TasksCompanion finalCompanion;
      switch (targetSection) {
        case domain.TaskSection.completed:
          finalCompanion = companion.copyWith(
            status: Value(domain.TaskStatus.completedActive),
            endedAt: Value(DateTime.now()),
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
      await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
        TasksCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        ),
      );
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
  Future<int> purgeObsolete(DateTime olderThan) {
    // TODO: 实现
    throw UnimplementedError('purgeObsolete will be implemented');
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
  Future<List<domain.Task>> listChildren(String parentId) async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.tasks)
        ..where((t) => t.parentId.equals(parentId) & t.status.isNotValue(domain.TaskStatus.trashed.index));
      final entities = await query.get();
      return await _toTasks(entities);
    });
  }

  @override
  Future<List<domain.Task>> listChildrenIncludingTrashed(String parentId) async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.tasks)
        ..where((t) => t.parentId.equals(parentId));
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
          parentId: payload.parentId != null ? Value(payload.parentId) : (payload.clearParent == true ? const Value.absent() : const Value.absent()),
          projectId: payload.projectId != null ? Value(payload.projectId) : (payload.clearProject == true ? const Value.absent() : const Value.absent()),
          milestoneId: payload.milestoneId != null ? Value(payload.milestoneId) : (payload.clearMilestone == true ? const Value.absent() : const Value.absent()),
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
      final today = DateTime(now.year, now.month, now.day);

      switch (section) {
        case domain.TaskSection.overdue:
          query.where((t) =>
              t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index]) &
              t.dueAt.isNotNull() &
              t.dueAt.isSmallerThanValue(today));
          break;
        case domain.TaskSection.today:
          final tomorrow = today.add(const Duration(days: 1));
          query.where((t) =>
              t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index]) &
              t.dueAt.isNotNull() &
              t.dueAt.isBiggerOrEqualValue(today) &
              t.dueAt.isSmallerThanValue(tomorrow));
          break;
        case domain.TaskSection.tomorrow:
          final tomorrow = today.add(const Duration(days: 1));
          final dayAfterTomorrow = tomorrow.add(const Duration(days: 1));
          query.where((t) =>
              t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index]) &
              t.dueAt.isNotNull() &
              t.dueAt.isBiggerOrEqualValue(tomorrow) &
              t.dueAt.isSmallerThanValue(dayAfterTomorrow));
          break;
        case domain.TaskSection.thisWeek:
          final nextWeek = today.add(const Duration(days: 7));
          query.where((t) =>
              t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index]) &
              t.dueAt.isNotNull() &
              t.dueAt.isBiggerOrEqualValue(today) &
              t.dueAt.isSmallerThanValue(nextWeek));
          break;
        case domain.TaskSection.thisMonth:
          final thisMonth = DateTime(now.year, now.month, 1);
          final nextMonth = DateTime(now.year, now.month + 1, 1);
          query.where((t) =>
              t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index]) &
              t.dueAt.isNotNull() &
              t.dueAt.isBiggerOrEqualValue(thisMonth) &
              t.dueAt.isSmallerThanValue(nextMonth));
          break;
        case domain.TaskSection.nextMonth:
          final nextMonth = DateTime(now.year, now.month + 1, 1);
          final monthAfterNext = DateTime(now.year, now.month + 2, 1);
          query.where((t) =>
              t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index]) &
              t.dueAt.isNotNull() &
              t.dueAt.isBiggerOrEqualValue(nextMonth) &
              t.dueAt.isSmallerThanValue(monthAfterNext));
          break;
        case domain.TaskSection.later:
          final monthAfterNext = DateTime(now.year, now.month + 2, 1);
          query.where((t) =>
              t.status.isIn([domain.TaskStatus.pending.index, domain.TaskStatus.doing.index]) &
              (t.dueAt.isNull() | t.dueAt.isBiggerOrEqualValue(monthAfterNext)));
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
  }) {
    // TODO: 实现
    throw UnimplementedError('listCompletedTasks will be implemented');
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

      // 应用过滤条件
      if (projectId != null) {
        query.where((t) => t.projectId.equals(projectId));
      }
      if (milestoneId != null) {
        query.where((t) => t.milestoneId.equals(milestoneId));
      }
      if (showNoProject == true) {
        query.where((t) => t.projectId.isNull());
      }
      // TODO: 实现标签过滤（contextTag, priorityTag, urgencyTag, importanceTag）

      final entities = await query.get();
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

      // 应用过滤条件
      if (projectId != null) {
        query.where((t) => t.projectId.equals(projectId));
      }
      if (milestoneId != null) {
        query.where((t) => t.milestoneId.equals(milestoneId));
      }
      if (showNoProject == true) {
        query.where((t) => t.projectId.isNull());
      }
      // TODO: 实现标签过滤（contextTag, priorityTag, urgencyTag, importanceTag）

      final entities = await query.get();
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
      parentId: entity.parentId,
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
}
