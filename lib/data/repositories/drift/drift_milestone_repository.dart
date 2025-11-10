import 'dart:async';

import 'package:drift/drift.dart';

import '../../database/database_adapter.dart';
import '../../drift/database.dart' hide Milestone, MilestoneLog;
import '../../drift/database.dart' as drift show Milestone, MilestoneLog;
import '../../drift/converters.dart';
import '../../models/milestone.dart';
import '../milestone_repository.dart';

/// Drift 版本的 MilestoneRepository 实现
class DriftMilestoneRepository implements MilestoneRepository {
  DriftMilestoneRepository(this._adapter);

  final DatabaseAdapter _adapter;

  /// 获取 AppDatabase 实例
  AppDatabase get _db => AppDatabase.instance;

  @override
  Stream<List<Milestone>> watchByProjectId(String projectId) {
    final query = _db.select(_db.milestones)
      ..where((m) => m.projectId.equals(projectId))
      ..orderBy([(m) => OrderingTerm(expression: m.sortIndex, mode: OrderingMode.asc)]);
    return query.watch().asyncMap((entities) async {
      if (entities.isEmpty) return <Milestone>[];
      return await _toMilestones(entities);
    });
  }

  @override
  Future<List<Milestone>> listByProjectId(String projectId) async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.milestones)
        ..where((m) => m.projectId.equals(projectId))
        ..orderBy([(m) => OrderingTerm(expression: m.sortIndex, mode: OrderingMode.asc)]);
      final entities = await query.get();
      return await _toMilestones(entities);
    });
  }

  @override
  Future<Milestone?> findById(String id) async {
    return await _adapter.readTransaction(() async {
      final query = _db.select(_db.milestones)..where((m) => m.id.equals(id));
      final entity = await query.getSingleOrNull();
      if (entity == null) return null;
      return await _toMilestone(entity);
    });
  }

  @override
  Future<Milestone> create(MilestoneDraft draft) async {
    final now = DateTime.now();
    final milestoneId = generateUuid();
    return createMilestoneWithId(draft, milestoneId, now, now);
  }

  @override
  Future<Milestone> createMilestoneWithId(
    MilestoneDraft draft,
    String milestoneId,
    DateTime createdAt,
    DateTime updatedAt,
  ) async {
    return await _adapter.writeTransaction(() async {
      final entity = drift.Milestone(
        id: milestoneId,
        projectId: draft.projectId,
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

      await _db.into(_db.milestones).insert(entity);

      // 保存日志（如果有）
      if (draft.logs.isNotEmpty) {
        for (final log in draft.logs) {
          final logEntity = drift.MilestoneLog(
            id: generateUuid(),
            milestoneId: milestoneId,
            timestamp: log.timestamp,
            action: log.action,
            previous: log.previous,
            next: log.next,
            actor: log.actor,
          );
          await _db.into(_db.milestoneLogs).insert(logEntity);
        }
      }

      return _toMilestone(entity, draft.logs);
    });
  }

  @override
  Future<void> update(String id, MilestoneUpdate update) async {
    await _adapter.writeTransaction(() async {
      final query = _db.select(_db.milestones)..where((m) => m.id.equals(id));
      final existing = await query.getSingleOrNull();
      if (existing == null) {
        throw StateError('Milestone not found: $id');
      }

      final companion = MilestonesCompanion(
        title: update.title != null ? Value(update.title!) : const Value.absent(),
        status: update.status != null ? Value(update.status!) : const Value.absent(),
        dueAt: update.dueAt != null ? Value(update.dueAt) : const Value.absent(),
        startedAt: update.startedAt != null ? Value(update.startedAt) : const Value.absent(),
        endedAt: update.endedAt != null ? Value(update.endedAt) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
        // MilestoneUpdate 没有 projectId 字段，不能更新
        sortIndex: update.sortIndex != null ? Value(update.sortIndex!) : const Value.absent(),
        tags: update.tags != null ? Value(update.tags!) : const Value.absent(),
        templateLockCount: update.templateLockDelta != 0 ? Value(existing.templateLockCount + update.templateLockDelta) : const Value.absent(),
        allowInstantComplete: update.allowInstantComplete != null ? Value(update.allowInstantComplete!) : const Value.absent(),
        description: update.description != null ? Value(update.description) : const Value.absent(),
      );

      await (_db.update(_db.milestones)..where((m) => m.id.equals(id))).write(companion);

      // 处理日志
      if (update.logs != null && update.logs!.isNotEmpty) {
        for (final log in update.logs!) {
          final logEntity = drift.MilestoneLog(
            id: generateUuid(),
            milestoneId: id,
            timestamp: log.timestamp,
            action: log.action,
            previous: log.previous,
            next: log.next,
            actor: log.actor,
          );
          await _db.into(_db.milestoneLogs).insert(logEntity);
        }
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    await _adapter.writeTransaction(() async {
      // 删除日志（外键级联删除会自动处理，但为了明确性，我们手动删除）
      await (_db.delete(_db.milestoneLogs)..where((m) => m.milestoneId.equals(id))).go();
      // 删除里程碑
      await (_db.delete(_db.milestones)..where((m) => m.id.equals(id))).go();
    });
  }

  @override
  Future<List<Milestone>> listAll() async {
    return await _adapter.readTransaction(() async {
      final entities = await _db.select(_db.milestones).get();
      return await _toMilestones(entities);
    });
  }

  /// 将 Drift Milestone 实体转换为领域模型 Milestone
  Future<Milestone> _toMilestone(drift.Milestone entity, [List<MilestoneLogEntry>? logs]) async {
    final milestoneLogs = logs ?? await _loadLogsForMilestone(entity.id);
      return Milestone(
        id: entity.id,
        projectId: entity.projectId ?? '',
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
      logs: List<MilestoneLogEntry>.unmodifiable(milestoneLogs),
    );
  }

  /// 批量转换 Drift Milestone 实体为领域模型 Milestone
  Future<List<Milestone>> _toMilestones(List<drift.Milestone> entities) async {
    if (entities.isEmpty) return [];

    final milestoneIds = entities.map((e) => e.id).toList();
    final logsByMilestone = await _loadLogsForMilestones(milestoneIds);

    return entities.map((entity) {
      final logs = logsByMilestone[entity.id] ?? const <MilestoneLogEntry>[];
      return Milestone(
        id: entity.id,
        projectId: entity.projectId ?? '',
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
        logs: List<MilestoneLogEntry>.unmodifiable(logs),
      );
    }).toList();
  }

  /// 加载单个里程碑的日志
  Future<List<MilestoneLogEntry>> _loadLogsForMilestone(String milestoneId) async {
    final query = _db.select(_db.milestoneLogs)
      ..where((m) => m.milestoneId.equals(milestoneId))
      ..orderBy([(m) => OrderingTerm(expression: m.timestamp, mode: OrderingMode.asc)]);
    final entities = await query.get();
    return entities.map(_toLogEntry).toList();
  }

  /// 批量加载多个里程碑的日志
  Future<Map<String, List<MilestoneLogEntry>>> _loadLogsForMilestones(List<String> milestoneIds) async {
    if (milestoneIds.isEmpty) return {};

    final query = _db.select(_db.milestoneLogs)
      ..where((m) => m.milestoneId.isIn(milestoneIds))
      ..orderBy([(m) => OrderingTerm(expression: m.timestamp, mode: OrderingMode.asc)]);
    final entities = await query.get();

    final logsByMilestone = <String, List<MilestoneLogEntry>>{};
    for (final entity in entities) {
      logsByMilestone.putIfAbsent(entity.milestoneId ?? '', () => []).add(_toLogEntry(entity));
    }
    return logsByMilestone;
  }

  /// 将 Drift MilestoneLog 实体转换为 MilestoneLogEntry
  MilestoneLogEntry _toLogEntry(drift.MilestoneLog entity) {
    return MilestoneLogEntry(
      timestamp: entity.timestamp,
      action: entity.action,
      previous: entity.previous,
      next: entity.next,
      actor: entity.actor,
    );
  }
}
