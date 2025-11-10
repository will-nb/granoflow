import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

import '../../database/database_adapter.dart';
import '../../database/objectbox_adapter.dart';
import '../../models/milestone.dart';
import '../../objectbox/converters.dart';
import '../../objectbox/milestone_entity.dart';
import '../../objectbox/milestone_log_entity.dart';
import '../milestone_repository.dart';

class ObjectBoxMilestoneRepository implements MilestoneRepository {
  const ObjectBoxMilestoneRepository(this._adapter);

  final DatabaseAdapter _adapter;
  static const _uuid = Uuid();

  ObjectBoxAdapter get _objectBoxAdapter {
    final adapter = _adapter;
    if (adapter is! ObjectBoxAdapter) {
      throw StateError('ObjectBoxMilestoneRepository requires ObjectBoxAdapter');
    }
    return adapter;
  }

  Box<MilestoneEntity> get _milestoneBox =>
      _objectBoxAdapter.store.box<MilestoneEntity>();
  Box<MilestoneLogEntity> get _milestoneLogBox =>
      _objectBoxAdapter.store.box<MilestoneLogEntity>();

  @override
  Future<Milestone> create(MilestoneDraft draft) {
    throw UnimplementedError('ObjectBoxMilestoneRepository.create');
  }

  @override
  Future<Milestone> createMilestoneWithId(
    MilestoneDraft draft,
    String milestoneId,
    DateTime createdAt,
    DateTime updatedAt,
  ) async {
    return await _adapter.writeTransaction(() async {
      final milestoneBox = _milestoneBox;
      final logBox = _milestoneLogBox;

      final entity = MilestoneEntity(
        id: milestoneId,
        projectId: draft.projectId,
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

      final obxId = milestoneBox.put(entity);

      // 保存日志（如果有）
      if (draft.logs.isNotEmpty) {
        final logEntities = draft.logs
            .map((log) => _createLogEntity(
                  milestoneId: milestoneId,
                  milestoneObxId: obxId,
                  entry: log,
                ))
            .toList();
        logBox.putMany(logEntities);
      }

      return _toMilestone(entity, draft.logs);
    });
  }

  /// 将 MilestoneEntity 转换为 Milestone
  Milestone _toMilestone(MilestoneEntity entity, List<MilestoneLogEntry> logs) {
    // 获取 projectId：优先使用 entity.projectId，如果为 null 则从关系获取
    String? projectId = entity.projectId;
    if (projectId == null || projectId.isEmpty) {
      // 尝试从关系获取
      if (entity.project.target != null && entity.project.target!.id.isNotEmpty) {
        projectId = entity.project.target!.id;
      } else {
        throw StateError('Milestone ${entity.id} has no projectId and no project relation');
      }
    }
    
    return Milestone(
      id: entity.id,
      projectId: projectId,
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
      logs: List<MilestoneLogEntry>.unmodifiable(logs),
    );
  }

  /// 创建 MilestoneLogEntity
  MilestoneLogEntity _createLogEntity({
    required String milestoneId,
    required int milestoneObxId,
    required MilestoneLogEntry entry,
  }) {
    final logEntity = MilestoneLogEntity(
      id: _uuid.v4(),
      milestoneId: milestoneId,
      timestamp: entry.timestamp,
      action: entry.action,
      previous: entry.previous,
      next: entry.next,
      actor: entry.actor,
    );
    logEntity.milestone.targetId = milestoneObxId;
    return logEntity;
  }

  @override
  Future<void> delete(String id) {
    throw UnimplementedError('ObjectBoxMilestoneRepository.delete');
  }

  @override
  Future<Milestone?> findById(String id) {
    throw UnimplementedError('ObjectBoxMilestoneRepository.findById');
  }

  @override
  Future<List<Milestone>> listAll() async {
    return await _adapter.readTransaction(() async {
      final entities = await _adapter.findAll<MilestoneEntity>();
      if (entities.isEmpty) {
        return <Milestone>[];
      }

      // 加载所有里程碑的日志
      final logEntities = await _adapter.findAll<MilestoneLogEntity>();
      final logsByMilestone = _loadLogsForMilestones(
        logEntities,
        entities.map((e) => e.id).toList(),
      );

      // 过滤掉无效的里程碑（没有 projectId 且没有 project 关系）
      final validMilestones = <Milestone>[];
      for (final entity in entities) {
        try {
          final milestone = _toMilestone(
            entity,
            logsByMilestone[entity.id] ?? const <MilestoneLogEntry>[],
          );
          validMilestones.add(milestone);
        } catch (e) {
          // 跳过无效的里程碑（没有 projectId）
          // 这在数据迁移或数据不一致的情况下可能发生
          continue;
        }
      }

      return validMilestones;
    });
  }

  /// 加载里程碑的日志
  Map<String, List<MilestoneLogEntry>> _loadLogsForMilestones(
    List<MilestoneLogEntity> logEntities,
    List<String> milestoneIds,
  ) {
    if (milestoneIds.isEmpty) {
      return {};
    }

    final logsByMilestone = <String, List<MilestoneLogEntry>>{};

    for (final log in logEntities) {
      if (log.milestoneId != null && milestoneIds.contains(log.milestoneId)) {
        logsByMilestone.putIfAbsent(log.milestoneId!, () => []).add(_toLogEntry(log));
      }
    }

    return logsByMilestone;
  }

  /// 将 MilestoneLogEntity 转换为 MilestoneLogEntry
  MilestoneLogEntry _toLogEntry(MilestoneLogEntity entity) {
    return MilestoneLogEntry(
      timestamp: entity.timestamp,
      action: entity.action,
      previous: entity.previous,
      next: entity.next,
      actor: entity.actor,
    );
  }

  @override
  Future<List<Milestone>> listByProjectId(String projectId) {
    throw UnimplementedError('ObjectBoxMilestoneRepository.listByProjectId');
  }

  @override
  Future<void> update(String id, MilestoneUpdate update) {
    throw UnimplementedError('ObjectBoxMilestoneRepository.update');
  }

  @override
  Stream<List<Milestone>> watchByProjectId(String projectId) {
    throw UnimplementedError('ObjectBoxMilestoneRepository.watchByProjectId');
  }
}
