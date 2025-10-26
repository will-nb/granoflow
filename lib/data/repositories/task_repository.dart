import 'dart:async';
import 'dart:math';

import 'package:isar/isar.dart';

import '../isar/task_entity.dart';
import '../models/task.dart';

abstract class TaskRepository {
  Stream<List<Task>> watchSection(TaskSection section);

  Stream<TaskTreeNode> watchTaskTree(int rootTaskId);

  Stream<List<Task>> watchInbox();

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
}

class IsarTaskRepository implements TaskRepository {
  IsarTaskRepository(this._isar, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Isar _isar;
  final DateTime Function() _clock;
  final Random _random = Random();

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
          .sortByCreatedAtDesc()
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
          .sortByCreatedAtDesc()
          .findAll();
      final filtered = entities.where((entity) {
        final tags = entity.tags;
        if (contextTag != null && contextTag.isNotEmpty) {
          if (!tags.contains(contextTag)) {
            return false;
          }
        }
        if (priorityTag != null && priorityTag.isNotEmpty) {
          if (!tags.contains(priorityTag)) {
            return false;
          }
        }
        if (urgencyTag != null && urgencyTag.isNotEmpty) {
          if (!tags.contains(urgencyTag)) {
            return false;
          }
        }
        if (importanceTag != null && importanceTag.isNotEmpty) {
          if (!tags.contains(importanceTag)) {
            return false;
          }
        }
        return true;
      }).map(_toDomain).toList(growable: false);
      return filtered;
    });
  }

  @override
  Future<Task> createTask(TaskDraft draft) async {
    return _isar.writeTxn<Task>(() async {
      final now = _clock();
      final entity = TaskEntity()
        ..taskId = _generateTaskId(now)
        ..title = draft.title
        ..status = draft.status
        ..dueAt = draft.dueAt
        ..createdAt = now
        ..updatedAt = now
        ..parentId = draft.parentId
        ..sortIndex = draft.sortIndex
        ..tags = draft.tags.toList()
        ..templateLockCount = 0
        ..seedSlug = draft.seedSlug
        ..allowInstantComplete = draft.allowInstantComplete;
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
        ..tags = payload.tags ?? entity.tags
        ..templateLockCount =
            (entity.templateLockCount + payload.templateLockDelta).clamp(
              0,
              1 << 31,
            )
        ..allowInstantComplete =
            payload.allowInstantComplete ?? entity.allowInstantComplete
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
        .findAll();
    return roots.map(_toDomain).toList(growable: false);
  }

  @override
  Future<List<Task>> listChildren(int parentId) async {
    final children = await _isar.taskEntitys
        .filter()
        .parentIdEqualTo(parentId)
        .sortBySortIndex()
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
    QueryBuilder<TaskEntity, TaskEntity, QAfterFilterCondition> builder =
        _isar.taskEntitys.filter().titleContains(
              query,
              caseSensitive: false,
            );
    if (status != null) {
      builder = builder.statusEqualTo(status);
    }
    final results = await builder.sortByUpdatedAtDesc().findAll();
    return results.take(limit).map(_toDomain).toList(growable: false);
  }

  Future<List<Task>> _fetchSection(TaskSection section) async {
    final now = _clock();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final laterStart = todayStart.add(const Duration(days: 2));

    QueryBuilder<TaskEntity, TaskEntity, QAfterFilterCondition> builder;
    switch (section) {
      case TaskSection.today:
        builder = _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtBetween(todayStart, tomorrowStart, includeUpper: true);
        break;
      case TaskSection.tomorrow:
        final dayAfter = tomorrowStart.add(const Duration(days: 1));
        builder = _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtBetween(tomorrowStart, dayAfter, includeUpper: true);
        break;
      case TaskSection.later:
        builder = _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtGreaterThan(laterStart, include: false);
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

    final results = await builder.sortBySortIndex().findAll();
    return results.map(_toDomain).toList(growable: false);
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
      tags: List.unmodifiable(entity.tags),
      templateLockCount: entity.templateLockCount,
      seedSlug: entity.seedSlug,
      allowInstantComplete: entity.allowInstantComplete,
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
      ..tags = task.tags.toList()
      ..templateLockCount = task.templateLockCount
      ..seedSlug = task.seedSlug
      ..allowInstantComplete = task.allowInstantComplete;
    return entity;
  }

  TaskStatus _sectionToStatus(TaskSection section) {
    switch (section) {
      case TaskSection.today:
      case TaskSection.tomorrow:
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

  String _generateTaskId(DateTime now) {
    final dateString =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final suffix = _random.nextInt(9000) + 1000;
    return '$dateString-$suffix';
  }
}
