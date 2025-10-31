import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../../core/services/tag_service.dart';
import '../isar/task_entity.dart';
import '../models/task.dart';

abstract class TaskRepository {
  Stream<List<Task>> watchSection(TaskSection section);

  Stream<TaskTreeNode> watchTaskTree(int rootTaskId);

  Stream<List<Task>> watchInbox();

  Stream<List<Task>> watchProjects();

  Stream<List<Task>> watchQuickTasks();

  Stream<List<Task>> watchMilestones(int projectId);

  Stream<List<Task>> watchInboxFiltered({
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
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

  Future<void> adjustTemplateLock({required int taskId, required int delta});

  Future<Task?> findById(int id);

  Future<Task?> findBySlug(String slug);

  Future<List<Task>> listRoots();

  Future<List<Task>> listChildren(int parentId);

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
}

class IsarTaskRepository implements TaskRepository {
  IsarTaskRepository(this._isar, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Isar _isar;
  final DateTime Function() _clock;

  @override
  Stream<List<Task>> watchSection(TaskSection section) {
    return _watchQuery(() => _fetchSection(section)).map((tasks) {
      if (section == TaskSection.later) {
        debugPrint('[TaskRepository.watchSection] Stream 发送的任务顺序:');
        for (final task in tasks) {
          debugPrint('  - ${task.title}: dueAt=${task.dueAt}');
        }
      }
      return tasks;
    });
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
      return results.map(_toDomain).toList(growable: false);
    });
  }

  @override
  Stream<List<Task>> watchInboxFiltered({
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
  }) {
    return _watchQuery(() async {
      final entities = await _isar.taskEntitys
          .filter()
          .statusEqualTo(TaskStatus.inbox)
          .sortBySortIndex()
          .thenByCreatedAtDesc()
          .findAll();
      final filtered = entities
          .where((entity) {
            final tags = entity.tags;
            // 规范化标签后进行比较（兼容旧数据）
            if (contextTag != null && contextTag.isNotEmpty) {
              final normalizedContextTag = TagService.normalizeSlug(contextTag);
              if (!tags.any((tag) => TagService.normalizeSlug(tag) == normalizedContextTag)) {
                return false;
              }
            }
            if (priorityTag != null && priorityTag.isNotEmpty) {
              final normalizedPriorityTag = TagService.normalizeSlug(priorityTag);
              if (!tags.any((tag) => TagService.normalizeSlug(tag) == normalizedPriorityTag)) {
                return false;
              }
            }
            if (urgencyTag != null && urgencyTag.isNotEmpty) {
              final normalizedUrgencyTag = TagService.normalizeSlug(urgencyTag);
              if (!tags.any((tag) => TagService.normalizeSlug(tag) == normalizedUrgencyTag)) {
                return false;
              }
            }
            if (importanceTag != null && importanceTag.isNotEmpty) {
              final normalizedImportanceTag = TagService.normalizeSlug(importanceTag);
              if (!tags.any((tag) => TagService.normalizeSlug(tag) == normalizedImportanceTag)) {
                return false;
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
  Stream<List<Task>> watchProjects() {
    return _watchQuery(() async {
      final entities = await _isar.taskEntitys
          .filter()
          .taskKindEqualTo(TaskKind.project)
          .parentIdIsNull()
          .findAll();
      final filtered = entities
          .where((entity) => _isActiveProjectStatus(entity.status))
          .toList(growable: false);
      filtered.sort((a, b) {
        final aDue = a.dueAt ?? DateTime.fromMillisecondsSinceEpoch(4102444800000); // 2100-01-01
        final bDue = b.dueAt ?? DateTime.fromMillisecondsSinceEpoch(4102444800000);
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
  Stream<List<Task>> watchQuickTasks() {
    return _watchQuery(() async {
      final entities = await _isar.taskEntitys
          .filter()
          .taskKindEqualTo(TaskKind.regular)
          .parentIdIsNull()
          .findAll();
      final filtered = entities
          .where((entity) => _isActiveQuickTaskStatus(entity.status))
          .toList(growable: false);
      filtered.sort((a, b) {
        final aDue = a.dueAt ?? DateTime.fromMillisecondsSinceEpoch(4102444800000);
        final bDue = b.dueAt ?? DateTime.fromMillisecondsSinceEpoch(4102444800000);
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
  Stream<List<Task>> watchMilestones(int projectId) {
    return _watchQuery(() async {
      final entities = await _isar.taskEntitys
          .filter()
          .taskKindEqualTo(TaskKind.milestone)
          .parentIdEqualTo(projectId)
          .findAll();
      final filtered = entities
          .where((entity) => _isVisibleMilestoneStatus(entity.status))
          .toList(growable: false);
      filtered.sort((a, b) {
        final aDue = a.dueAt ?? DateTime.fromMillisecondsSinceEpoch(4102444800000);
        final bDue = b.dueAt ?? DateTime.fromMillisecondsSinceEpoch(4102444800000);
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
  Future<Task> createTask(TaskDraft draft) async {
    return _isar.writeTxn<Task>(() async {
      final now = _clock();
      final taskId = await _generateTaskId(now);
      final entity = TaskEntity()
        ..taskId = taskId
        ..title = draft.title
        ..status = draft.status
        ..dueAt = draft.dueAt
        ..createdAt = now
        ..updatedAt = now
        ..parentId = draft.parentId
        ..sortIndex = draft.sortIndex
        ..tags = draft.tags.map((tag) => TagService.normalizeSlug(tag)).toList()
        ..templateLockCount = 0
        ..seedSlug = draft.seedSlug
        ..allowInstantComplete = draft.allowInstantComplete
        ..description = draft.description
        ..taskKind = draft.taskKind
        ..logs = draft.logs.map(_logFromDomain).toList();
      final id = await _isar.taskEntitys.put(entity);
      entity.id = id;
      return _toDomain(entity);
    });
  }

  @override
  Future<void> updateTask(int taskId, TaskUpdate payload) async {
    await _isar.writeTxn(() async {
      final entity = await _isar.taskEntitys.get(taskId);
      if (entity == null) {
        return;
      }

      entity
        ..title = payload.title ?? entity.title
        ..status = payload.status ?? entity.status
        ..dueAt = payload.dueAt ?? entity.dueAt
        ..startedAt = payload.startedAt ?? entity.startedAt
        ..endedAt = payload.endedAt ?? entity.endedAt
        ..parentId = payload.parentId ?? entity.parentId
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
        ..taskKind = payload.taskKind ?? entity.taskKind
        ..logs = payload.logs != null
            ? payload.logs!.map(_logFromDomain).toList()
            : entity.logs
        ..updatedAt = _clock();

      await _isar.taskEntitys.put(entity);
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
    await _isar.writeTxn(() async {
      final entity = await _isar.taskEntitys.get(taskId);
      if (entity == null) {
        return;
      }
      entity
        ..parentId = targetParentId
        ..status = _sectionToStatus(targetSection)
        ..sortIndex = sortIndex
        ..dueAt = dueAt ?? entity.dueAt
        ..updatedAt = _clock();
      await _isar.taskEntitys.put(entity);
    });
  }

  @override
  Future<void> markStatus({
    required int taskId,
    required TaskStatus status,
  }) async {
    await _isar.writeTxn(() async {
      final entity = await _isar.taskEntitys.get(taskId);
      if (entity == null) {
        return;
      }
      entity
        ..status = status
        ..updatedAt = _clock();
      await _isar.taskEntitys.put(entity);
    });
  }

  @override
  Future<void> archiveTask(int taskId) async {
    await markStatus(taskId: taskId, status: TaskStatus.archived);
  }

  @override
  Future<void> softDelete(int taskId) async {
    await _isar.writeTxn(() async {
      final entity = await _isar.taskEntitys.get(taskId);
      if (entity == null || entity.templateLockCount > 0) {
        return;
      }
      entity
        ..status = TaskStatus.trashed
        ..updatedAt = _clock();
      await _isar.taskEntitys.put(entity);
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
        .thenByCreatedAt()
        .findAll();
    return roots.map(_toDomain).toList(growable: false);
  }

  @override
  Future<List<Task>> listChildren(int parentId) async {
    final children = await _isar.taskEntitys
        .filter()
        .parentIdEqualTo(parentId)
        .sortBySortIndex()
        .thenByCreatedAt()
        .findAll();
    return children.map(_toDomain).toList(growable: false);
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
    return results.take(limit).map(_toDomain).toList(growable: false);
  }

  @override
  Future<void> batchUpdate(Map<int, TaskUpdate> updates) async {
    if (updates.isEmpty) return;
    await _isar.writeTxn(() async {
      for (final entry in updates.entries) {
        final entity = await _isar.taskEntitys.get(entry.key);
        if (entity == null) continue;
        final payload = entry.value;
        entity
          ..title = payload.title ?? entity.title
          ..status = payload.status ?? entity.status
          ..dueAt = payload.dueAt ?? entity.dueAt
          ..startedAt = payload.startedAt ?? entity.startedAt
          ..endedAt = payload.endedAt ?? entity.endedAt
          ..parentId = payload.parentId ?? entity.parentId
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
          ..taskKind = payload.taskKind ?? entity.taskKind
          ..logs = payload.logs != null
              ? payload.logs!.map(_logFromDomain).toList()
              : entity.logs
          ..updatedAt = _clock();
        await _isar.taskEntitys.put(entity);
      }
    });
  }

  @override
  Future<List<Task>> listSectionTasks(TaskSection section) async {
    // 复用 _fetchSection（已是叶任务，并按 sortIndex 排序）
    return _fetchSection(section);
  }

  bool _isActiveProjectStatus(TaskStatus status) {
    return status != TaskStatus.archived &&
        status != TaskStatus.trashed &&
        status != TaskStatus.pseudoDeleted &&
        status != TaskStatus.completedActive;
  }

  bool _isActiveQuickTaskStatus(TaskStatus status) {
    return status != TaskStatus.archived &&
        status != TaskStatus.trashed &&
        status != TaskStatus.pseudoDeleted &&
        status != TaskStatus.completedActive;
  }

  bool _isVisibleMilestoneStatus(TaskStatus status) {
    return status != TaskStatus.archived &&
        status != TaskStatus.trashed &&
        status != TaskStatus.pseudoDeleted;
  }

  Future<List<Task>> _fetchSection(TaskSection section) async {
    final now = _clock();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final dayAfterTomorrowStart = tomorrowStart.add(const Duration(days: 1));
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);
    // 以周日 00:00 作为“本周”的上界、“当月”的下界
    final sundayStart = _getThisSundayStart(todayStart);
    // “以后”下界为周日与下月1日的最大者
    final laterStart = nextMonthStart.isAfter(sundayStart)
        ? nextMonthStart
        : sundayStart;

    QueryBuilder<TaskEntity, TaskEntity, QAfterFilterCondition> builder;
    switch (section) {
      case TaskSection.overdue:
        // 已逾期：[~, <今天00:00:00)
        builder = _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtLessThan(todayStart, include: false);
        break;
      case TaskSection.today:
        // 今天：[>=今天00:00:00, <明天00:00:00)
        builder = _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtBetween(todayStart, tomorrowStart, includeUpper: false);
        break;
      case TaskSection.tomorrow:
        // 明天：[>=明天00:00:00, <后天00:00:00)
        builder = _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtBetween(
              tomorrowStart,
              dayAfterTomorrowStart,
              includeUpper: false,
            );
        break;
      case TaskSection.thisWeek:
        // 本周：[>=后天00:00:00, <周日00:00:00)
        builder = _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtBetween(
              dayAfterTomorrowStart,
              sundayStart,
              includeUpper: false,
            );
        break;
      case TaskSection.thisMonth:
        // 当月：[>=周日00:00:00, <下月1日00:00:00)
        builder = _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtBetween(sundayStart, nextMonthStart, includeUpper: false);
        break;
      case TaskSection.later:
        // 以后：[>=max(周日00:00:00, 下月1日00:00:00), ~)
        builder = _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtGreaterThan(laterStart, include: true);
        break;
      case TaskSection.completed:
        builder = _isar.taskEntitys.filter().statusEqualTo(
          TaskStatus.completedActive,
        );
        break;
      case TaskSection.archived:
        builder = _isar.taskEntitys.filter().statusEqualTo(TaskStatus.archived);
        break;
      case TaskSection.trash:
        builder = _isar.taskEntitys.filter().statusEqualTo(TaskStatus.trashed);
        break;
    }

    // 先从数据库获取数据，不做排序
    final results = await builder.findAll();

    // 过滤叶任务（只显示没有子任务的任务）
    final leafTasks = await _filterLeafTasks(results);

    // 转换为领域模型
    final tasks = leafTasks.map(_toDomain).toList(growable: false);

    // 调试日志：输出排序前的任务
    if (section == TaskSection.later && tasks.isNotEmpty) {
      debugPrint('[TaskRepository] 以后区域排序前:');
      for (final task in tasks) {
        debugPrint('  - ${task.title}: dueAt=${task.dueAt}, sortIndex=${task.sortIndex}');
      }
    }

    // 在内存中排序：先按日期（不含时间）升序，再按 sortIndex 升序，最后按 createdAt 升序
    tasks.sort((a, b) {
      // 1. 比较 dueAt 的日期部分（忽略时间）
      final aDate = a.dueAt;
      final bDate = b.dueAt;
      
      if (aDate == null && bDate == null) {
        // 两者都没有 dueAt，按 sortIndex 比较
        final sortIndexComparison = a.sortIndex.compareTo(b.sortIndex);
        if (sortIndexComparison != 0) return sortIndexComparison;
        return a.createdAt.compareTo(b.createdAt);
      }
      
      if (aDate == null) return 1; // 没有 dueAt 的排在后面
      if (bDate == null) return -1;
      
      // 提取日期部分（年-月-日，忽略时分秒）
      final aDayOnly = DateTime(aDate.year, aDate.month, aDate.day);
      final bDayOnly = DateTime(bDate.year, bDate.month, bDate.day);
      
      final dateComparison = aDayOnly.compareTo(bDayOnly);
      if (dateComparison != 0) return dateComparison;
      
      // 2. 日期相同，按 sortIndex 比较
      final sortIndexComparison = a.sortIndex.compareTo(b.sortIndex);
      if (sortIndexComparison != 0) return sortIndexComparison;
      
      // 3. sortIndex 也相同，按 createdAt 比较
      return a.createdAt.compareTo(b.createdAt);
    });

    // 调试日志：输出排序后的任务
    if (section == TaskSection.later && tasks.isNotEmpty) {
      debugPrint('[TaskRepository] 以后区域排序后:');
      for (final task in tasks) {
        debugPrint('  - ${task.title}: dueAt=${task.dueAt}, sortIndex=${task.sortIndex}');
      }
    }

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

  Future<List<TaskEntity>> _filterLeafTasks(List<TaskEntity> tasks) async {
    if (tasks.isEmpty) return tasks;

    // 查询所有父任务ID（不限制子任务的任何条件，避免bug）
    // 利用parentId索引提升性能
    final parentIds = await _isar.taskEntitys
        .filter()
        .parentIdIsNotNull()
        .distinctByParentId()
        .findAll()
        .then((entities) => entities.map((e) => e.parentId!).toSet());

    // 过滤出叶任务（没有子任务的任务）
    return tasks.where((task) => !parentIds.contains(task.id)).toList();
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
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      parentId: entity.parentId,
      sortIndex: entity.sortIndex,
      tags: List.unmodifiable(normalizedTags),
      templateLockCount: entity.templateLockCount,
      seedSlug: entity.seedSlug,
      allowInstantComplete: entity.allowInstantComplete,
      description: entity.description,
      taskKind: entity.taskKind,
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
      ..createdAt = task.createdAt
      ..updatedAt = task.updatedAt
      ..parentId = task.parentId
      ..sortIndex = task.sortIndex
      ..tags = task.tags.map((tag) => TagService.normalizeSlug(tag)).toList()
      ..templateLockCount = task.templateLockCount
      ..seedSlug = task.seedSlug
      ..allowInstantComplete = task.allowInstantComplete
      ..description = task.description
      ..taskKind = task.taskKind
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
  // 辅助方法：获取本周周日 00:00（基于给定日期所在周）
  DateTime _getThisSundayStart(DateTime todayStart) {
    // DateTime.weekday: Monday=1 ... Sunday=7
    final daysUntilSunday = (DateTime.sunday - todayStart.weekday + 7) % 7;
    final sunday = todayStart.add(Duration(days: daysUntilSunday));
    return DateTime(sunday.year, sunday.month, sunday.day);
  }
}
