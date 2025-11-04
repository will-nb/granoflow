import 'dart:async';

import 'package:isar/isar.dart';

import '../../core/providers/project_filter_providers.dart';
import '../../core/services/tag_service.dart';
import '../isar/project_entity.dart';
import '../models/project.dart';
import '../models/task.dart';

abstract class ProjectRepository {
  Stream<List<Project>> watchActiveProjects();

  Stream<List<Project>> watchProjectsByStatus(ProjectFilterStatus status);

  Stream<List<Project>> watchProjectsByStatuses(Set<TaskStatus> allowedStatuses);

  Future<Project?> findByIsarId(int id);

  Future<Project?> findByProjectId(String projectId);

  Future<Project> create(ProjectDraft draft);

  Future<void> update(int isarId, ProjectUpdate update);

  Future<void> delete(int isarId);

  Future<List<Project>> listAll();
}

class IsarProjectRepository implements ProjectRepository {
  IsarProjectRepository(this._isar, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Isar _isar;
  final DateTime Function() _clock;

  @override
  Stream<List<Project>> watchActiveProjects() {
    return watchProjectsByStatus(ProjectFilterStatus.active);
  }

  @override
  Stream<List<Project>> watchProjectsByStatus(ProjectFilterStatus status) {
    return _watchQuery(() async {
      final entities = await _isar.projectEntitys.where().findAll();
      final filtered = entities
          .where((entity) => _matchesFilterStatus(entity.status, status))
          .toList(growable: false);
      filtered.sort(_compareByDueThenCreated);
      return filtered.map(_toDomain).toList(growable: false);
    });
  }

  @override
  Stream<List<Project>> watchProjectsByStatuses(Set<TaskStatus> allowedStatuses) {
    return _watchQuery(() async {
      final entities = await _isar.projectEntitys.where().findAll();
      final filtered = entities
          .where((entity) {
            // 排除伪删除状态
            if (entity.status == TaskStatus.pseudoDeleted) {
              return false;
            }
            // 只返回状态在允许集合中的项目
            return allowedStatuses.contains(entity.status);
          })
          .toList(growable: false);
      filtered.sort(_compareByDueThenCreated);
      return filtered.map(_toDomain).toList(growable: false);
    });
  }

  @override
  Future<Project?> findByIsarId(int id) async {
    final entity = await _isar.projectEntitys.get(id);
    return entity == null ? null : _toDomain(entity);
  }

  @override
  Future<Project?> findByProjectId(String projectId) async {
    final entity = await _isar.projectEntitys
        .filter()
        .projectIdEqualTo(projectId)
        .findFirst();
    return entity == null ? null : _toDomain(entity);
  }

  @override
  Future<Project> create(ProjectDraft draft) async {
    return _isar.writeTxn<Project>(() async {
      final now = _clock();
      final entity = ProjectEntity()
        ..projectId = draft.projectId
        ..title = draft.title
        ..status = draft.status
        ..dueAt = draft.dueAt
        ..startedAt = draft.startedAt
        ..endedAt = draft.endedAt
        ..createdAt = now
        ..updatedAt = now
        ..sortIndex = draft.sortIndex
        ..tags = draft.tags.map((tag) => TagService.normalizeSlug(tag)).toList()
        ..templateLockCount = draft.templateLockCount
        ..seedSlug = draft.seedSlug
        ..allowInstantComplete = draft.allowInstantComplete
        ..description = draft.description
        ..logs = draft.logs.map(_logFromDomain).toList();
      final id = await _isar.projectEntitys.put(entity);
      entity.id = id;
      return _toDomain(entity);
    });
  }

  @override
  Future<void> update(int isarId, ProjectUpdate update) async {
    await _isar.writeTxn(() async {
      final entity = await _isar.projectEntitys.get(isarId);
      if (entity == null) {
        return;
      }

      entity
        ..title = update.title ?? entity.title
        ..status = update.status ?? entity.status
        ..dueAt = update.dueAt ?? entity.dueAt
        ..startedAt = update.startedAt ?? entity.startedAt
        ..endedAt = update.endedAt ?? entity.endedAt
        ..sortIndex = update.sortIndex ?? entity.sortIndex
        ..tags = update.tags != null
            ? update.tags!.map((tag) => TagService.normalizeSlug(tag)).toList()
            : entity.tags
        ..templateLockCount =
            (entity.templateLockCount + update.templateLockDelta).clamp(
              0,
              1 << 31,
            )
        ..allowInstantComplete =
            update.allowInstantComplete ?? entity.allowInstantComplete
        ..description = update.description ?? entity.description
        ..logs = update.logs != null
            ? update.logs!.map(_logFromDomain).toList()
            : entity.logs
        ..updatedAt = _clock();

      await _isar.projectEntitys.put(entity);
    });
  }

  @override
  Future<void> delete(int isarId) {
    return _isar.writeTxn(() => _isar.projectEntitys.delete(isarId));
  }

  @override
  Future<List<Project>> listAll() async {
    final entities = await _isar.projectEntitys.where().findAll();
    entities.sort(_compareByDueThenCreated);
    return entities.map(_toDomain).toList(growable: false);
  }

  int _compareByDueThenCreated(ProjectEntity a, ProjectEntity b) {
    final aDue = a.dueAt ?? DateTime.fromMillisecondsSinceEpoch(4102444800000);
    final bDue = b.dueAt ?? DateTime.fromMillisecondsSinceEpoch(4102444800000);
    final compareDue = aDue.compareTo(bDue);
    if (compareDue != 0) {
      return compareDue;
    }
    return a.createdAt.compareTo(b.createdAt);
  }

  bool _matchesFilterStatus(TaskStatus status, ProjectFilterStatus filter) {
    switch (filter) {
      case ProjectFilterStatus.all:
        // 排除伪删除状态
        return status != TaskStatus.pseudoDeleted;
      case ProjectFilterStatus.active:
        // 活跃状态：pending 或 doing
        return status == TaskStatus.pending || status == TaskStatus.doing;
      case ProjectFilterStatus.completed:
        // 已完成状态
        return status == TaskStatus.completedActive;
      case ProjectFilterStatus.archived:
        // 已归档状态
        return status == TaskStatus.archived;
      case ProjectFilterStatus.trash:
        // 回收站状态
        return status == TaskStatus.trashed;
    }
  }

  Project _toDomain(ProjectEntity entity) {
    final normalizedTags = entity.tags
        .map(TagService.normalizeSlug)
        .toList(growable: false);
    return Project(
      id: entity.id,
      projectId: entity.projectId,
      title: entity.title,
      status: entity.status,
      dueAt: entity.dueAt,
      startedAt: entity.startedAt,
      endedAt: entity.endedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      sortIndex: entity.sortIndex,
      tags: List.unmodifiable(normalizedTags),
      templateLockCount: entity.templateLockCount,
      seedSlug: entity.seedSlug,
      allowInstantComplete: entity.allowInstantComplete,
      description: entity.description,
      logs: List.unmodifiable(entity.logs.map(_logToDomain)),
    );
  }

  ProjectLogEntry _logToDomain(ProjectLogEntryEntity entity) {
    return ProjectLogEntry(
      timestamp: entity.timestamp,
      action: entity.action,
      previous: entity.previous,
      next: entity.next,
      actor: entity.actor,
    );
  }

  ProjectLogEntryEntity _logFromDomain(ProjectLogEntry entry) {
    return ProjectLogEntryEntity()
      ..timestamp = entry.timestamp
      ..action = entry.action
      ..previous = entry.previous
      ..next = entry.next
      ..actor = entry.actor;
  }

  Stream<T> _watchQuery<T>(Future<T> Function() query) {
    late StreamController<T> controller;
    StreamSubscription<void>? subscription;

    Future<void> emit() async {
      if (controller.isClosed) {
        return;
      }
      try {
        final value = await query();
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
        subscription = _isar.projectEntitys
            .watchLazy(fireImmediately: false)
            .listen((_) => emit());
      },
      onCancel: () async {
        await subscription?.cancel();
      },
    );

    return controller.stream;
  }
}
