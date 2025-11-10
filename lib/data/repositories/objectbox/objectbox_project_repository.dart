import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

import '../../database/database_adapter.dart';
import '../../database/objectbox_adapter.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../objectbox/converters.dart';
import '../../objectbox/project_entity.dart';
import '../../objectbox/project_log_entity.dart';
import '../project_repository.dart';
import '../../../core/providers/project_filter_providers.dart';

class ObjectBoxProjectRepository implements ProjectRepository {
  const ObjectBoxProjectRepository(this._adapter);

  final DatabaseAdapter _adapter;
  static const _uuid = Uuid();

  @override
  Future<Project> create(ProjectDraft draft) {
    final now = DateTime.now();
    final projectId = _uuid.v4();
    return createProjectWithId(draft, projectId, now, now);
  }

  @override
  Future<Project> createProjectWithId(
    ProjectDraft draft,
    String projectId,
    DateTime createdAt,
    DateTime updatedAt,
  ) async {
    return _adapter.writeTransaction(() async {
      final projectBox = _projectBox;
      final logBox = _projectLogBox;

      final entity = ProjectEntity(
        id: projectId,
        title: draft.title,
        statusIndex: taskStatusToIndex(draft.status),
        dueAt: draft.dueAt,
        startedAt: draft.startedAt,
        endedAt: draft.endedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        sortIndex: draft.sortIndex,
        tags: List<String>.from(draft.tags),
        templateLockCount: draft.templateLockCount,
        seedSlug: draft.seedSlug,
        allowInstantComplete: draft.allowInstantComplete,
        description: draft.description,
      );

      final obxId = projectBox.put(entity);

      if (draft.logs.isNotEmpty) {
        final logEntities = draft.logs
            .map((log) => _createLogEntity(
                  projectId: projectId,
                  projectObxId: obxId,
                  entry: log,
                ))
            .toList();
        logBox.putMany(logEntities);
      }

      return _toProject(entity, draft.logs);
    });
  }

  @override
  Future<void> delete(String id) async {
    await _adapter.writeTransaction(() async {
      final projectBox = _projectBox;
      final logBox = _projectLogBox;

      final entity = _findById(projectBox, id);
      if (entity == null) {
        return;
      }

      _removeLogs(logBox, id);
      projectBox.remove(entity.obxId);
    });
  }

  @override
  Future<Project?> findById(String id) async {
    return _adapter.readTransaction(() async {
      final projectBox = _projectBox;
      final logBox = _projectLogBox;

      final entity = _findById(projectBox, id);
      if (entity == null) {
        return null;
      }

      final logs = _loadLogsForProject(logBox, id);
      return _toProject(entity, logs);
    });
  }

  @override
  Future<List<Project>> listAll() async {
    return _adapter.readTransaction(() async {
      final projectBox = _projectBox;
      final logBox = _projectLogBox;

      final entities = projectBox.getAll();
      if (entities.isEmpty) {
        return <Project>[];
      }

      final logsByProject = _loadLogsForProjects(
        logBox,
        entities.map((e) => e.id),
      );

      return entities
          .map(
            (entity) => _toProject(
              entity,
              logsByProject[entity.id] ?? const <ProjectLogEntry>[],
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Future<void> update(String id, ProjectUpdate update) async {
    await _adapter.writeTransaction(() async {
      final projectBox = _projectBox;
      final logBox = _projectLogBox;

      final entity = _findById(projectBox, id);
      if (entity == null) {
        throw StateError('Project not found: $id');
      }

      if (update.title != null) {
        entity.title = update.title!;
      }
      if (update.status != null) {
        entity.statusIndex = taskStatusToIndex(update.status!);
      }
      if (update.dueAt != null) {
        entity.dueAt = update.dueAt;
      }
      if (update.startedAt != null) {
        entity.startedAt = update.startedAt;
      }
      if (update.endedAt != null) {
        entity.endedAt = update.endedAt;
      }
      if (update.sortIndex != null) {
        entity.sortIndex = update.sortIndex!;
      }
      if (update.tags != null) {
        entity.tags = List<String>.from(update.tags!);
      }
      if (update.templateLockDelta != 0) {
        final nextValue = entity.templateLockCount + update.templateLockDelta;
        entity.templateLockCount = nextValue < 0 ? 0 : nextValue;
      }
      if (update.allowInstantComplete != null) {
        entity.allowInstantComplete = update.allowInstantComplete!;
      }
      if (update.description != null) {
        entity.description = update.description;
      }
      if (update.seedSlug != null) {
        entity.seedSlug = update.seedSlug;
      }

      entity.updatedAt = DateTime.now();
      projectBox.put(entity);

      if (update.logs != null) {
        _removeLogs(logBox, id);
        if (update.logs!.isNotEmpty) {
          final logEntities = update.logs!
              .map((log) => _createLogEntity(
                    projectId: id,
                    projectObxId: entity.obxId,
                    entry: log,
                  ))
              .toList();
          logBox.putMany(logEntities);
        }
      }
    });
  }

  @override
  Stream<List<Project>> watchActiveProjects() {
    return watchProjectsByStatus(ProjectFilterStatus.active);
  }

  @override
  Stream<List<Project>> watchProjectsByStatus(ProjectFilterStatus status) {
    return _adapter
        .watch<ProjectEntity>((builder) {
          return builder
            ..filter((entity) => _matchesFilter(status, entity))
            ..sort(_sortByIndexThenCreated);
        })
        .asyncMap(_mapEntitiesToProjects);
  }

  @override
  Stream<List<Project>> watchProjectsByStatuses(
    Set<TaskStatus> allowedStatuses,
  ) {
    final allowed = allowedStatuses.map(taskStatusToIndex).toSet();
    return _adapter
        .watch<ProjectEntity>((builder) {
          return builder
            ..filter(
              (entity) =>
                  entity.statusIndex != taskStatusToIndex(TaskStatus.pseudoDeleted) &&
                  allowed.contains(entity.statusIndex),
            )
            ..sort(_sortByIndexThenCreated);
        })
        .asyncMap(_mapEntitiesToProjects);
  }

  Future<List<Project>> _mapEntitiesToProjects(
    List<ProjectEntity> entities,
  ) async {
    if (entities.isEmpty) {
      return const <Project>[];
    }

    return _adapter.readTransaction(() async {
      final logBox = _projectLogBox;
      final logsByProject = _loadLogsForProjects(
        logBox,
        entities.map((e) => e.id),
      );

      return entities
          .map(
            (entity) => _toProject(
              entity,
              logsByProject[entity.id] ?? const <ProjectLogEntry>[],
            ),
          )
          .toList(growable: false);
    });
  }

  Project _toProject(ProjectEntity entity, List<ProjectLogEntry> logs) {
    return Project(
      id: entity.id,
      title: entity.title,
      status: taskStatusFromIndex(entity.statusIndex),
      dueAt: entity.dueAt,
      startedAt: entity.startedAt,
      endedAt: entity.endedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      sortIndex: entity.sortIndex,
      tags: List<String>.unmodifiable(entity.tags),
      templateLockCount: entity.templateLockCount,
      seedSlug: entity.seedSlug,
      allowInstantComplete: entity.allowInstantComplete,
      description: entity.description,
      logs: List<ProjectLogEntry>.unmodifiable(logs),
    );
  }

  ProjectLogEntry _toLogEntry(ProjectLogEntity entity) {
    return ProjectLogEntry(
      timestamp: entity.timestamp,
      action: entity.action,
      previous: entity.previous,
      next: entity.next,
      actor: entity.actor,
    );
  }

  ProjectLogEntity _createLogEntity({
    required String projectId,
    required int projectObxId,
    required ProjectLogEntry entry,
  }) {
    final logEntity = ProjectLogEntity(
      id: _uuid.v4(),
      projectId: projectId,
      timestamp: entry.timestamp,
      action: entry.action,
      previous: entry.previous,
      next: entry.next,
      actor: entry.actor,
    );
    logEntity.project.targetId = projectObxId;
    return logEntity;
  }

  bool _matchesFilter(ProjectFilterStatus status, ProjectEntity entity) {
    final taskStatus = taskStatusFromIndex(entity.statusIndex);
    switch (status) {
      case ProjectFilterStatus.all:
        return taskStatus != TaskStatus.pseudoDeleted;
      case ProjectFilterStatus.active:
        return taskStatus == TaskStatus.pending || taskStatus == TaskStatus.doing;
      case ProjectFilterStatus.completed:
        return taskStatus == TaskStatus.completedActive;
      case ProjectFilterStatus.archived:
        return taskStatus == TaskStatus.archived;
      case ProjectFilterStatus.trash:
        return taskStatus == TaskStatus.trashed;
    }
  }

  int _sortByIndexThenCreated(ProjectEntity a, ProjectEntity b) {
    final byIndex = a.sortIndex.compareTo(b.sortIndex);
    if (byIndex != 0) {
      return byIndex;
    }
    return a.createdAt.compareTo(b.createdAt);
  }

  Map<String, List<ProjectLogEntry>> _loadLogsForProjects(
    Box<ProjectLogEntity> logBox,
    Iterable<String> projectIds,
  ) {
    final idSet = projectIds.toSet();
    if (idSet.isEmpty) {
      return const {};
    }

    final records = logBox
        .getAll()
        .where((log) => log.projectId != null && idSet.contains(log.projectId))
        .toList(growable: false)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final Map<String, List<ProjectLogEntry>> result = {};
    for (final record in records) {
      final projectId = record.projectId;
      if (projectId != null) {
        result.putIfAbsent(projectId, () => <ProjectLogEntry>[]);
        result[projectId]!.add(_toLogEntry(record));
      }
    }
    return result;
  }

  List<ProjectLogEntry> _loadLogsForProject(
    Box<ProjectLogEntity> logBox,
    String projectId,
  ) {
    final logs = logBox
        .getAll()
        .where((log) => log.projectId != null && log.projectId == projectId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return logs.map(_toLogEntry).toList(growable: false);
  }

  ProjectEntity? _findById(Box<ProjectEntity> box, String id) {
    for (final entity in box.getAll()) {
      if (entity.id == id) {
        return entity;
      }
    }
    return null;
  }

  void _removeLogs(Box<ProjectLogEntity> box, String projectId) {
    final ids = box
        .getAll()
        .where((log) => log.projectId != null && log.projectId == projectId)
        .map((log) => log.obxId)
        .toList(growable: false);
    if (ids.isNotEmpty) {
      box.removeMany(ids);
    }
  }

  ObjectBoxAdapter get _objectBoxAdapter {
    final adapter = _adapter;
    if (adapter is! ObjectBoxAdapter) {
      throw StateError('ObjectBoxProjectRepository requires ObjectBoxAdapter');
    }
    return adapter;
  }

  Box<ProjectEntity> get _projectBox =>
      _objectBoxAdapter.store.box<ProjectEntity>();

  Box<ProjectLogEntity> get _projectLogBox =>
      _objectBoxAdapter.store.box<ProjectLogEntity>();
}
