import 'dart:async';

import 'package:drift/drift.dart';

import '../../../core/providers/project_filter_providers.dart';
import '../../database/database_adapter.dart';
import '../../drift/database.dart' hide Project, ProjectLog;
import '../../drift/database.dart' as drift show Project, ProjectLog;
import '../../drift/converters.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../project_repository.dart';

/// Drift 版本的 ProjectRepository 实现
class DriftProjectRepository implements ProjectRepository {
  DriftProjectRepository(this._adapter);

  final DatabaseAdapter _adapter;

  /// 获取 AppDatabase 实例
  AppDatabase get _db => AppDatabase.instance;

  @override
  Stream<List<Project>> watchActiveProjects() {
    final query = _db.select(_db.projects)
      ..where((p) => p.status.isIn([
            TaskStatus.pending.index,
            TaskStatus.doing.index,
          ]));
    return query.watch().asyncMap((entities) async {
      if (entities.isEmpty) return <Project>[];
      return await _toProjects(entities);
    });
  }

  @override
  Stream<List<Project>> watchProjectsByStatus(ProjectFilterStatus status) {
    final query = _db.select(_db.projects);
    switch (status) {
      case ProjectFilterStatus.all:
        // 不添加状态过滤
        break;
      case ProjectFilterStatus.active:
        query.where((p) => p.status.isIn([
              TaskStatus.pending.index,
              TaskStatus.doing.index,
            ]));
        break;
      case ProjectFilterStatus.completed:
        query.where((p) => p.status.equals(TaskStatus.completedActive.index));
        break;
      case ProjectFilterStatus.archived:
        query.where((p) => p.status.equals(TaskStatus.archived.index));
        break;
      case ProjectFilterStatus.trash:
        query.where((p) => p.status.equals(TaskStatus.trashed.index));
        break;
    }
    return query.watch().asyncMap((entities) async {
      if (entities.isEmpty) return <Project>[];
      return await _toProjects(entities);
    });
  }

  @override
  Stream<List<Project>> watchProjectsByStatuses(Set<TaskStatus> allowedStatuses) {
    final statusIndexes = allowedStatuses.map((s) => s.index).toList();
    final query = _db.select(_db.projects)
      ..where((p) => p.status.isIn(statusIndexes));
    return query.watch().asyncMap((entities) async {
      if (entities.isEmpty) return <Project>[];
      return await _toProjects(entities);
    });
  }

  @override
  Future<Project?> findById(String id) async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.projects)..where((p) => p.id.equals(id));
      final entity = await query.getSingleOrNull();
      if (entity == null) return null;
      return await _toProject(entity);
    });
  }

  @override
  Future<Project> create(ProjectDraft draft) async {
    final now = DateTime.now();
    final projectId = generateUuid();
    return createProjectWithId(draft, projectId, now, now);
  }

  @override
  Future<Project> createProjectWithId(
    ProjectDraft draft,
    String projectId,
    DateTime createdAt,
    DateTime updatedAt,
  ) async {
    return await _adapter.writeTransaction(() async {
      final entity = drift.Project(
        id: projectId,
        title: draft.title,
        status: draft.status,
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

      await _db.into(_db.projects).insert(entity);

      // 保存日志（如果有）
      if (draft.logs.isNotEmpty) {
        for (final log in draft.logs) {
          final logEntity = drift.ProjectLog(
            id: generateUuid(),
            projectId: projectId,
            timestamp: log.timestamp,
            action: log.action,
            previous: log.previous,
            next: log.next,
            actor: log.actor,
          );
          await _db.into(_db.projectLogs).insert(logEntity);
        }
      }

      return _toProject(entity, draft.logs);
    });
  }

  @override
  Future<void> update(String id, ProjectUpdate update) async {
    await _adapter.writeTransaction(() async {
      final query = _db.select(_db.projects)..where((p) => p.id.equals(id));
      final existing = await query.getSingleOrNull();
      if (existing == null) {
        throw StateError('Project not found: $id');
      }

      final companion = ProjectsCompanion(
        title: update.title != null ? Value(update.title!) : const Value.absent(),
        status: update.status != null ? Value(update.status!) : const Value.absent(),
        dueAt: update.dueAt != null ? Value(update.dueAt) : const Value.absent(),
        startedAt: update.startedAt != null ? Value(update.startedAt) : const Value.absent(),
        endedAt: update.endedAt != null ? Value(update.endedAt) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
        sortIndex: update.sortIndex != null ? Value(update.sortIndex!) : const Value.absent(),
        tags: update.tags != null ? Value(update.tags!) : const Value.absent(),
        templateLockCount: update.templateLockDelta != 0 ? Value(existing.templateLockCount + update.templateLockDelta) : const Value.absent(),
        allowInstantComplete: update.allowInstantComplete != null ? Value(update.allowInstantComplete!) : const Value.absent(),
        description: update.description != null ? Value(update.description) : const Value.absent(),
      );

      await (_db.update(_db.projects)..where((p) => p.id.equals(id))).write(companion);

      // 处理日志
      if (update.logs != null && update.logs!.isNotEmpty) {
        for (final log in update.logs!) {
          final logEntity = drift.ProjectLog(
            id: generateUuid(),
            projectId: id,
            timestamp: log.timestamp,
            action: log.action,
            previous: log.previous,
            next: log.next,
            actor: log.actor,
          );
          await _db.into(_db.projectLogs).insert(logEntity);
        }
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    await _adapter.writeTransaction(() async {
      // 删除日志（外键级联删除会自动处理，但为了明确性，我们手动删除）
      await (_db.delete(_db.projectLogs)..where((p) => p.projectId.equals(id))).go();
      // 删除项目
      await (_db.delete(_db.projects)..where((p) => p.id.equals(id))).go();
    });
  }

  @override
  Future<List<Project>> listAll() async {
    return await _adapter.readTransaction(() async {
      final entities = await _db.select(_db.projects).get();
      return await _toProjects(entities);
    });
  }

  /// 将 Drift Project 实体转换为领域模型 Project
  Future<Project> _toProject(drift.Project entity, [List<ProjectLogEntry>? logs]) async {
    final projectLogs = logs ?? await _loadLogsForProject(entity.id);
    return Project(
      id: entity.id,
      title: entity.title,
      status: entity.status,
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
      logs: List<ProjectLogEntry>.unmodifiable(projectLogs),
    );
  }

  /// 批量转换 Drift Project 实体为领域模型 Project
  Future<List<Project>> _toProjects(List<drift.Project> entities) async {
    if (entities.isEmpty) return [];

    final projectIds = entities.map((e) => e.id).toList();
    final logsByProject = await _loadLogsForProjects(projectIds);

    return entities.map((entity) {
      final logs = logsByProject[entity.id] ?? const <ProjectLogEntry>[];
      return Project(
        id: entity.id,
        title: entity.title,
        status: entity.status,
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
    }).toList();
  }

  /// 加载单个项目的日志
  Future<List<ProjectLogEntry>> _loadLogsForProject(String projectId) async {
    final query = _db.select(_db.projectLogs)
      ..where((p) => p.projectId.equals(projectId))
      ..orderBy([(p) => OrderingTerm(expression: p.timestamp, mode: OrderingMode.asc)]);
    final entities = await query.get();
    return entities.map(_toLogEntry).toList();
  }

  /// 批量加载多个项目的日志
  Future<Map<String, List<ProjectLogEntry>>> _loadLogsForProjects(List<String> projectIds) async {
    if (projectIds.isEmpty) return {};

    final query = _db.select(_db.projectLogs)
      ..where((p) => p.projectId.isIn(projectIds))
      ..orderBy([(p) => OrderingTerm(expression: p.timestamp, mode: OrderingMode.asc)]);
    final entities = await query.get();

    final logsByProject = <String, List<ProjectLogEntry>>{};
    for (final entity in entities) {
      logsByProject.putIfAbsent(entity.projectId ?? '', () => []).add(_toLogEntry(entity));
    }
    return logsByProject;
  }

  /// 将 Drift ProjectLog 实体转换为 ProjectLogEntry
  ProjectLogEntry _toLogEntry(drift.ProjectLog entity) {
    return ProjectLogEntry(
      timestamp: entity.timestamp,
      action: entity.action,
      previous: entity.previous,
      next: entity.next,
      actor: entity.actor,
    );
  }
}
